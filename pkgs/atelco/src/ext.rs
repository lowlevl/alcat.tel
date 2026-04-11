use futures::{TryFutureExt, TryStreamExt};
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
        sqlx::query!(
            r#"
            SELECT number
            FROM location
            WHERE location.data = ? || '/' || ?
            "#,
            module,
            address
        )
        .fetch_optional(self)
        .err_into()
        .map_ok(|opt| opt.map(|row| row.number))
        .await
    }

    async fn route(&self, number: &str) -> anyhow::Result<Vec<String>> {
        sqlx::query!(
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
        .err_into()
        .map_ok(|row| row.data)
        .try_collect()
        .await
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
        .err_into()
        .await
    }

    async fn register(&self, number: &str, data: &str, ttl: u32) -> anyhow::Result<()> {
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

    async fn lookup(&self, pp: &str) -> anyhow::Result<Option<String>> {
        sqlx::query!(
            r#"
            SELECT number
            FROM extension
            WHERE extension.dectpp = ?
            "#,
            pp
        )
        .fetch_optional(self)
        .err_into()
        .map_ok(|opt| opt.map(|row| row.number))
        .await
    }

    async fn pair(&self, pp: &str, code: &str) -> anyhow::Result<bool> {
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
        // FIXME: potentially unregister locations at unpairing

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
}

impl DataExt for SqlitePool {}
