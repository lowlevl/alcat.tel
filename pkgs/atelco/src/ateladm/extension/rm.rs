use clap::Parser;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Args {
    /// The extension number to remove.
    number: String,
}

pub async fn exec(database: SqlitePool, args: Args) -> anyhow::Result<()> {
    let deleted = sqlx::query!(
        r#"
        DELETE FROM extension
        WHERE extension.number = ?
        RETURNING extension.number
        "#,
        args.number
    )
    .fetch_optional(&database)
    .await?;

    if let Some(deleted) = deleted {
        println!("Successfully deleted `{}`: {deleted:?}", deleted.number);
    } else {
        anyhow::bail!("Extension `{}` not found", args.number);
    }

    Ok(())
}
