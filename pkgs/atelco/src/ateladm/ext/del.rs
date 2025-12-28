use clap::Parser;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Del {
    /// The extension to delete.
    ext: String,
}

pub async fn exec(database: SqlitePool, del: Del) -> anyhow::Result<()> {
    let deleted = sqlx::query!("DELETE FROM ext WHERE ext.ext = ? RETURNING *", del.ext)
        .fetch_optional(&database)
        .await?;

    if let Some(deleted) = deleted {
        println!("Successfully deleted `{}`: {deleted:?}", deleted.ext);
    } else {
        anyhow::bail!("Extension `{}` not found", del.ext);
    }

    Ok(())
}
