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

            request.retvalue = password;
            request.kv.insert("caller".into(), username);

            Ok(true)
        } else if request.name == "user.register"
            && let Some(username) = request.kv.get("username")
            && let Some(expires) = request.kv.get("expires")
            && let Some(data) = request.kv.get("data")
        {
            self.database
                .register(username, data, expires.parse().unwrap_or(60))
                .await?;

            Ok(true)
        } else if request.name == "user.unregister"
            && let Some(username) = request.kv.get("username")
            && let Some(data) = request.kv.get("data")
        {
            self.database.unregister(username, data).await
        } else {
            Ok(false)
        }
    }
}
