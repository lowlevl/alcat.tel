use std::path::PathBuf;

use clap::{Parser, Subcommand};
use url::Url;

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
    /// Handle `call.preroute` and `call.route` messages
    /// to provide routing functionalities.
    Routed {
        /// The priority for `call.preroute` and `call.route` handlers.
        #[arg(short, long, default_value = "95")]
        priority: u64,
    },

    /// Handle `user.auth`, `user.register` and `user.unregister` messages
    /// to provide authentication functionalities.
    Authd {
        /// The priority for `user.auth`, `user.register` and `user.unregister` handlers.
        #[arg(short, long, default_value = "95")]
        priority: u64,
    },
}
