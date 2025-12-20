use std::io;

use clap::Parser;
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;

mod route;

/// All the telecommunication functionalities.
#[derive(Debug, Parser)]
enum Args {
    /// Route calls according to the local database
    Route,
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

    let engine = yengine::Engine::stdio();
    match args {
        Args::Route => route::run(engine).await,
    }
}
