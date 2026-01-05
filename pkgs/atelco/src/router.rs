use sqlx::SqlitePool;

#[derive(Debug)]
pub enum Route {
    NotFound,
    Routed(String, String),
    Alias(String),
    Offline,
    Reserved,
}

pub struct Router<'d>(pub &'d SqlitePool);

impl Router<'_> {
    pub async fn preroute(&self, module: &str, address: &str) -> anyhow::Result<Option<String>> {
        tracing::trace!("preroute from `{module}/{address}`");

        if let Some(row) = sqlx::query!(
            r#"
            SELECT ext
            FROM route
            WHERE route.module = ?
                AND route.address = ?
            "#,
            module,
            address
        )
        .fetch_optional(self.0)
        .await?
        {
            let caller = row.ext;
            tracing::trace!("caller is at `{caller}`");

            Ok(Some(caller))
        } else {
            Ok(None)
        }
    }

    pub async fn route(&self, called: &str) -> anyhow::Result<Route> {
        tracing::trace!("route to `{called}`");

        let route = match sqlx::query!(
            r#"
            SELECT module,
                address,
                expiry - UNIXEPOCH() as "ttl: i64"
            FROM route
            WHERE route.ext = ?
            "#,
            called
        )
        .fetch_optional(self.0)
        .await?
        {
            None => Route::NotFound,
            Some(row) => match (row.module, row.address) {
                // Route is not routable
                (None, None) => Route::Reserved,
                // Route is offline
                (Some(_), None) => Route::Offline,
                // Address has expired
                (_, _) if row.ttl.unwrap_or_default() < 0 => Route::Offline,
                // Alias to another location
                (None, Some(address)) => Route::Alias(address),
                // Route to final location
                (Some(module), Some(address)) => Route::Routed(module, address),
            },
        };

        tracing::trace!("route is at `{route:?}`");

        Ok(route)
    }
}
