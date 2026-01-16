use std::num::NonZeroUsize;

use clap::Parser;
use rand::seq::IndexedRandom;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Args {
    /// The number of the extension.
    number: String,

    /// The password to set, or if empty generate.
    password: Option<String>,

    /// The number of passphrase words if generated.
    #[arg(long, short, default_value = "4")]
    words: NonZeroUsize,
}

fn generate(words: NonZeroUsize) -> String {
    let mut rng = rand::rng();

    (0..words.get())
        .map(|_| {
            *diceware_wordlists::MINILOCK_WORDLIST
                .choose(&mut rng)
                .expect("empty wordlist")
        })
        .collect::<Vec<_>>()
        .join("-")
}

pub async fn exec(database: SqlitePool, args: Args) -> anyhow::Result<()> {
    let mut tx = database.begin().await?;

    let extension = sqlx::query!(
        r#"
        SELECT number
        FROM extension
        WHERE extension.number = ?
        "#,
        args.number
    )
    .fetch_optional(tx.as_mut())
    .await?;

    match extension {
        None => eprintln!("Extension `{}` not found", args.number),
        Some(_) => {
            let password = args.password.unwrap_or_else(|| generate(args.words));

            sqlx::query!(
                r#"
                INSERT INTO auth
                    (number, password)
                VALUES (?, ?)
                    ON CONFLICT DO UPDATE SET password = ?
                "#,
                args.number,
                password,
                password
            )
            .execute(tx.as_mut())
            .await?;

            tx.commit().await?;

            println!("Successfully set password for `{}`.", args.number);
        }
    }

    Ok(())
}
