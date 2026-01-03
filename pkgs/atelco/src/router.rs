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
            "SELECT ext FROM ext WHERE ext.module = ? AND ext.address = ?",
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

        let route = match sqlx::query!("SELECT module, address FROM ext WHERE ext.ext = ?", called)
            .fetch_optional(self.0)
            .await?
        {
            None => Route::NotFound,
            Some(row) => match (row.module, row.address) {
                // Route to final location
                (Some(module), Some(address)) => Route::Routed(module, address),
                // Alias to another location
                (None, Some(address)) => Route::Alias(address),
                // Route is offline
                (Some(_), None) => Route::Offline,
                // Route is not routable
                (None, None) => Route::Reserved,
            },
        };

        tracing::trace!("route is at `{route:?}`");

        Ok(route)
    }

    pub async fn register(&self, ext: &str, address: &str, ttl: u32) -> anyhow::Result<bool> {
        tracing::trace!("registering `{ext}` at `{address}` for {ttl}s");

        let registered = sqlx::query!(
            "UPDATE ext SET address = ?, expiry = CURRENT_TIMESTAMP + ? WHERE ext.ext = ? RETURNING ext.ext",
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
            "UPDATE ext SET address = NULL WHERE ext.ext = ? RETURNING ext.ext",
            ext
        )
        .fetch_optional(self.0)
        .await?;

        Ok(unregistered.is_some())
    }
}
