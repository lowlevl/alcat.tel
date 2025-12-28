use std::io;

use clap::{Parser, Subcommand};
use macro_rules_attribute::apply;
use smol_macros::main;
use tracing_subscriber::EnvFilter;
use url::Url;

mod ext;

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

    /// Manage extensions.
    Ext {
        #[clap(subcommand)]
        ext: ext::Ext,
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
        Command::Ext {
            ext: ext::Ext::List,
        } => ext::list::exec(database).await,
        Command::Ext {
            ext: ext::Ext::Add(add),
        } => ext::add::exec(database, add).await,
        Command::Ext {
            ext: ext::Ext::Del(del),
        } => ext::del::exec(database, del).await,
    }
}
