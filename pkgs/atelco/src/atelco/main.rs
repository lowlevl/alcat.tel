use std::io;

use clap::Parser;
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;

mod routing;
mod sipd;

/// Core telecom functionalities.
#[derive(Debug, Parser)]
enum Args {
    /// Handle `call.preroute` and `call.route` messages.
    Routing(routing::Args),

    /// Handle `user.auth`, `user.register` and `user.unregister` messages.
    Sipd(sipd::Args),
}

#[apply(main!)]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    tracing_subscriber::fmt()
        .with_writer(io::stderr)
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive(tracing::Level::WARN.into())
                .from_env_lossy(),
        )
        .without_time()
        .init();

    match args {
        Args::Routing(args) => routing::exec(args).await,
        Args::Sipd(args) => sipd::exec(args).await,
    }
}
