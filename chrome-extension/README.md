# Digital Sabbath — Chrome Extension

A Manifest V3 Chrome extension that blocks social media and gambling sites on the summer solstice.

## Blocked Sites

- instagram.com
- tiktok.com
- twitter.com / x.com
- facebook.com
- reddit.com
- snapchat.com
- threads.net
- kalshi.com
- polymarket.com
- youtube.com *(optional — included by default)*

## Installation (Local Development)

1. Open Chrome and go to `chrome://extensions`
2. Enable **Developer mode** (toggle in the top right)
3. Click **Load unpacked**
4. Select this `chrome-extension/` directory
5. The extension is now installed — you'll see the golden icon in your toolbar

## Testing with Debug Mode

The extension only blocks sites on the sabbath day (June 20, 2026). To test blocking right now:

### Enable debug mode

Open the extension's service worker console:

1. Go to `chrome://extensions`
2. Find "Digital Sabbath" and click **Service worker** (under "Inspect views")
3. In the console, run:

```js
chrome.storage.local.set({ debugSabbath: true });
```

Blocking activates immediately. Now visit [instagram.com](https://instagram.com) — you should see the blocked page.

### Disable debug mode

```js
chrome.storage.local.set({ debugSabbath: false });
```

## How It Works

- On install/startup, the service worker checks if today is a sabbath day
- If yes, it enables the `declarativeNetRequest` ruleset that redirects blocked domains to `blocked.html`
- If no, it disables the ruleset
- An hourly alarm re-checks so the transition happens automatically at midnight
- Debug mode (`debugSabbath` in storage) forces blocking on for testing

## Adding New Sabbath Dates

Edit the `SABBATH_DATES` array in `background.js`:

```js
const SABBATH_DATES = [
  "2026-06-20",
  "2027-06-21", // add more dates here
];
```

## Adding New Blocked Sites

Add a new rule to `rules.json` following the existing pattern. Use `||domain.com` as the `urlFilter` to match all subdomains.
