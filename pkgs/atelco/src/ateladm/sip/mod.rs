use clap::Subcommand;

pub mod generate;

#[derive(Debug, Subcommand)]
pub enum Args {
    /// Generate a password for the provided extension.
    Generate(generate::Args),
}
