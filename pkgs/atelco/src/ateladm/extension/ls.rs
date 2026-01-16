use futures::{StreamExt, TryStreamExt};
use sqlx::SqlitePool;
use tabled::{Tabled, derive::display, settings::style};

pub async fn exec(database: SqlitePool) -> anyhow::Result<()> {
    #[derive(Tabled)]
    struct Ext {
        number: String,

        #[tabled(display("display::option", "(none)"))]
        ringback: Option<String>,

        locations: String,
    }

    let extensions = sqlx::query!(
        r#"
        SELECT *
        FROM extension
        "#
    )
    .fetch_all(&database)
    .await?;

    let data = futures::stream::iter(extensions)
        .then(async |extension| {
            let locations = sqlx::query!(
                r#"
                SELECT
                    data,
                    expiry - UNIXEPOCH() as ttl
                FROM location
                WHERE location.number = ?
                ORDER BY ttl DESC
                "#,
                extension.number
            )
            .fetch_all(&database)
            .await?;

            let locations = locations
                .into_iter()
                .map(|location| {
                    let mut line = location.data;

                    if let Some(ttl) = location.ttl {
                        if ttl >= 0 {
                            line += &format!(", ttl {ttl}s");
                        } else {
                            line += ", ttl expired";
                        }
                    }

                    line
                })
                .collect::<Vec<_>>();

            let mut locations = locations.join("\n");
            if locations.is_empty() {
                locations += "(offline)";
            }

            anyhow::Ok(Ext {
                number: extension.number,
                ringback: extension.ringback,
                locations,
            })
        })
        .try_collect::<Vec<_>>()
        .await?;

    let mut table = tabled::Table::builder(data).build();
    let table = table.with(style::Style::rounded());

    println!("{table}");

    Ok(())
}
