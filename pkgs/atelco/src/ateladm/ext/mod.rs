use clap::Subcommand;

pub mod list;

#[derive(Debug, Subcommand)]
pub enum Ext {
    /// List registered extensions.
    List,
}
