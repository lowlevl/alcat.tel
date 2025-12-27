use std::path::Path;

use smol::net::unix::UnixStream;
use sqlx::SqlitePool;
use url::Url;
use yengine::Engine;

pub async fn engine(path: &Path) -> Result<Engine<UnixStream, UnixStream>, yengine::Error> {
    let socket = UnixStream::connect(path).await?;
    let engine = Engine::from_io(socket.clone(), socket);

    engine
        .connect(yengine::format::ConnectRole::Global, None)
        .await?;

    Ok(engine)
}

pub async fn database(url: &Url) -> sqlx::Result<SqlitePool> {
    let database = SqlitePool::connect(url.as_str()).await?;

    Ok(database)
}
