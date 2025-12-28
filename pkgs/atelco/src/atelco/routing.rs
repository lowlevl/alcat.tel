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
            tracing::trace!("call.route to `{called}`");

            if let Some(row) =
                sqlx::query!("SELECT module, location FROM ext WHERE ext.ext = ?", called)
                    .fetch_optional(&database)
                    .await?
            {
                processed = true;

                req.retvalue = match (row.module, row.location) {
                    // Deny routing to itself
                    (module, location)
                        if module.as_ref() == req.kv.get("module")
                            && location.as_ref() == req.kv.get("address") =>
                    {
                        req.kv.insert("error".into(), "busy".into());

                        "-".into()
                    }
                    // Route to final location
                    (Some(module), Some(location)) => format!("{module}/{location}"),
                    // Alias to another location
                    (None, Some(location)) => {
                        req.kv.insert("called".into(), location);

                        // FIXME: does not work

                        "return".into()
                    }
                    // Route is offline
                    (Some(_), None) => {
                        req.kv.insert("error".into(), "offline".into());

                        "-".into()
                    }
                    // Route is not routable
                    (None, None) => "-".into(),
                };

                tracing::trace!("location is `{}`", req.retvalue);
            }
        } else if req.name == "call.preroute"
            && let Some(module) = req.kv.get("module")
            && let Some(address) = req.kv.get("address")
        {
            tracing::trace!("call.preroute from `{module}/{address}`");

            if let Some(row) = sqlx::query!(
                "SELECT ext FROM ext WHERE ext.module = ? AND ext.location = ?",
                module,
                address
            )
            .fetch_optional(&database)
            .await?
            {
                tracing::trace!("caller is `{}`", row.ext);

                req.kv.insert("caller".into(), row.ext);
            }
        }

        engine.ack(req, processed).await?;
    }

    Ok(())
}
