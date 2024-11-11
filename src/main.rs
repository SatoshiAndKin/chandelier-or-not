pub mod farcaster;
pub mod instagram;

use eyre::Context;
use serde::Deserialize;
use tracing::info;

#[derive(Deserialize, Debug)]
struct Config {
    instagram_username: String,
    instagram_password: String,
}

#[tokio::main]
async fn main() -> eyre::Result<()> {
    dotenvy::dotenv().context("loading .env")?;

    let config = envy::from_env::<Config>().context("creating config from env")?;

    // TODO: more complex logging. and tokio-console
    tracing_subscriber::fmt::init();

    info!("Starting");

    // TODO: spawn 10 of these?
    let farcaster_handle = farcaster::FarcasterHandle::new();

    let instagram_handle = instagram::InstagramHandle::new(
        config.instagram_username.clone(),
        config.instagram_password,
        farcaster_handle,
    );

    instagram_handle
        .fetch_posts(config.instagram_username)
        .await;

    instagram_handle.logout().await;

    Ok(())
}
