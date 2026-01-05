use sqlx::SqlitePool;

pub struct Auth<'d>(pub &'d SqlitePool);

impl Auth<'_> {
    #[allow(clippy::too_many_arguments)]
    pub async fn auth(
        &self,
        username: &str,
        protocol: &str,
        nonce: &str,
        realm: &str,
        method: &str,
        uri: &str,
        response: &str,
    ) -> anyhow::Result<bool> {
        tracing::trace!("authenticating `{username}` for `{method} {uri}`");

        if let Some(row) = sqlx::query!(
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
        .await?
        {
            let ha1 = md5::compute(format!("{username}:{realm}:{}", row.pwd));
            let ha2 = md5::compute(format!("{method}:{uri}"));

            let computed = md5::compute(format!("{ha1:x}:{nonce}:{ha2:x}"));
            let expected = format!("{computed:x}");

            tracing::trace!("{response} == {expected}");

            Ok(response == expected)
        } else {
            Ok(false)
        }
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
