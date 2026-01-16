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
    let password = args.password.unwrap_or_else(|| {
        let generated = generate(args.words);

        println!("Generated a {} word passphrase: {generated}", args.words);

        generated
    });

    sqlx::query!(
        r#"
        UPDATE extension
        SET password = ?
        WHERE extension.number = ?
        RETURNING extension.number
        "#,
        password,
        args.number,
    )
    .fetch_one(&database)
    .await?;

    println!("Successfully set password for `{}`.", args.number);

    Ok(())
}
