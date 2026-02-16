# Digital Sabbath

**The longest day, spent offline.**

A collective digital sabbath on the summer solstice. Everyone goes offline together. One day. One blacklist. No configuration. We block social media and gambling sites across every platform — iOS, Android, Chrome — so you can spend the longest day of the year in the real world.

## Sabbath Dates

- **June 20, 2026** — Summer Solstice

## Blocked Sites

| Site | Domain |
|------|--------|
| Instagram | instagram.com |
| TikTok | tiktok.com |
| Twitter/X | twitter.com, x.com |
| Facebook | facebook.com |
| Reddit | reddit.com |
| Snapchat | snapchat.com |
| Threads | threads.net |
| Kalshi | kalshi.com |
| Polymarket | polymarket.com |
| YouTube | youtube.com *(optional)* |

## Repo Structure

```
digital-sabbath/
├── ios/                  # iOS app (SwiftUI + Network Extension)
├── android/              # Android app (planned)
├── chrome-extension/     # Chrome extension (Manifest V3)
├── web/                  # Landing page (planned)
├── backend/              # Counter API (planned)
└── media/                # Brand assets, flyers, screenshots
```

## Status

| Component | Status |
|-----------|--------|
| iOS App | In progress |
| Chrome Extension | Done |
| Android App | Planned |
| Landing Page | Planned |
| Backend API | Planned |

## Getting Started

### Chrome Extension

```bash
cd chrome-extension/
```

Load as an unpacked extension in Chrome. See [chrome-extension/README.md](chrome-extension/README.md) for full instructions.

### iOS App

Open `ios/Sabbath.xcodeproj` in Xcode.

## Contributing

This is an open project. Ways to help:

- **Code** — Pick a planned component and build it. Android and the landing page are good starting points.
- **Design** — The brand lives in `media/`. Flyer templates, app store screenshots, and social posts all need work.
- **Spread the word** — The whole point is that we do this together. Tell people about June 20.

If you want to contribute, open an issue or submit a PR.

## License

MIT
