use sqlx::SqlitePool;

pub struct Auth<'d>(pub &'d SqlitePool);

impl Auth<'_> {
    pub async fn pwd(&self, number: &str) -> anyhow::Result<Option<String>> {
        tracing::trace!("authenticating `{number}`");

        let row = sqlx::query!(
            r#"
            SELECT auth.password
            FROM auth
            WHERE auth.number = ?
            "#,
            number
        )
        .fetch_optional(self.0)
        .await?;

        Ok(row.map(|row| row.password))
    }

    pub async fn register(&self, number: &str, data: &str, ttl: u32) -> anyhow::Result<()> {
        tracing::trace!("registering `{number}` at `{data}` for {ttl}s");

        // FIXME: expire all the expired locations for `number`

        sqlx::query!(
            r#"
            INSERT INTO
                location(number, data, expiry)
            VALUES (?, ?, UNIXEPOCH() + ?)
            "#,
            number,
            data,
            ttl
        )
        .execute(self.0)
        .await?;

        Ok(())
    }

    pub async fn unregister(&self, number: &str, data: &str) -> anyhow::Result<bool> {
        tracing::trace!("unregistering `{number}` from `{data}`");

        let unregistered = sqlx::query!(
            r#"
            DELETE FROM location
            WHERE location.number = ?
                AND location.data = ?
            RETURNING location.number
            "#,
            number,
            data
        )
        .fetch_optional(self.0)
        .await?;

        Ok(unregistered.is_some())
    }
}
