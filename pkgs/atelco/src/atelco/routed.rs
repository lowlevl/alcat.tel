use atelco::router::Router;
use futures::{AsyncRead, AsyncWrite};
use yengine::engine::{Engine, Request};

pub struct Routed<'r> {
    pub priority: u64,
    pub router: Router<'r>,
}

impl yengine::Module for Routed<'_> {
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
        // Deny unauthenticated calls with `noauth`
        if request.kv.get("module").map(String::as_str) != Some("analog")
            && !request.kv.contains_key("username")
        {
            request.retvalue = "-".into();
            request.kv.insert("error".into(), "noauth".into());

            return Ok(true);
        }

        if request.name == "call.preroute"
            && let Some(module) = request.kv.get("module")
            && let Some(address) = request.kv.get("address")
            && let Some(caller) = self.router.reverse(module, address).await?
        {
            request.kv.insert("caller".into(), caller);

            Ok(true)
        } else if request.name == "call.route"
            && let Some(called) = request.kv.get("called")
            && let Some(mut extension) = self.router.extension(called).await?
        {
            let locations = self.router.route(called).await?;

            // `ringback` only works when we're at toplevel
            let ringback = extension
                .ringback
                .take_if(|_| !request.kv.contains_key("fork.master"));

            // FIXME: add loop protection

            match &locations[..] {
                // Extension is `offline`
                [] => {
                    request.retvalue = "-".into();
                    request.kv.insert("error".into(), "offline".into());
                }

                // Call routes to the caller, deny with `busy`
                [location]
                    if location.split_once("/")
                        == request
                            .kv
                            .get("module")
                            .map(String::as_str)
                            .zip(request.kv.get("address").map(String::as_str)) =>
                {
                    request.retvalue = "-".into();
                    request.kv.insert("error".into(), "busy".into());
                }

                // Extension has a single location and has no ringback
                [location] if ringback.is_none() => {
                    request.retvalue = location.into();
                }

                // Otherwise, ringback or multiple locations, it's a `fork` !
                locations => {
                    request.retvalue = "fork".into();
                    request.kv.insert("fork.stop".into(), "rejected".into());

                    if let Some(ringback) = ringback {
                        request.kv.insert("fork.fake".into(), ringback);
                        request
                            .kv
                            .insert("fork.fake.autorepeat".into(), "true".into());
                    }

                    for (idx, location) in locations.iter().enumerate() {
                        request
                            .kv
                            .insert(format!("callto.{}", idx + 1), location.into());
                    }
                }
            }

            Ok(true)
        } else {
            Ok(false)
        }
    }
}
