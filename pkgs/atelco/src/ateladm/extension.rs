use std::num::NonZeroUsize;

use clap::{Parser, Subcommand};
use futures::{StreamExt, TryStreamExt};
use rand::seq::IndexedRandom;
use sqlx::SqlitePool;
use tabled::{Tabled, derive::display, settings::style};

#[derive(Debug, Subcommand)]
pub enum Extension {
    /// List extensions in the system.
    Ls,

    /// Add an extension to the system.
    Add(Add),

    /// Modify an extension in the system.
    Modify(Modify),

    /// Remove an extension from the system.
    Rm(Rm),
}

#[derive(Debug, Parser)]
pub struct Add {
    /// The extension number to register.
    number: String,

    /// The ringback tone for the extension.
    #[clap(short, long)]
    ringback: Option<String>,
}

#[derive(Debug, Parser)]
pub struct Modify {
    /// The extension number to modify.
    number: String,

    /// The ringback tone to set, or `-` to unset.
    #[arg(short, long)]
    ringback: Option<String>,

    /// The password to set, or `-` to unset.
    #[arg(short, long)]
    password: Option<String>,

    /// Generate a random passphrase of the provided word count.
    #[arg(short, long)]
    generate_password: Option<NonZeroUsize>,
}

#[derive(Debug, Parser)]
pub struct Rm {
    /// The extension number to remove.
    number: String,
}

impl Extension {
    pub async fn exec(self, database: SqlitePool) -> anyhow::Result<()> {
        match self {
            Self::Ls => Self::ls(&database).await,
            Self::Add(args) => Self::add(&database, args).await,
            Self::Modify(args) => Self::modify(&database, args).await,
            Self::Rm(args) => Self::rm(&database, args).await,
        }
    }

    pub async fn ls(database: &SqlitePool) -> anyhow::Result<()> {
        #[derive(Tabled)]
        struct Ext {
            number: String,

            #[tabled(display("display::option", "(none)"))]
            ringback: Option<String>,

            locations: String,
        }

        let extensions = sqlx::query!(
            r#"
            SELECT *
            FROM extension
            "#
        )
        .fetch_all(database)
        .await?;

        let data = futures::stream::iter(extensions)
            .then(async |mut extension| {
                let locations = sqlx::query!(
                    r#"
                    SELECT
                        data,
                        expiry - UNIXEPOCH() as "ttl: i64"
                    FROM location
                    WHERE location.number = ?
                    ORDER BY "ttl: i64" DESC
                    "#,
                    extension.number
                )
                .fetch_all(database)
                .await?;

                let locations = locations
                    .into_iter()
                    .map(|location| {
                        let mut line = location.data;

                        if let Some(ttl) = location.ttl {
                            if ttl >= 0 {
                                line += &format!(", ttl {ttl}s");
                            } else {
                                line += ", ttl expired";
                            }
                        }

                        line
                    })
                    .collect::<Vec<_>>();

                let mut locations = locations.join("\n");
                if locations.is_empty() {
                    locations += "(offline)";
                }

                if extension.password.is_some() {
                    extension.number += " 🗝";
                }

                anyhow::Ok(Ext {
                    number: extension.number,
                    ringback: extension.ringback,
                    locations,
                })
            })
            .try_collect::<Vec<_>>()
            .await?;

        let mut table = tabled::Table::builder(data).build();
        let table = table.with(style::Style::rounded());

        println!("{table}");

        Ok(())
    }

    pub async fn add(database: &SqlitePool, args: Add) -> anyhow::Result<()> {
        let mut tx = database.begin().await?;

        let colliding = sqlx::query!(
            r#"
            SELECT number
            FROM extension
            WHERE ? LIKE extension.number || '%'
                OR extension.number || '%' LIKE ?
            "#,
            args.number,
            args.number
        )
        .fetch_optional(tx.as_mut())
        .await?;

        if let Some(colliding) = colliding {
            anyhow::bail!(
                "Extension `{}` collides with `{}`, dial plan must be non-overlapping",
                args.number,
                colliding.number
            );
        }

        sqlx::query!(
            r#"
            INSERT INTO extension
                (number, ringback)
            VALUES (?, ?)
            "#,
            args.number,
            args.ringback
        )
        .execute(tx.as_mut())
        .await?;

        tx.commit().await?;

        println!("Successfully added `{}`", args.number);

        Ok(())
    }

    pub async fn modify(database: &SqlitePool, args: Modify) -> anyhow::Result<()> {
        let mut tx = database.begin().await?;

        if sqlx::query!(
            r#"
            SELECT number
            FROM extension
            WHERE extension.number = ?
            "#,
            args.number
        )
        .fetch_optional(tx.as_mut())
        .await?
        .is_none()
        {
            anyhow::bail!("Extension `{}` not found.", args.number);
        }

        if let Some(ringback) = args.ringback {
            sqlx::query!(
                r#"
                UPDATE extension
                SET ringback = ?
                WHERE extension.number = ?
                "#,
                if ringback == "-" {
                    None
                } else {
                    Some(ringback)
                },
                args.number
            )
            .execute(tx.as_mut())
            .await?;
        }

        if let Some(password) = args.password {
            sqlx::query!(
                r#"
                UPDATE extension
                SET password = ?
                WHERE extension.number = ?
                "#,
                if password == "-" {
                    None
                } else {
                    Some(password)
                },
                args.number
            )
            .execute(tx.as_mut())
            .await?;
        }

        if let Some(words) = args.generate_password {
            let mut rng = rand::rng();

            let password = (0..words.get())
                .map(|_| {
                    *diceware_wordlists::MINILOCK_WORDLIST
                        .choose(&mut rng)
                        .expect("empty wordlist")
                })
                .collect::<Vec<_>>()
                .join("-");

            println!("Generated password: {password}");

            sqlx::query!(
                r#"
                UPDATE extension
                SET password = ?
                WHERE extension.number = ?
                "#,
                password,
                args.number
            )
            .execute(tx.as_mut())
            .await?;
        }

        tx.commit().await?;

        println!("Success.");

        Ok(())
    }

    pub async fn rm(database: &SqlitePool, args: Rm) -> anyhow::Result<()> {
        let deleted = sqlx::query!(
            r#"
            DELETE FROM extension
            WHERE extension.number = ?
            RETURNING extension.number
            "#,
            args.number
        )
        .fetch_optional(database)
        .await?;

        if let Some(deleted) = deleted {
            println!("Successfully deleted `{}`: {deleted:?}", deleted.number);
        } else {
            anyhow::bail!("Extension `{}` not found", args.number);
        }

        Ok(())
    }
}
