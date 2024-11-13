use futures::{StreamExt, TryStreamExt};
use instagram_scraper_rs::Post;
use tokio::{
    sync::{mpsc, oneshot},
    task::JoinHandle,
};
use tokio_stream::wrappers::ReceiverStream;
use tokio_util::sync::CancellationToken;
use tracing::{error, warn};

pub struct FarcasterActor {
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
    #[allow(clippy::new_without_default)]
    pub fn new(concurrency: usize, shutdown_token: CancellationToken) -> (Self, JoinHandle<()>) {
        // TODO: put database files somewhere specified by configs
        // TODO: use mysql so we can have multiple proceses running at once
        let sled_db = sled::open("farcaster.sled").unwrap();

        let (sender, receiver) = mpsc::channel(100);

        let actor = FarcasterActor { sled_db };

        let actor_handle = tokio::spawn(async move {
            if let Err(err) = actor.run(receiver, concurrency, shutdown_token).await {
                error!(?err, "farcaster actor");
            }
        });
        let x = Self { sender };

        (x, actor_handle)
    }

    pub async fn process_post(&self, post: Post) {
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
    async fn run(
        &self,
        receiver: mpsc::Receiver<ActorMessage>,
        concurrency: usize,
        shutdown_token: CancellationToken,
    ) -> eyre::Result<()> {
        let _shutdown_guard = shutdown_token.clone().drop_guard();

        ReceiverStream::new(receiver)
            .take_until(shutdown_token.cancelled())
            .map(Ok)
            .try_for_each_concurrent(concurrency, |msg| self.handle_message(msg))
            .await
    }

    async fn handle_message(&self, msg: ActorMessage) -> eyre::Result<()> {
        match msg {
            ActorMessage::HandlePost { post, respond_to } => {
                self.handle_post(post).await?;
                respond_to.send(()).unwrap();
                Ok(())
            }
        }
    }

    async fn handle_post(&self, post: Post) -> eyre::Result<()> {
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
