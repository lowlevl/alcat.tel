use std::path::Path;

use anyhow::Context;
use smol::net::unix::UnixStream;
use sqlx::SqlitePool;
use url::Url;
use yengine::Engine;

pub mod router;

pub async fn engine(path: &Path) -> anyhow::Result<Engine<UnixStream, UnixStream>> {
    let socket = UnixStream::connect(path)
        .await
        .context("while opening unix socket")?;
    let engine = Engine::from_io(socket.clone(), socket);

    engine
        .connect(yengine::format::ConnectRole::Global, None)
        .await?;

    Ok(engine)
}

pub async fn database(url: &Url) -> anyhow::Result<SqlitePool> {
    let database = SqlitePool::connect(url.as_str())
        .await
        .context("while connecting to sqlite database")?;

    Ok(database)
}
