use futures::TryStreamExt;
use sqlx::SqlitePool;

pub struct Router<'d>(pub &'d SqlitePool);

pub struct Extension {
    pub number: String,
    pub ringback: Option<String>,
    pub password: Option<String>,
}

impl Router<'_> {
    pub async fn preroute(&self, module: &str, address: &str) -> anyhow::Result<Option<String>> {
        tracing::trace!("preroute from `{module}/{address}`");

        if let Some(row) = sqlx::query!(
            r#"
            SELECT number
            FROM location
            WHERE location.data = ? || '/' || ?
            "#,
            module,
            address
        )
        .fetch_optional(self.0)
        .await?
        {
            let number = row.number;
            tracing::trace!("caller is at `{number}`");

            Ok(Some(number))
        } else {
            Ok(None)
        }
    }

    pub async fn route(&self, number: &str) -> anyhow::Result<Vec<String>> {
        tracing::trace!("route to `{number}`");

        let locations = sqlx::query!(
            r#"
            SELECT data
            FROM location
            WHERE location.number = ?
                AND (location.expiry IS NULL
                    OR location.expiry > UNIXEPOCH())
            "#,
            number
        )
        .fetch(self.0)
        .map_ok(|row| row.data)
        .try_collect()
        .await?;

        tracing::trace!("number is at `{locations:?}`");

        Ok(locations)
    }

    pub async fn extension(&self, number: &str) -> anyhow::Result<Option<Extension>> {
        sqlx::query_as!(
            Extension,
            r#"
            SELECT *
            FROM extension
            WHERE extension.number = ?
            "#,
            number
        )
        .fetch_optional(self.0)
        .await
        .map_err(Into::into)
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
