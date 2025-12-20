use std::sync::Arc;

use futures::{AsyncRead, AsyncWrite, TryStreamExt};
use yengine::Engine;

pub async fn run(
    engine: Engine<
        impl AsyncRead + Send + Unpin + 'static,
        impl AsyncWrite + Send + Unpin + 'static,
    >,
) -> anyhow::Result<()> {
    engine.setlocal("trackparam", module_path!()).await?;
    if !engine.install(80, "call.route", None).await? {
        anyhow::bail!("unable to register `call.route` handler");
    }

    let engine = Arc::new(engine);
    let mut messages = engine.messages();

    while let Some(req) = messages.try_next().await? {
        tracing::info!("new: {req:?}");

        engine.ack(req, false).await?;
    }

    Ok(())
}
