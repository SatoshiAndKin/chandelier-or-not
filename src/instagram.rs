use crate::farcaster::FarcasterHandle;
use eyre::Context;
use instagram_scraper_rs::InstagramScraper;
use tokio::sync::{mpsc, oneshot};
use tracing::info;

pub struct InstagramActor {
    farcaster_handle: FarcasterHandle,
    receiver: mpsc::Receiver<ActorMessage>,
    scraper: InstagramScraper,
}

pub enum ActorMessage {
    /// TODO: i think this could be cut into a login and a profile fetch and then a posts query. but one is simpler and we only have the one path right now
    FetchPosts {
        profile: String,
        respond_to: oneshot::Sender<()>,
    },
    Logout {
        respond_to: oneshot::Sender<()>,
    },
}

#[derive(Clone)]
pub struct InstagramHandle {
    sender: mpsc::Sender<ActorMessage>,
}

impl InstagramHandle {
    pub fn new(username: String, password: String, farcaster_handle: FarcasterHandle) -> Self {
        let (sender, receiver) = mpsc::channel(100);

        let mut scraper = InstagramScraper::default();

        scraper = scraper.authenticate_with_login(username, password);

        let actor = InstagramActor {
            receiver,
            farcaster_handle,
            scraper,
        };
        tokio::spawn(run_actor(actor));

        Self { sender }
    }

    pub async fn fetch_posts(&self, profile: String) {
        let (send, recv) = oneshot::channel();

        let msg = ActorMessage::FetchPosts {
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
    async fn handle_message(&mut self, msg: ActorMessage) -> eyre::Result<()> {
        match msg {
            ActorMessage::FetchPosts {
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

    async fn fetch_posts(&mut self, profile: String) -> eyre::Result<()> {
        // TODO: option to login

        let user = self.scraper.scrape_userinfo(&profile).await?;
        info!(
            "{}: {} (followers: {}; following {}) - user id: {}",
            user.username,
            user.biography.as_deref().unwrap_or_default(),
            user.followers(),
            user.following(),
            user.id
        );
        // TODO: how should we fetch more posts?
        // TODO: this is wrong. copy the code that fetches the user id from the upstream example
        // TODO: would be nice to give a "stop" shortcode. then we could do max_posts = max
        let posts = self.scraper.scrape_posts(&user.id, 10).await?;

        for post in posts {
            self.farcaster_handle.send_post(post).await;
        }

        Ok(())
    }

    async fn logout(&mut self) -> eyre::Result<()> {
        self.scraper.logout().await.context("logging out")?;

        Ok(())
    }
}

/// TODO: i dont like these unwraps
/// TODO: this works, but i'd like it to run concurrently, or even in parallel
/// TODO: tokio::spawn is not going to work because actor is mut
async fn run_actor(mut actor: InstagramActor) {
    actor.scraper.login().await.unwrap();

    // TODO: how can we make this parallel? or even concurrent? actor being mut makes this hard
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await.unwrap();
    }
}
