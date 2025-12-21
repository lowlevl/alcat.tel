use sqlx::SqlitePool;

pub async fn database(url: &str) -> sqlx::Result<SqlitePool> {
    let database = SqlitePool::connect(url).await?;
    sqlx::migrate!().run(&database).await?;

    Ok(database)
}
