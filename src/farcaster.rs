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
        // TODO: put configs somewhere specific
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
                warn!(?post, "actually do something here");

                // TODO: if post is already in db, return early

                self.sled_db.insert(post.shortcode, "true")?;
                respond_to.send(()).unwrap();
                Ok(())
            }
        }
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
