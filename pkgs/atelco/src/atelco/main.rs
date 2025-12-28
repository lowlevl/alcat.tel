use std::{io, path::PathBuf};

use clap::Parser;
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;
use url::Url;

mod route;

/// Core telecom functionalities.
#[derive(Debug, Parser)]
enum Args {
    /// Route calls from the provided database.
    Route {
        /// The path to the `sqlite` database.
        #[arg(short, long)]
        database: Url,

        /// Path to yate's control socket.
        socket: PathBuf,
    },
}

#[apply(main!)]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    tracing_subscriber::fmt()
        .with_writer(io::stderr)
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive(tracing::Level::DEBUG.into())
                .from_env_lossy(),
        )
        .init();

    tracing::debug!("starting with args: {args:?}");

    match args {
        Args::Route { database, socket } => {
            route::exec(
                atelco::engine(&socket).await?,
                atelco::database(&database).await?,
            )
            .await
        }
    }
}
