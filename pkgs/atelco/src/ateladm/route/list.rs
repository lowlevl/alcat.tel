use sqlx::SqlitePool;
use tabled::{Tabled, derive::display, settings::style};

pub async fn exec(database: SqlitePool) -> anyhow::Result<()> {
    #[derive(Tabled)]
    struct Ext {
        ext: String,

        #[tabled(display("display::option", "(none)"))]
        module: Option<String>,

        #[tabled(display("display::option", "(none)"))]
        address: Option<String>,

        state: String,
    }

    let exts = sqlx::query!(
        r#"
        SELECT ext,
            module,
            address,
            expiry - UNIXEPOCH() as "ttl: i64"
        FROM route 
        ORDER BY module, ext
        "#
    )
    .fetch_all(&database)
    .await?
    .into_iter()
    .map(|row| {
        // NOTE: maybe golf this with routing
        let state = match (&row.module, &row.address) {
            (None, None) => "reserved".into(),
            (Some(_), None) => "offline".into(),
            (_, _) if row.ttl.unwrap_or_default() < 0 => "offline".into(),
            (None, Some(_)) => "alias".into(),
            (Some(_), Some(_)) => {
                if let Some(ttl) = row.ttl {
                    format!("routed, ttl {ttl}s")
                } else {
                    "routed".into()
                }
            }
        };

        Ext {
            ext: row.ext,
            module: row.module,
            address: row.address,
            state,
        }
    });

    let mut table = tabled::Table::builder(exts).build();
    let table = table.with(style::Style::rounded());

    println!("{table}");

    Ok(())
}
