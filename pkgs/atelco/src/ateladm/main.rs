use std::io;

use clap::{Parser, Subcommand};
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;
use url::Url;

mod auth;
mod route;

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

    /// Manage routes.
    Route {
        #[clap(subcommand)]
        args: route::Args,
    },

    /// Manage authentication.
    Auth {
        #[clap(subcommand)]
        args: auth::Args,
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
        Command::Route {
            args: route::Args::List,
        } => route::list::exec(database).await,
        Command::Route {
            args: route::Args::Add(args),
        } => route::add::exec(database, args).await,
        Command::Route {
            args: route::Args::Del(args),
        } => route::del::exec(database, args).await,
        Command::Auth {
            args: auth::Args::Generate(args),
        } => auth::generate::exec(database, args).await,
        // TODO: `alrm` commands with system services monitoring
    }
}
