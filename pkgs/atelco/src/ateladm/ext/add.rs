use clap::Parser;
use sqlx::SqlitePool;

#[derive(Debug, Parser)]
pub struct Add {
    /// The extension to register.
    ext: String,

    /// The `module` of the extension.
    #[clap(short, long)]
    module: Option<String>,

    /// The `address` of the extension.
    #[clap(short, long)]
    address: Option<String>,
}

pub async fn exec(database: SqlitePool, add: Add) -> anyhow::Result<()> {
    let mut tx = database.begin().await?;

    let colliding = sqlx::query!("SELECT ext FROM ext WHERE ? LIKE ext.ext || '%'", add.ext)
        .fetch_optional(tx.as_mut())
        .await?;

    // FIXME: detect reverse prefixing, 18 LIKE 181 or 181 LIKE 18

    if let Some(colliding) = colliding {
        anyhow::bail!(
            "Extension `{}` collides with `{}`, dial plan must be non-overlapping",
            add.ext,
            colliding.ext
        );
    }

    sqlx::query!(
        "INSERT INTO ext VALUES (?, ?, ?)",
        add.ext,
        add.module,
        add.address
    )
    .execute(tx.as_mut())
    .await?;

    tx.commit().await?;

    println!("Successfully added `{}`", add.ext);

    Ok(())
}
