use std::io;

use atelco::router::Router;
use clap::Parser;
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;

mod authd;
mod routed;

mod args;

#[apply(main!)]
async fn main() -> anyhow::Result<()> {
    let args = args::Args::parse();

    tracing_subscriber::fmt()
        .with_writer(io::stderr)
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive(tracing::Level::WARN.into())
                .from_env_lossy(),
        )
        .without_time()
        .init();

    let (engine, database) = (
        atelco::engine(&args.socket).await?,
        atelco::database(&args.database).await?,
    );

    match args.command {
        args::Command::Routed { priority } => {
            let module = routed::Routed {
                priority,
                router: Router(&database),
            };

            engine.attach(module).await
        }

        args::Command::Authd { priority } => {
            let module = authd::Authd {
                priority,
                router: Router(&database),
            };

            engine.attach(module).await
        }
    }
}
