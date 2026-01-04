use std::io;

use clap::Parser;
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;

mod authd;
mod routed;

/// Core telecom functionalities.
#[derive(Debug, Parser)]
enum Args {
    /// Handle `call.preroute` and `call.route` messages.
    Routed(routed::Args),

    /// Handle `user.auth`, `user.register` and `user.unregister` messages.
    Authd(authd::Args),
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
        Args::Routed(args) => routed::exec(args).await,
        Args::Authd(args) => authd::exec(args).await,
    }
}
