# Digital Sabbath

**June 21, 2026 — the longest day, spent offline.**

On the summer solstice, we all put down our phones together. One day. No doomscrolling. No algorithmic feeds. No gambling. No AI chatbots. Just the real world.

Digital Sabbath is an app that blocks distracting apps and websites for 24 hours on June 21, 2026. It works by filtering network requests on your device — your data never leaves your phone. When the day is over, everything goes back to normal.

## What happens on June 21?

At midnight on the summer solstice, Digital Sabbath activates. For the next 24 hours:

- **Social media feeds won't load** — Instagram, TikTok, Twitter/X, Facebook, Reddit, Snapchat, Threads, Bluesky
- **Gambling sites won't load** — Kalshi, Polymarket
- **AI chatbots won't load** — ChatGPT, Gemini, Claude
- **Everything else works normally** — calls, texts, maps, music, banking, email

You can still open the apps — but their feeds return nothing. A quiet reminder to look up.

## How it works

### iOS

A lightweight VPN runs entirely on your device. It intercepts DNS requests and returns empty responses for blocked domains. No traffic is sent to any server. No data is collected. It's local-only, privacy-first blocking.

### Chrome Extension

A Manifest V3 extension uses `declarativeNetRequest` to block the same domains in your browser. No background scripts, no data collection.

## Blocked domains

| Category | Sites |
|----------|-------|
| Social media | instagram.com, tiktok.com, twitter.com, x.com, facebook.com, reddit.com, snapchat.com, threads.net, bsky.app, bsky.social |
| Gambling | kalshi.com, polymarket.com |
| AI | chatgpt.com, openai.com, gemini.google.com, anthropic.com, claude.ai |

YouTube is excluded by default but can be optionally blocked.

## Getting started

### iOS

```bash
cd ios/
brew install xcodegen  # if not already installed
xcodegen generate
open Sabbath.xcodeproj
```

Build and run on your device (Cmd+R). The app requires a real device — the VPN extension doesn't work in the simulator.

### Chrome Extension

```bash
cd chrome-extension/
```

1. Open `chrome://extensions`
2. Enable Developer Mode
3. Click "Load unpacked" and select the `chrome-extension/` directory

### Backend (Cloudflare Worker)

The backend is a simple counter that tracks how many people have joined. It runs on Cloudflare Workers with KV storage.

```bash
cd backend/
npm install
npx wrangler dev  # local development
```

## Repo structure

```
digitalsabbath/
├── ios/                  # iOS app (SwiftUI + Network Extension)
│   ├── Sabbath/          # Main app target
│   └── PacketTunnel/     # VPN extension for DNS filtering
├── backend/              # Cloudflare Worker (join counter API)
├── chrome-extension/     # Chrome extension (Manifest V3)
├── android/              # Android app (planned)
├── web/                  # Landing page (planned)
└── media/                # Brand assets
```

## Status

| Component | Status |
|-----------|--------|
| iOS App | Working |
| Chrome Extension | Working |
| Backend API | Deployed |
| Android App | Planned |
| Landing Page | Planned |

## Contributing

This is an open project. Ways to help:

- **Code** — The Android app and landing page are the biggest open items.
- **Design** — App store screenshots, social posts, and flyer templates in `media/`.
- **Spread the word** — The whole point is that we do this together. Tell people about June 21.

## License

MIT
