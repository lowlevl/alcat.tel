use clap::Subcommand;

pub mod add;
pub mod del;
pub mod list;

#[derive(Debug, Subcommand)]
pub enum Args {
    /// List routes in the system.
    List,

    /// Add a route to the system.
    Add(add::Args),

    /// Delete a route from the system.
    Del(del::Args),
}
