use std::net::IpAddr;

use atelco::ext::DataExt;
use futures::{AsyncRead, AsyncWrite};
use sqlx::SqlitePool;
use yengine::engine::{Engine, Request};

pub struct Dectd {
    pub database: SqlitePool,
    pub priority: u64,

    pub prefix: String,
    pub address: IpAddr,
    pub success: String,
}

impl yengine::Module for Dectd {
    type Error = anyhow::Error;

    async fn install<I, O>(&self, engine: &Engine<I, O>) -> Result<(), Self::Error>
    where
        I: AsyncRead + Send + Unpin,
        O: AsyncWrite + Send + Unpin,
    {
        engine.setlocal("trackparam", module_path!()).await?;

        if !engine.install(self.priority, "call.preroute", None).await? {
            anyhow::bail!("unable to register `call.preroute` handler");
        }
        if !engine.install(self.priority, "call.route", None).await? {
            anyhow::bail!("unable to register `call.route` handler");
        }
        if !engine.install(self.priority, "user.auth", None).await? {
            anyhow::bail!("unable to register `user.auth` handler");
        }

        atelco::sigterm(engine).await
    }

    async fn on_message<I, O>(
        &self,
        _: &Engine<I, O>,
        request: &mut Request,
    ) -> Result<bool, Self::Error>
    where
        I: AsyncRead + Send + Unpin,
        O: AsyncWrite + Send + Unpin,
    {
        // Don't bother with messages not coming from the expected party.
        if request
            .kv
            .get("ip_host")
            .and_then(|ip| ip.parse::<IpAddr>().ok())
            != Some(self.address)
        {
            return Ok(false);
        }

        // We can trust the `caller` argument since we trust the
        // source party for giving us a fixed `caller` for each DECT.

        if request.name == "user.auth"
            && let Some(pp) = request.kv.get("caller")
            && let Some(caller) = self.database.lookup(pp).await?
        {
            request.kv.insert("username".into(), caller.clone());
            request.kv.insert("caller".into(), caller);

            Ok(true)
        } else if let Some(pp) = request.kv.get("caller")
            && let Some(called) = request.kv.get("called")
            && let Some(code) = called.strip_prefix(&self.prefix)
        {
            if request.name == "call.preroute" {
                // Always unpair the `pp` before attempting pairing,
                // this also allows self-service unpairing.
                self.database.unpair(pp).await?;

                Ok(true) // Let the `call.preroute` flow as `call.route`
            } else {
                request.retvalue = if self.database.pair(pp, code).await? {
                    self.success.clone()
                } else {
                    "-".into()
                };

                Ok(true)
            }
        } else {
            Ok(false)
        }
    }
}
