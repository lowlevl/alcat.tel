use std::collections::HashMap;

use futures::{AsyncRead, AsyncWrite, lock::Mutex};
use maplit::btreemap;
use yengine::{engine::Engine, wire::MessageAck};

pub struct Divertd {
    callwait: String,
    specdial: String,

    divertions: Mutex<HashMap<String, State>>,
}

impl Divertd {
    pub fn new(callwait: String, specdial: String) -> Self {
        Self {
            callwait,
            specdial,
            divertions: Default::default(),
        }
    }
}

enum State {
    Initialized { peerid: String },
}

impl yengine::Module for Divertd {
    type Error = anyhow::Error;

    async fn install<I, O>(&self, engine: &Engine<I, O>) -> Result<(), Self::Error>
    where
        I: AsyncRead + Send + Unpin,
        O: AsyncWrite + Send + Unpin,
    {
        engine.setlocal("trackparam", module_path!()).await?;

        if !engine.watch("chan.dtmf").await? {
            anyhow::bail!("unable to register `chan.dtmf` watcher");
        }

        atelco::sigterm(engine).await
    }

    #[tracing::instrument(
        name = "watch",
        level = "trace",
        skip_all,
        fields(name = watch.name)
    )]
    async fn on_watch<I, O>(
        &self,
        engine: &Engine<I, O>,
        watch: MessageAck,
    ) -> Result<(), Self::Error>
    where
        I: AsyncRead + Send + Unpin,
        O: AsyncWrite + Send + Unpin,
    {
        // %%<message::false:chan.dtmf::id=analog/9:module=analog:status=answered:address=local-fxs/1:targetid=analog/8:billid=1777828812-10:peerid=analog/8:lastpeerid=analog/8:answered=true:direction=outgoing:text=F:detected=analog:sequence=2:duplicate=false:handlers=callfork%z100,wave%z100,analog%z100,sip%z100,yrtp%z150

        if watch.name.as_deref() == Some("chan.dtmf")
            && watch.kv.get("status").map(String::as_str) == Some("answered")
            && watch.kv.get("module").map(String::as_str) == Some("analog")
            && watch.kv.get("text").map(String::as_str) == Some("F")
            && let Some(peerid) = watch.kv.get("peerid")
            && let Some(id) = watch.kv.get("id")
        {
            // A hook-flash (`F`) in an `answered` call from an `analog` phone.
            let mut divertions = self.divertions.lock().await;

            match divertions.get(id) {
                None => {
                    // > put the diverted party on hold
                    engine
                        .message(
                            "chan.masquerade",
                            "",
                            btreemap! {
                                "id".into() => peerid.into(),
                                "message".into() => "call.execute".into(),
                                "callto".into() => self.callwait.clone(),
                            },
                        )
                        .await?;

                    // > put the diverter party on dialing
                    engine
                        .message(
                            "chan.masquerade",
                            "",
                            btreemap! {
                                "id".into() => id.into(),
                                "message".into() => "call.execute".into(),
                                "callto".into() => "lateroute/off-hook".into(),
                            },
                        )
                        .await?;

                    // chan.attach
                    // chan.connect
                    // chan.transfer

                    divertions.insert(
                        id.clone(),
                        State::Initialized {
                            peerid: peerid.into(),
                        },
                    );
                }

                Some(State::Initialized { peerid }) => {
                    // > reconnect inital call
                    engine
                        .message(
                            "chan.connect",
                            "",
                            btreemap! {
                                "id".into() => id.into(),
                                "targetid".into() => peerid.into(),
                            },
                        )
                        .await?;
                    divertions.remove(id);
                }
            }
        }

        Ok(())
    }
}
