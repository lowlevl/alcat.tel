use std::num::NonZeroUsize;

use clap::Parser;
use rand::seq::IndexedRandom;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Args {
    /// The extension to generate the password for.
    ext: String,

    /// The number of words in the passphrase.
    #[arg(short, long, default_value = "4")]
    words: NonZeroUsize,
}

pub async fn exec(database: SqlitePool, args: Args) -> anyhow::Result<()> {
    let mut tx = database.begin().await?;

    let row = sqlx::query!("SELECT ext, module FROM ext WHERE ext.ext = ?", args.ext)
        .fetch_optional(tx.as_mut())
        .await?;
    match row {
        None => eprintln!("extension `{}` not found", args.ext),
        Some(row) if row.module.as_deref() != Some("sip") => {
            eprintln!(
                "extension `{}` is not registered as `sip`: {:?}",
                args.ext, row.module
            )
        }
        _ => {
            let mut rng = rand::rng();
            let pwd = (0..args.words.get())
                .map(|_| {
                    *diceware_wordlists::MINILOCK_WORDLIST
                        .choose(&mut rng)
                        .expect("empty wordlist")
                })
                .collect::<Vec<_>>()
                .join("-");

            sqlx::query!(
                "INSERT INTO sip VALUES (?, ?) ON CONFLICT DO UPDATE SET pwd = ?",
                args.ext,
                pwd,
                pwd
            )
            .execute(tx.as_mut())
            .await?;

            tx.commit().await?;

            println!("successfully generated password for `{}`: {pwd}", args.ext);
        }
    }

    Ok(())
}
