use clap::Subcommand;

pub mod add;
pub mod del;
pub mod list;

#[derive(Debug, Subcommand)]
pub enum Args {
    /// List routed extensions.
    List,

    /// Add extension to the routing system.
    Add(add::Args),

    /// Delete extension from the routing system.
    Del(del::Args),
}
