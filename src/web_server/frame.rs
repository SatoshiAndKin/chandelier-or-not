use askama_axum::Template;
use url::Url;

#[derive(Default)]
pub enum AspectRatio {
    #[default]
    Ratio1dot91x1,
    Ratio1x1,
}

#[derive(Default)]
pub enum ButtonAction {
    #[default]
    Post,
    PostRedirect,
    Link,
    Mint,
    Tx,
}

#[derive(Default)]
pub struct Button {
    label: String,
    action: Option<ButtonAction>,
    target: Option<String>,
    post_url: Option<String>,
    // TODO: more things
}

#[derive(Template)] // this will generate the code...
#[template(path = "frame.html")] // using the template in this path, relative
                                 // to the `templates` dir in the crate root
pub struct FrameTemplate {
    image: Url,
    buttons: Vec<Button>,
    post_url: Option<Url>,
    state: Option<String>,
    /// TODO: enum on this? "vNext" or date?
    version: String,
}

pub async fn initial_frame_handler() -> FrameTemplate {
    // TODO: take an ipfs hash from the path
    // TODO: if the hash is not in the database, return a 404
    // TODO: if the hash is in the database, build a frame image from the base image

    FrameTemplate {
        image: Url::parse("https://example.com").unwrap(),
        buttons: vec![
            Button {
                label: "post".to_string(),
                action: Some(ButtonAction::Post),
                ..Default::default()
            },
            Button {
                label: "post_redirect".to_string(),
                action: Some(ButtonAction::PostRedirect),
                ..Default::default()
            },
        ],
        post_url: None,
        state: None,
        version: "vNext".to_string(),
    }
}

// TODO: frame template here
pub async fn frame_post_handler() -> FrameTemplate {
    /*
    When a frame server receives a POST request:

    It must respond within 5 seconds.
    It must respond with a 200 OK and another frame, on a post button click to indicate success.
    It must respond with a 302 OK and a Location header, on a post_redirect button click to indicate success.
    It may respond with 4XX status, content-type: application/json header, and JSON body containing a message property that is <= 90 characters to indicate an application-level error.
    Any Location header provided must contain a URL that starts with http:// or https://.
     */

    // TODO: <head> tag with farcaster frame things in it
    // TODO: 5 second timeout
    FrameTemplate {
        image: Url::parse("https://example.com").unwrap(),
        buttons: vec![
            Button {
                label: "post".to_string(),
                action: Some(ButtonAction::Post),
                ..Default::default()
            },
            Button {
                label: "post_redirect".to_string(),
                action: Some(ButtonAction::PostRedirect),
                ..Default::default()
            },
        ],
        post_url: None,
        state: None,
        version: "vNext".to_string(),
    }
}
