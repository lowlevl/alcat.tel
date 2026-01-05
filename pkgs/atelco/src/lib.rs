use std::{path::Path, time::Duration};

use anyhow::Context;
use async_signal::{Signal, Signals};
use futures::TryStreamExt;
use smol::net::unix::UnixStream;
use sqlx::{
    ConnectOptions, SqlitePool,
    pool::PoolOptions,
    sqlite::{SqliteConnectOptions, SqliteJournalMode},
};
use url::Url;
use yengine::Engine;

pub mod auth;
pub mod router;

pub async fn engine(path: &Path) -> anyhow::Result<Engine<UnixStream, UnixStream>> {
    let socket = UnixStream::connect(path)
        .await
        .context("while opening unix socket")?;
    let engine = Engine::from_io(socket.clone(), socket);

    engine
        .connect(yengine::format::ConnectRole::Global, None)
        .await?;

    tracing::info!(
        "%%>{}< connected to yate:{}@{}-{}",
        engine.getlocal("engine.runid").await?,
        engine.getlocal("engine.nodename").await?,
        engine.getlocal("engine.version").await?,
        engine.getlocal("engine.release").await?,
    );

    Ok(engine)
}

pub async fn sigterm(engine: &Engine<UnixStream, UnixStream>) -> anyhow::Result<()> {
    Signals::new([Signal::Term])?.try_next().await?;

    tracing::info!("received `SIGTERM`, sending quit message to engine..");
    engine.quit().await?;

    Ok(())
}

pub async fn database(url: &Url) -> anyhow::Result<SqlitePool> {
    let database = PoolOptions::new()
        .acquire_slow_threshold(Duration::from_millis(250))
        .min_connections(4)
        .connect_with(
            SqliteConnectOptions::from_url(url)?
                .log_slow_statements("warn".parse()?, Duration::from_millis(100))
                .optimize_on_close(true, None)
                .journal_mode(SqliteJournalMode::Wal),
        )
        .await
        .context("while connecting to sqlite database")?;

    Ok(database)
}
