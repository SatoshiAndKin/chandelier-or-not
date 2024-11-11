use std::sync::Arc;

use instagram_scraper_rs::Post;
use tokio::sync::{mpsc, oneshot};
use tracing::warn;

pub struct FarcasterActor {
    receiver: mpsc::Receiver<ActorMessage>,
    sled_db: sled::Db,
}

pub enum ActorMessage {
    HandlePost {
        post: Post,
        respond_to: oneshot::Sender<()>,
    },
}

#[derive(Clone)]
pub struct FarcasterHandle {
    sender: mpsc::Sender<ActorMessage>,
}

impl FarcasterHandle {
    pub fn new() -> Self {
        // TODO: put database files somewhere specified by configs
        let sled_db = sled::open("farcaster.sled").unwrap();

        let (sender, receiver) = mpsc::channel(100);

        let actor = FarcasterActor { receiver, sled_db };
        tokio::spawn(run_actor(actor));

        Self { sender }
    }

    pub async fn send_post(&self, post: Post) {
        let (send, recv) = oneshot::channel();

        let msg = ActorMessage::HandlePost {
            post,
            respond_to: send,
        };
        let _ = self.sender.send(msg).await;
        recv.await.expect("actor is gone");
    }
}

impl FarcasterActor {
    async fn handle_message(&mut self, msg: ActorMessage) -> eyre::Result<()> {
        match msg {
            ActorMessage::HandlePost { post, respond_to } => {
                self.handle_post(post).await?;
                respond_to.send(()).unwrap();
                Ok(())
            }
        }
    }

    async fn handle_post(&mut self, post: Post) -> eyre::Result<()> {
        let t = sled::IVec::from("true");
        let f = sled::IVec::from("false");

        // if the post is already in db, return early
        match self.sled_db.get(&post.shortcode)? {
            Some(x) if x == t => {
                // we've already processed this post
                return Ok(());
            }
            Some(x) if x == f => {
                warn!(?post, "processing was previously interrupted");
                // TODO: figure out how to retry without duplicating things
                return Ok(());
            }
            Some(x) => {
                eyre::bail!("unexpected value in sled db: {:?}", x);
            }
            None => {
                // new post to us
            }
        }

        self.sled_db.insert(&post.shortcode, f)?;

        warn!(?post, "actually do something here");

        // TODO: download the image

        // TODO: create a frame that includes the image and a "yes" and "no" vote button

        // TODO: where do we collect these yes/no votes? maybe do this on-chain and take DEGEN?

        self.sled_db.insert(&post.shortcode, t)?;

        Ok(())
    }
}

async fn run_actor(mut actor: FarcasterActor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor
            .handle_message(msg)
            .await
            .expect("error handling message");
    }
}
