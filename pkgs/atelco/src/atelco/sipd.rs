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

    /// The priority for `user.auth`, `user.register` and `user.unregister` handlers.
    #[arg(short, long, default_value = "95")]
    priority: u64,
}

pub async fn exec(args: Args) -> anyhow::Result<()> {
    let (engine, database) = (
        atelco::engine(&args.socket).await?,
        atelco::database(&args.database).await?,
    );

    engine.setlocal("trackparam", module_path!()).await?;

    // FIXME: deny `call.route` when unauthenticated, or investigate engine

    if !engine.install(args.priority, "user.auth", None).await? {
        anyhow::bail!("unable to register `user.auth` handler");
    }
    if !engine.install(args.priority, "user.register", None).await? {
        anyhow::bail!("unable to register `user.register` handler");
    }
    if !engine
        .install(args.priority, "user.unregister", None)
        .await?
    {
        anyhow::bail!("unable to register `user.unregister` handler");
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

    if req.name == "user.auth"
        && let Some(username) = req.kv.get("username")
    {
        let row = sqlx::query!(
            "SELECT sip.pwd FROM sip INNER JOIN ext ON ext.ext = sip.ext AND ext.module = 'sip' WHERE ext.ext = ?",
            username
        ).fetch_optional(database).await?;

        match row {
            Some(row) => {
                req.retvalue = row.pwd;

                Ok(true)
            }
            None => {
                req.retvalue = "-".into();
                req.kv.insert("error".into(), "noauth".into());

                Ok(true)
            }
        }
    } else if req.name == "user.register"
        && let Some(username) = req.kv.get("username")
        && let Some(expires) = req.kv.get("expires")
        && let Some(data) = req.kv.get("data")
    {
        router
            .register(username, data, expires.parse().unwrap_or(60))
            .await
    } else if req.name == "user.unregister"
        && let Some(username) = req.kv.get("username")
    {
        router.unregister(username).await
    } else {
        Ok(false)
    }
}
