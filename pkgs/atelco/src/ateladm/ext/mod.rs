use clap::Subcommand;

pub mod add;
pub mod del;
pub mod list;

#[derive(Debug, Subcommand)]
pub enum Ext {
    /// List routed extensions.
    List,

    /// Add extension to the routing system.
    Add(add::Add),

    /// Delete extension from the routing system.
    Del(del::Del),
}
