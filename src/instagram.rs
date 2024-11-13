use crate::farcaster::FarcasterHandle;
use eyre::Context;
use futures::{StreamExt, TryStreamExt};
use instagram_scraper_rs::InstagramScraper;
use tokio::{
    sync::{mpsc, oneshot, Mutex},
    task::JoinHandle,
};
use tokio_stream::wrappers::ReceiverStream;
use tokio_util::sync::CancellationToken;
use tracing::{error, info};

pub struct InstagramActor {
    farcaster_handle: FarcasterHandle,
    scraper: Mutex<InstagramScraper>,
}

pub enum ActorMessage {
    /// TODO: i think this could be cut into a login and a profile fetch and then a posts query. but one is simpler and we only have the one path right now
    FetchProfilePosts {
        profile: String,
        respond_to: oneshot::Sender<()>,
    },
    /// TODO: i'm not sure we need this
    Logout { respond_to: oneshot::Sender<()> },
}

#[derive(Clone)]
pub struct InstagramHandle {
    sender: mpsc::Sender<ActorMessage>,
}

impl InstagramHandle {
    pub fn new(
        username: String,
        password: String,
        concurrency: usize,
        farcaster_handle: FarcasterHandle,
        shutdown_token: CancellationToken,
    ) -> (Self, JoinHandle<()>) {
        let (sender, receiver) = mpsc::channel(100);

        let mut scraper = InstagramScraper::default();

        scraper = scraper.authenticate_with_login(username, password);

        let actor = InstagramActor {
            farcaster_handle,
            scraper: Mutex::new(scraper),
        };
        let spawn_handle = tokio::spawn(async move {
            if let Err(err) = actor.run(receiver, concurrency, shutdown_token).await {
                error!(?err, "instagram actor");
            }
        });

        let x = Self { sender };

        (x, spawn_handle)
    }

    pub async fn fetch_posts(&self, profile: String) {
        let (send, recv) = oneshot::channel();

        let msg = ActorMessage::FetchProfilePosts {
            profile,
            respond_to: send,
        };
        let _ = self.sender.send(msg).await;

        // TODO: should this return recv instead of the answer?
        recv.await.expect("actor is gone");
    }

    pub async fn logout(&self) {
        let (send, recv) = oneshot::channel();

        let msg = ActorMessage::Logout { respond_to: send };

        let _ = self.sender.send(msg).await;

        // TODO: should this return recv instead of the answer?
        recv.await.expect("actor is gone");
    }
}

impl InstagramActor {
    async fn run(
        &self,
        receiver: mpsc::Receiver<ActorMessage>,
        concurrency: usize,
        shutdown_token: CancellationToken,
    ) -> eyre::Result<()> {
        let _shutdown_guard = shutdown_token.clone().drop_guard();

        self.scraper.lock().await.login().await.context("login")?;

        ReceiverStream::new(receiver)
            .take_until(shutdown_token.cancelled())
            .map(Ok)
            // TODO: i think we should tokio::spawn the handle_message futures. that way they run in parallel instead of just concurrently. but i should do benchmarks
            .try_for_each_concurrent(concurrency, |msg| self.handle_message(msg))
            .await
    }

    async fn handle_message(&self, msg: ActorMessage) -> eyre::Result<()> {
        match msg {
            ActorMessage::FetchProfilePosts {
                profile,
                respond_to,
            } => {
                self.fetch_posts(profile).await?;

                let _ = respond_to.send(());

                Ok(())
            }
            ActorMessage::Logout { respond_to } => {
                self.logout().await?;

                let _ = respond_to.send(());

                Ok(())
            }
        }
    }

    async fn fetch_posts(&self, profile: String) -> eyre::Result<()> {
        // TODO: option to login? we should already be logged in here. maybe check if logout was called?

        let user = self
            .scraper
            .lock()
            .await
            .scrape_userinfo(&profile)
            .await
            .context("scraping user info")?;

        info!(
            "{}: {} (followers: {}; following {}) - user id: {}",
            user.username,
            user.biography.as_deref().unwrap_or_default(),
            user.followers(),
            user.following(),
            user.id
        );

        // TODO: how should we fetch more than 10 posts?
        // TODO: would be nice to give a "stop" shortcode. then we could do max_posts = max
        // TODO: this broke in a recent instagram update. need to switch to using their creator apis
        let posts = self
            .scraper
            .lock()
            .await
            .scrape_posts(&user.id, 10)
            .await
            .context("scraping posts")?;

        for post in posts {
            self.farcaster_handle.process_post(post).await;
        }

        Ok(())
    }

    async fn logout(&self) -> eyre::Result<()> {
        self.scraper
            .lock()
            .await
            .logout()
            .await
            .context("logging out")?;

        Ok(())
    }
}
