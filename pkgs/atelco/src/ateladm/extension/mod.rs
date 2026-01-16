use clap::Subcommand;

pub mod add;
pub mod auth;
pub mod ls;
pub mod rm;

#[derive(Debug, Subcommand)]
pub enum Args {
    /// List extensions in the system.
    Ls,

    /// Add an extension to the system.
    Add(add::Args),

    /// Modify an extension in the system.
    Mod,

    /// Remove an extension from the system.
    Rm(rm::Args),

    /// Manage extension authentication in the system.
    Auth(auth::Args),
}
