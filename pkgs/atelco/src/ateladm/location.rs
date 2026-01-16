use clap::{Parser, Subcommand};
use sqlx::SqlitePool;

#[derive(Debug, Subcommand)]
pub enum Location {
    /// Add a location to an extension.
    Add(Add),

    /// Remove a location from an extension.
    Rm(Rm),
}

#[derive(Debug, Parser)]
pub struct Add {
    /// The extension number to add a location to.
    number: String,

    /// The location to add to the extension.
    location: String,
}

#[derive(Debug, Parser)]
pub struct Rm {
    /// The extension number to remove a location from.
    number: String,

    /// The location to remove from the extension.
    location: String,
}

impl Location {
    pub async fn exec(self, database: SqlitePool) -> anyhow::Result<()> {
        match self {
            Self::Add(args) => Self::add(&database, args).await,
            Self::Rm(args) => Self::rm(&database, args).await,
        }
    }

    pub async fn add(database: &SqlitePool, args: Add) -> anyhow::Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO location
                (number, data)
            VALUES (?, ?)
            "#,
            args.number,
            args.location
        )
        .execute(database)
        .await?;

        println!(
            "Successfully added `{}` to `{}`",
            args.location, args.number
        );

        Ok(())
    }

    pub async fn rm(database: &SqlitePool, args: Rm) -> anyhow::Result<()> {
        if sqlx::query!(
            r#"
            DELETE FROM location
            WHERE location.number = ?
                AND location.data = ?
            RETURNING location.number
            "#,
            args.number,
            args.location
        )
        .fetch_optional(database)
        .await?
        .is_none()
        {
            anyhow::bail!("Extension `{}` not found", args.number);
        }

        println!(
            "Successfully deleted `{}` from `{}`",
            args.location, args.number,
        );

        Ok(())
    }
}
