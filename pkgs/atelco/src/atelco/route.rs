use std::sync::Arc;

use futures::{AsyncRead, AsyncWrite, TryStreamExt};
use sqlx::SqlitePool;
use yengine::Engine;

pub async fn run(
    engine: Engine<
        impl AsyncRead + Send + Unpin + 'static,
        impl AsyncWrite + Send + Unpin + 'static,
    >,
    database: SqlitePool,
) -> anyhow::Result<()> {
    engine.setlocal("trackparam", module_path!()).await?;
    if !engine.install(80, "call.route", None).await? {
        anyhow::bail!("unable to register `call.route` handler");
    }

    let engine = Arc::new(engine);
    let mut messages = engine.messages();

    while let Some(mut req) = messages.try_next().await? {
        if req.name == "call.route"
            && let Some(called) = req.kv.get("called")
        {
            tracing::debug!("request to route {called}");

            let row = sqlx::query!("SELECT module, location FROM ext WHERE ext.ext = ?", called)
                .fetch_optional(&database)
                .await?;

            if let Some(row) = row
                && let Some(module) = row.module
                && let Some(location) = row.location
            {
                tracing::debug!("found {called} <> {module}/{location}");

                req.retvalue = format!("{module}/{location}");
                engine.ack(req, true).await?;

                continue;
            }
        }

        engine.ack(req, false).await?;
    }

    Ok(())
}
