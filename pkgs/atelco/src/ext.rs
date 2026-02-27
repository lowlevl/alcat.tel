use futures::TryStreamExt;
use sqlx::SqlitePool;

pub struct Extension {
    pub number: String,
    pub ringback: Option<String>,
    pub password: Option<String>,
    pub dectpp: Option<String>,
    pub dectcode: Option<String>,
}

#[allow(async_fn_in_trait)]
pub trait DataExt
where
    for<'e> &'e Self: sqlx::Executor<'e, Database = sqlx::Sqlite>,
{
    async fn reverse(&self, module: &str, address: &str) -> anyhow::Result<Option<String>> {
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
        .fetch_optional(self)
        .await?
        {
            let number = row.number;
            tracing::trace!("caller is at `{number}`");

            Ok(Some(number))
        } else {
            Ok(None)
        }
    }

    async fn route(&self, number: &str) -> anyhow::Result<Vec<String>> {
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
        .fetch(self)
        .map_ok(|row| row.data)
        .try_collect()
        .await?;

        tracing::trace!("number is at `{locations:?}`");

        Ok(locations)
    }

    async fn extension(&self, number: &str) -> anyhow::Result<Option<Extension>> {
        sqlx::query_as!(
            Extension,
            r#"
            SELECT *
            FROM extension
            WHERE extension.number = ?
            "#,
            number
        )
        .fetch_optional(self)
        .await
        .map_err(Into::into)
    }

    async fn register(&self, number: &str, data: &str, ttl: u32) -> anyhow::Result<()> {
        tracing::trace!("registering `{number}` at `{data}` for {ttl}s");

        // Expire all the expired locations for `number`
        sqlx::query!(
            r#"
            DELETE FROM location
            WHERE location.number = ?
                AND location.expiry IS NOT NULL
                AND location.expiry < UNIXEPOCH()
            "#,
            number
        )
        .execute(self)
        .await?;

        sqlx::query!(
            r#"
            INSERT INTO location(number, data, expiry)
            VALUES (?, ?, UNIXEPOCH() + ?)
            ON CONFLICT DO UPDATE
            SET expiry = excluded.expiry
            "#,
            number,
            data,
            ttl
        )
        .execute(self)
        .await?;

        Ok(())
    }

    async fn unregister(&self, number: &str, data: &str) -> anyhow::Result<bool> {
        tracing::trace!("unregistering `{number}` from `{data}`");

        let res = sqlx::query!(
            r#"
            DELETE FROM location
            WHERE location.number = ?
                AND location.data = ?
            "#,
            number,
            data
        )
        .execute(self)
        .await?;

        Ok(res.rows_affected() > 0)
    }

    async fn pair(&self, pp: &str, code: &str) -> anyhow::Result<bool> {
        tracing::trace!("pairing `{pp}` using `{code}`");

        let res = sqlx::query!(
            r#"
            UPDATE extension
            SET dectpp = ?,
                dectcode = NULL
            WHERE extension.dectcode = ?
            "#,
            pp,
            code
        )
        .execute(self)
        .await?;

        Ok(res.rows_affected() > 0)
    }

    async fn unpair(&self, pp: &str) -> anyhow::Result<()> {
        tracing::trace!("unpairing `{pp}`");

        sqlx::query!(
            r#"
            UPDATE extension
            SET dectpp = NULL
            WHERE extension.dectpp = ?
            "#,
            pp
        )
        .execute(self)
        .await?;

        Ok(())
    }

    async fn lookup(&self, pp: &str) -> anyhow::Result<Option<String>> {
        tracing::trace!("looking up `{pp}` in database");

        let caller = sqlx::query!(
            r#"
            SELECT number
            FROM extension
            WHERE extension.dectpp = ?
            "#,
            pp
        )
        .fetch_optional(self)
        .await?
        .map(|row| row.number);

        tracing::trace!("`{pp}` is at {caller:?}");

        Ok(caller)
    }
}

impl DataExt for SqlitePool {}
