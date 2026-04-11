use atelco::ext::DataExt;
use futures::{AsyncRead, AsyncWrite};
use sqlx::SqlitePool;
use yengine::engine::{Engine, Request};

pub struct Authd {
    pub database: SqlitePool,
    pub priority: u64,
}

impl yengine::Module for Authd {
    type Error = anyhow::Error;

    async fn install<I, O>(&self, engine: &Engine<I, O>) -> Result<(), Self::Error>
    where
        I: AsyncRead + Send + Unpin,
        O: AsyncWrite + Send + Unpin,
    {
        engine.setlocal("trackparam", module_path!()).await?;

        if !engine.install(self.priority, "user.auth", None).await? {
            anyhow::bail!("unable to register `user.auth` handler");
        }
        if !engine.install(self.priority, "user.register", None).await? {
            anyhow::bail!("unable to register `user.register` handler");
        }
        if !engine
            .install(self.priority, "user.unregister", None)
            .await?
        {
            anyhow::bail!("unable to register `user.unregister` handler");
        }

        atelco::sigterm(engine).await
    }

    #[tracing::instrument(
        name = "req",
        level = "trace",
        skip_all,
        fields(name = request.name)
    )]
    async fn on_message<I, O>(
        &self,
        _: &Engine<I, O>,
        request: &mut Request,
    ) -> Result<bool, Self::Error>
    where
        I: AsyncRead + Send + Unpin,
        O: AsyncWrite + Send + Unpin,
    {
        if request.name == "user.auth"
            && let Some(username) = request.kv.get("username")
            && let Some(password) = self
                .database
                .extension(username)
                .await?
                .and_then(|extension| extension.password)
        {
            let username = username.clone();

            tracing::debug!("<{username}> has a password, attempting authentication");

            request.retvalue = password;
            request.kv.insert("caller".into(), username);

            Ok(true)
        } else if request.name == "user.register"
            && let Some(caller) = request.kv.get("caller")
            && let Some(expires) = request.kv.get("expires")
            && let Some(data) = request.kv.get("data")
        {
            let ttl = expires.parse().unwrap_or(60);
            self.database.register(caller, data, ttl).await?;

            tracing::debug!("registered location <{data}> as {caller} for {ttl}s");

            Ok(true)
        } else if request.name == "user.unregister"
            && let Some(caller) = request.kv.get("caller")
            && let Some(data) = request.kv.get("data")
        {
            let unregistered = self.database.unregister(caller, data).await?;
            if unregistered {
                tracing::debug!("unregistered location <{data}> from {caller}");
            }

            Ok(unregistered)
        } else {
            Ok(false)
        }
    }
}
