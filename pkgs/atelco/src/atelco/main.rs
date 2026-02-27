use std::{io, net::IpAddr, path::PathBuf};

use clap::{Parser, Subcommand};
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;
use url::Url;

mod authd;
mod dectd;
mod routed;

/// Core telecom functionalities.
#[derive(Debug, Parser)]
pub struct Args {
    /// Path to yate's control socket.
    #[arg(short, long)]
    pub socket: PathBuf,

    /// The path to the `sqlite` database.
    #[arg(short, long)]
    pub database: Url,

    #[clap(subcommand)]
    pub command: Command,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    /// Pre-route/route calls.
    Routed {
        /// The priority of `call.preroute` and `call.route` handlers.
        #[arg(short, long, default_value = "95")]
        priority: u64,
    },

    /// Authenticate calls from remote parties.
    Authd {
        /// The priority of `user.auth`, `user.register` and `user.unregister` handlers.
        #[arg(short, long, default_value = "95")]
        priority: u64,
    },

    /// Handle self-service registrations of DECTs.
    Dectd {
        /// The priority of `call.preroute`, `call.route` & `user.auth` handlers.
        #[arg(short, long, default_value = "90")]
        priority: u64,

        /// The prefix of the service numbers.
        #[arg(short = 'n', long)]
        prefix: String,

        /// The address to trust when processing messages.
        #[arg(short, long)]
        address: IpAddr,

        /// The target to play on pairing success.
        #[arg(short, long, default_value = "tone/info")]
        success: String,
    },
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

    let (engine, database) = (
        atelco::engine(&args.socket).await?,
        atelco::database(&args.database).await?,
    );

    match args.command {
        Command::Routed { priority } => engine.attach(routed::Routed { database, priority }).await,
        Command::Authd { priority } => engine.attach(authd::Authd { database, priority }).await,
        Command::Dectd {
            priority,
            prefix,
            address,
            success,
        } => {
            engine
                .attach(dectd::Dectd {
                    database,
                    priority,
                    prefix,
                    address,
                    success,
                })
                .await
        }
    }
}
