use clap::Parser;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Args {
    /// The extension to delete.
    ext: String,
}

pub async fn exec(database: SqlitePool, args: Args) -> anyhow::Result<()> {
    let deleted = sqlx::query!(
        "DELETE FROM route WHERE route.ext = ? RETURNING route.ext",
        args.ext
    )
    .fetch_optional(&database)
    .await?;

    if let Some(deleted) = deleted {
        println!("Successfully deleted `{}`: {deleted:?}", deleted.ext);
    } else {
        anyhow::bail!("Extension `{}` not found", args.ext);
    }

    Ok(())
}
