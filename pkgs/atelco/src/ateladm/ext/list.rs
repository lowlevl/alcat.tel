use derive_more::Display;
use sqlx::SqlitePool;
use tabled::{Tabled, derive::display, settings::style};

pub async fn exec(database: SqlitePool) -> anyhow::Result<()> {
    #[derive(Debug, Display)]
    #[display(rename_all = "lowercase")]
    enum State {
        Routed,
        Alias,
        Offline,
        Reserved,
    }

    #[derive(Tabled)]
    struct Ext {
        ext: String,

        #[tabled(display("display::option", "(none)"))]
        module: Option<String>,

        #[tabled(display("display::option", "(none)"))]
        address: Option<String>,

        state: State,

        #[tabled(display("display::option", ""))]
        ttl: Option<u64>,
    }

    let exts = sqlx::query!(
        r#"
        SELECT ext,
            module,
            address,
            expiry - UNIXEPOCH() as "ttl: u64"
        FROM ext
        ORDER BY module, ext
        "#
    )
    .fetch_all(&database)
    .await?
    .into_iter()
    .map(|row| {
        // FIXME: maybe golf this with routing
        let state = match (&row.module, &row.address) {
            (Some(_), Some(_)) => State::Routed,
            (None, Some(_)) => State::Alias,
            (Some(_), None) => State::Offline,
            (None, None) => State::Reserved,
        };

        Ext {
            ext: row.ext,
            module: row.module,
            address: row.address,
            state,
            ttl: row.ttl,
        }
    });

    let mut table = tabled::Table::builder(exts).build();
    let table = table.with(style::Style::rounded());

    println!("{table}");

    Ok(())
}
