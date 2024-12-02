# 🖼️ frames-v2-demo

Based on the [Farcaster Frames v2 demo app](https://github.com/farcasterxyz/frames-v2-demo?tab=readme-ov-file).

[🛠️ Frame Playground](https://warpcast.com/~/developers/frame-playground) (Mobile only)<br/>
[📦 Frame SDK](https://github.com/farcasterxyz/frames/)<br/>
[👀 Dev preview docs](https://github.com/farcasterxyz/frames/wiki/frames-v2-developer-playground-preview)<br/>

## Getting Started

This is a [NextJS](https://nextjs.org/) + TypeScript + React app.

Select the right version of node:

```bash
nvm use || (nvm install && nvm use)
```

To install dependencies:

```bash
yarn
```

To run the app:

```bash
yarn dev
```

To try your app in the Warpcast playground, you'll want to use a tunneling tool like [ngrok](https://ngrok.com/).

```bash
ngrok http 3000
```

# Notes

- If you open the app in a normal browser, it loads, but its pretty broken. This site is only built to work inside a frame. How can we make it work without a frame context?
- set `accountAssociation` in `src/app/.well-known/farcaster.json`
