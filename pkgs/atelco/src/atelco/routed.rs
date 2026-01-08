use std::path::PathBuf;

use atelco::router::{Route, Router};
use clap::Parser;
use futures::TryStreamExt;
use smol::net::unix::UnixStream;
use sqlx::SqlitePool;
use url::Url;
use yengine::{Engine, Req};

#[derive(Debug, Parser)]
pub struct Args {
    /// Path to yate's control socket.
    socket: PathBuf,

    /// The path to the `sqlite` database.
    #[arg(short, long)]
    database: Url,

    /// The priority for `call.preroute` and `call.route` handlers.
    #[arg(short, long, default_value = "95")]
    priority: u64,
}

pub async fn exec(args: Args) -> anyhow::Result<()> {
    let (engine, database) = (
        atelco::engine(&args.socket).await?,
        atelco::database(&args.database).await?,
    );

    engine.setlocal("trackparam", module_path!()).await?;
    engine.setlocal("reenter", "true").await?;

    if !engine.install(args.priority, "call.preroute", None).await? {
        anyhow::bail!("unable to register `call.preroute` handler");
    }
    if !engine.install(args.priority, "call.route", None).await? {
        anyhow::bail!("unable to register `call.route` handler");
    }

    futures::try_join!(
        atelco::sigterm(&engine),
        engine
            .messages()
            .err_into()
            .try_for_each_concurrent(None, async |mut req| {
                let processed = process(&engine, &database, &mut req).await?;

                Ok(engine.ack(req, processed).await?)
            })
    )?;

    tracing::info!("processed all incoming messages, exiting");

    Ok(())
}

async fn process(
    engine: &Engine<UnixStream, UnixStream>,
    database: &SqlitePool,
    req: &mut Req,
) -> anyhow::Result<bool> {
    let router = Router(database);

    // Deny unauthenticated calls with `noauth`
    if req.kv.get("module").map(String::as_str) != Some("analog")
        && !req.kv.contains_key("username")
    {
        req.retvalue = "-".into();
        req.kv.insert("error".into(), "noauth".into());

        return Ok(true);
    }

    if req.name == "call.preroute"
        && let Some(module) = req.kv.get("module")
        && let Some(address) = req.kv.get("address")
        && let Some(caller) = router.preroute(module, address).await?
    {
        req.kv.insert("caller".into(), caller);

        Ok(true)
    } else if req.name == "call.route"
        && let Some(called) = req.kv.get("called")
    {
        match router.route(called).await? {
            Route::NotFound => Ok(false),

            // Deny routing to itself, because it might just timeout
            Route::Routed(module, address)
                if Some(&module) == req.kv.get("module")
                    && Some(&address) == req.kv.get("address") =>
            {
                req.retvalue = "-".into();

                Ok(true)
            }

            Route::Routed(module, address) => {
                req.retvalue = format!("{module}/{address}");

                Ok(true)
            }

            Route::Alias(called) => {
                let noloop = req.kv.get("noloop");

                if let Some(noloop) = noloop
                    && noloop == &called
                {
                    tracing::warn!("number `{called}` loops to itself");

                    req.retvalue = "-".into();
                    req.kv.insert("error".into(), "looping".into());

                    Ok(true)
                } else {
                    if noloop.is_none() {
                        req.kv.insert("noloop".into(), called.clone());
                    }
                    req.kv.insert("called".into(), called);

                    // request the engine for a new route
                    let (processed, retvalue, kv) = engine
                        .message(&req.name, &req.retvalue, req.kv.clone())
                        .await?;

                    req.retvalue = retvalue;
                    req.kv = kv;

                    Ok(processed)
                }
            }

            Route::Offline => {
                req.retvalue = "-".into();
                req.kv.insert("error".into(), "offline".into());

                Ok(true)
            }

            Route::Reserved => {
                req.retvalue = "-".into();

                Ok(true)
            }
        }
    } else {
        Ok(false)
    }
}
