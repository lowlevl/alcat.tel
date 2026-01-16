use std::io;

use clap::{Parser, Subcommand};
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;
use url::Url;

mod extension;

// TODO: `alrm` commands with system services monitoring.

/// Administrate the telecom system.
#[derive(Debug, Parser)]
struct Args {
    /// The path to the `sqlite` database.
    #[arg(short, long)]
    database: Url,

    #[clap(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Apply database migrations.
    Migrate,

    /// Manage extensions in the telephony system.
    Extension {
        #[clap(subcommand)]
        args: extension::Args,
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
        .init();

    let database = atelco::database(&args.database).await?;
    match args.command {
        Command::Migrate => sqlx::migrate!().run(&database).await.map_err(Into::into),

        Command::Extension {
            args: extension::Args::Ls,
        } => extension::ls::exec(database).await,
        Command::Extension {
            args: extension::Args::Add(args),
        } => extension::add::exec(database, args).await,
        Command::Extension {
            args: extension::Args::Mod,
        } => todo!(),
        Command::Extension {
            args: extension::Args::Rm(args),
        } => extension::rm::exec(database, args).await,
        Command::Extension {
            args: extension::Args::Auth(args),
        } => extension::auth::exec(database, args).await,
    }
}
