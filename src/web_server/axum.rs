use std::time::Duration;

use super::frame;
use askama_axum::Template;
use axum::{response::Redirect, routing::post, Router};
use tokio_util::sync::CancellationToken;
use tower_http::timeout::TimeoutLayer;
use tower_http::trace::TraceLayer;
use tracing::info;

pub async fn main(shutdown_token: CancellationToken) {
    // build our application with a route
    let app = Router::new()
        .route("/", post(frame::initial_frame_handler).get(root_handler))
        .route(
            "/frame/:image_ipfs_hash",
            post(frame::frame_post_handler).layer(TimeoutLayer::new(Duration::from_secs(5))),
        )
        .fallback(anything_else)
        .layer((
            TraceLayer::new_for_http(),
            // Graceful shutdown will wait for outstanding requests to complete. Add a timeout so
            // requests don't hang forever.
            // TODO: how do i put a l
            TimeoutLayer::new(Duration::from_secs(10)),
        ));

    // TODO: shutdown handler on ctrl+c

    // run it
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    info!("listening on {}", listener.local_addr().unwrap());
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal(shutdown_token))
        .await
        .unwrap();
}

#[derive(Template)]
#[template(path = "root.html")]
struct RootTemplate<'a> {
    name: &'a str,
}

async fn root_handler() -> RootTemplate<'static> {
    // TODO: <head> tag with farcaster frame things in it
    RootTemplate { name: "world" }
}

async fn anything_else() -> Redirect {
    // TODO: support subdomains? will do "" do that?
    Redirect::to("")
}

/// From <https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs>
async fn shutdown_signal(shutdown_token: CancellationToken) {
    shutdown_token.cancelled().await;
}
