use std::path::PathBuf;

use atelco::router::{Route, Router};
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
}

pub async fn exec(args: Args) -> anyhow::Result<()> {
    let (engine, database) = (
        atelco::engine(&args.socket).await?,
        atelco::database(&args.database).await?,
    );

    engine.setlocal("trackparam", module_path!()).await?;

    if !engine.install(80, "call.route", None).await? {
        anyhow::bail!("unable to register `call.route` handler");
    }
    if !engine.install(80, "call.preroute", None).await? {
        anyhow::bail!("unable to register `call.preroute` handler");
    }

    tracing::info!(
        "%%>{} ready to route calls for {}@{}-{}",
        engine.getlocal("engine.runid").await?,
        engine.getlocal("engine.nodename").await?,
        engine.getlocal("engine.version").await?,
        engine.getlocal("engine.release").await?,
    );

    engine
        .messages()
        .err_into()
        .try_for_each_concurrent(None, async |mut req| {
            let processed = process(&database, &mut req).await?;

            Ok(engine.ack(req, processed).await?)
        })
        .await
}

async fn process(database: &SqlitePool, req: &mut Req) -> anyhow::Result<bool> {
    let router = Router(database);

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
            Route::Alias(_) => {
                // FIXME: does not work
                // TODO: recursive routing
                // NOTE: recursive will need re-entry probably
                // TODO: loop prevention
                req.retvalue = "tone/info".into();

                Ok(true)
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
