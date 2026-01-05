use sqlx::SqlitePool;

pub struct Auth<'d>(pub &'d SqlitePool);

impl Auth<'_> {
    pub async fn pwd(&self, username: &str, protocol: &str) -> anyhow::Result<Option<String>> {
        tracing::trace!("authenticating `{username}` for `{protocol}`");

        let row = sqlx::query!(
            r#"
            SELECT auth.pwd
            FROM auth
            INNER JOIN route
                ON route.ext = auth.ext
                AND route.module = ?
            WHERE route.ext = ?
            "#,
            protocol,
            username
        )
        .fetch_optional(self.0)
        .await?;

        Ok(row.map(|row| row.pwd))
    }

    pub async fn register(&self, ext: &str, address: &str, ttl: u32) -> anyhow::Result<bool> {
        tracing::trace!("registering `{ext}` at `{address}` for {ttl}s");

        let registered = sqlx::query!(
            r#"
            UPDATE route
            SET address = ?,
                expiry = UNIXEPOCH() + ?
            WHERE route.ext = ?
            RETURNING route.ext
            "#,
            address,
            ttl,
            ext
        )
        .fetch_optional(self.0)
        .await?;

        Ok(registered.is_some())
    }

    pub async fn unregister(&self, ext: &str) -> anyhow::Result<bool> {
        tracing::trace!("unregistering `{ext}`");

        let unregistered = sqlx::query!(
            r#"
            UPDATE route
            SET address = NULL,
                expiry = NULL
            WHERE route.ext = ?
            RETURNING route.ext
            "#,
            ext
        )
        .fetch_optional(self.0)
        .await?;

        Ok(unregistered.is_some())
    }
}
