use std::{path::Path, time::Duration};

use anyhow::Context;
use smol::net::unix::UnixStream;
use sqlx::{
    ConnectOptions, SqlitePool,
    pool::PoolOptions,
    sqlite::{SqliteConnectOptions, SqliteJournalMode},
};
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
    let database = PoolOptions::new()
        .acquire_slow_threshold(Duration::from_millis(250))
        .min_connections(2)
        .connect_with(
            SqliteConnectOptions::from_url(url)?
                .log_slow_statements("warn".parse()?, Duration::from_millis(100))
                .journal_mode(SqliteJournalMode::Wal),
        )
        .await
        .context("while connecting to sqlite database")?;

    Ok(database)
}
