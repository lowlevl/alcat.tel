use std::{io, path::PathBuf};

use clap::Parser;
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;
use url::Url;

mod routing;

/// Core telecom functionalities.
#[derive(Debug, Parser)]
enum Args {
    /// Route calls from the provided database.
    Routing {
        /// Path to yate's control socket.
        socket: PathBuf,

        /// The path to the `sqlite` database.
        #[arg(short, long)]
        database: Url,
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
        Args::Routing { socket, database } => {
            routing::exec(
                atelco::engine(&socket).await?,
                atelco::database(&database).await?,
            )
            .await
        }
    }
}
