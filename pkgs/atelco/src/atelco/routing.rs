use futures::TryStreamExt;
use smol::net::unix::UnixStream;
use sqlx::SqlitePool;
use yengine::Engine;

pub async fn exec(
    engine: Engine<UnixStream, UnixStream>,
    database: SqlitePool,
) -> anyhow::Result<()> {
    engine.setlocal("trackparam", module_path!()).await?;

    if !engine.install(80, "call.route", None).await? {
        anyhow::bail!("unable to register `call.route` handler");
    }
    if !engine.install(80, "call.preroute", None).await? {
        anyhow::bail!("unable to register `call.preroute` handler");
    }

    let mut messages = engine.messages();
    while let Some(mut req) = messages.try_next().await? {
        let mut processed = false;

        if req.name == "call.route"
            && let Some(called) = req.kv.get("called")
        {
            tracing::debug!("call.route to `{called}`");

            if let Some(row) =
                sqlx::query!("SELECT module, location FROM ext WHERE ext.ext = ?", called)
                    .fetch_optional(&database)
                    .await?
            {
                req.retvalue = match (row.module, row.location) {
                    // Route to final location
                    (Some(module), Some(location)) => format!("{module}/{location}"),
                    // Alias to another location
                    (None, Some(location)) => location,
                    // Route is offline
                    (Some(_), None) => {
                        req.kv.insert("error".into(), "offline".into());

                        "-".into()
                    }
                    // Route is not routable
                    (None, None) => "-".into(),
                };
                processed = true;
            }
        } else if req.name == "call.preroute"
            && let Some(address) = req.kv.get("address")
        {
            tracing::debug!("call.preroute from `{address}`");

            if let Some((module, location)) = address.split_once("/")
                && let Some(row) = sqlx::query!(
                    "SELECT ext FROM ext WHERE ext.module = ? AND ext.location = ?",
                    module,
                    location
                )
                .fetch_optional(&database)
                .await?
            {
                req.kv.insert("caller".into(), row.ext);
            }
        }

        engine.ack(req, processed).await?;
    }

    Ok(())
}
