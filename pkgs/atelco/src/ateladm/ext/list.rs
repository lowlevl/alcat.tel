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
    }

    let exts = sqlx::query!(
        r#"
            SELECT ext, module, address FROM ext
            ORDER BY module, ext
        "#
    )
    .fetch_all(&database)
    .await?
    .into_iter()
    .map(|record| {
        // FIXME: maybe golf this with routing
        let state = match (&record.module, &record.address) {
            (Some(_), Some(_)) => State::Routed,
            (None, Some(_)) => State::Alias,
            (Some(_), None) => State::Offline,
            (None, None) => State::Reserved,
        };

        Ext {
            ext: record.ext,
            module: record.module,
            address: record.address,
            state,
        }
    });

    let mut table = tabled::Table::builder(exts).build();
    let table = table.with(style::Style::rounded());

    println!("{table}");

    Ok(())
}
