pub mod farcaster;
pub mod instagram;
pub mod web_server;

use eyre::Context;
use serde::Deserialize;
use tokio_util::sync::CancellationToken;
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[cfg(unix)]
use tokio::signal::unix::{signal, SignalKind};

#[cfg(windows)]
use tokio::signal::windows::{signal, CtrlC};

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
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| format!("{}=debug", env!("CARGO_CRATE_NAME")).into()),
        )
        .with(tracing_subscriber::fmt::layer().pretty())
        .init();

    info!("Starting");

    let shutdown_token = CancellationToken::new();

    tokio::spawn(ctrl_c_handler(shutdown_token.clone()));

    // TODO: get this from config
    let farcaster_concurrency = 10;
    let instagram_concurrency = 10;

    // TODO: spawn 10 of these? or just have smarter parallelism in the actors?
    let (farcaster_handle, farcaster_join_handle) =
        farcaster::FarcasterHandle::new(farcaster_concurrency, shutdown_token.clone());

    let (instagram_handle, instagram_join_handle) = instagram::InstagramHandle::new(
        config.instagram_username.clone(),
        config.instagram_password,
        instagram_concurrency,
        farcaster_handle,
        shutdown_token.clone(),
    );

    let web_server_handle = tokio::spawn(web_server::main(shutdown_token.clone()));

    let shutdown_guard = shutdown_token.drop_guard();

    instagram_handle
        .fetch_posts(config.instagram_username)
        .await;

    instagram_handle.logout().await;

    drop(shutdown_guard);

    // TODO: what should we do with any errors?
    web_server_handle.await?;
    instagram_join_handle.await?;
    farcaster_join_handle.await?;

    Ok(())
}

async fn ctrl_c_handler(shutdown_token: CancellationToken) {
    #[cfg(unix)]
    let mut ctrl_c = signal(SignalKind::interrupt()).expect("failed to install Ctrl+C handler");

    #[cfg(windows)]
    unimplemented!();

    ctrl_c
        .recv()
        .await
        .expect("failed to install Ctrl+C handler");

    info!("[ctrl+c] received. Shutting down. [ctrl+c] again to force exit");
    shutdown_token.cancel();

    ctrl_c
        .recv()
        .await
        .expect("failed to install Ctrl+C handler");

    panic!("second ctrl+c forced exit");
}
