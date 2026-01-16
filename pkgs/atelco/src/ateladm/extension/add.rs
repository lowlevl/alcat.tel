use clap::Parser;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Args {
    /// The extension number to register.
    number: String,

    /// The ringback tone for the extension.
    #[clap(short, long)]
    ringback: Option<String>,
}

pub async fn exec(database: SqlitePool, args: Args) -> anyhow::Result<()> {
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
