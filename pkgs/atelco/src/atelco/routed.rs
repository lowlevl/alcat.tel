use std::path::PathBuf;

use atelco::router::Router;
use clap::Parser;
use futures::TryStreamExt;
use sqlx::SqlitePool;
use url::Url;
use yengine::Req;

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
                let processed = process(&database, &mut req).await?;

                Ok(engine.ack(req, processed).await?)
            })
    )?;

    tracing::info!("processed all incoming messages, exiting");

    Ok(())
}

async fn process(database: &SqlitePool, req: &mut Req) -> anyhow::Result<bool> {
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
        && let Some(extension) = router.extension(called).await?
    {
        let locations = router.route(called).await?;

        // FIXME: add loop protection

        if locations.is_empty() {
            req.retvalue = "-".into();
            req.kv.insert("error".into(), "offline".into());
        } else {
            req.retvalue = "fork".into();

            if let Some(ringback) = extension.ringback {
                req.kv.insert("fork.fake".into(), ringback);
            }

            for (idx, location) in locations.into_iter().enumerate() {
                req.kv.insert(format!("callto.{}", idx + 1), location);
            }
        }

        Ok(true)
    } else {
        Ok(false)
    }
}
