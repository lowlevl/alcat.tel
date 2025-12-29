use sqlx::SqlitePool;

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
        tracing::trace!("call.preroute from `{module}/{address}`");

        if let Some(row) = sqlx::query!(
            "SELECT ext FROM ext WHERE ext.module = ? AND ext.address = ?",
            module,
            address
        )
        .fetch_optional(self.0)
        .await?
        {
            let location = row.ext;
            tracing::trace!("caller is at `{location}`");

            Ok(Some(location))
        } else {
            Ok(None)
        }
    }

    pub async fn route(&self, called: &str) -> anyhow::Result<Route> {
        tracing::trace!("call.route to `{called}`");

        match sqlx::query!("SELECT module, address FROM ext WHERE ext.ext = ?", called)
            .fetch_optional(self.0)
            .await?
        {
            None => Ok(Route::NotFound),
            Some(row) => match (row.module, row.address) {
                // Route to final location
                (Some(module), Some(address)) => Ok(Route::Routed(module, address)),
                // Alias to another location
                (None, Some(address)) => Ok(Route::Alias(address)),
                // Route is offline
                (Some(_), None) => Ok(Route::Offline),
                // Route is not routable
                (None, None) => Ok(Route::Reserved),
            },
        }
    }
}
