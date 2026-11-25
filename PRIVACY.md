# Privacy

_Last updated: November 24, 2026_

ClockSpace is a macOS app for browsing and installing screensavers. It is built to collect nothing about you.

## What ClockSpace does not do

- No accounts or sign-in.
- No analytics, tracking, advertising or crash reporting.
- No personal data is sent anywhere by the app.

## What stays on your Mac

ClockSpace keeps a few things on your Mac so it works between launches. None of it leaves your Mac.

| What | Where |
|---|---|
| Your favourites, the screensaver ClockSpace installed, your update-check setting | ClockSpace's preferences (`~/Library/Preferences/CivicEase.ClockSpace.plist`) |
| The last downloaded screensaver catalog (so the app works offline) | `~/Library/Application Support/CivicEase.ClockSpace/` |
| Downloaded screensaver pictures | `~/Library/Caches/CivicEase.ClockSpace/Images/` |
| The screensaver you install | `~/Library/Screen Savers/` |

Deleting ClockSpace and these folders removes everything it stored.

## When ClockSpace goes online

ClockSpace only downloads public files. It sends no information about you, but, as with any download, the server can see your IP address.

- **The screensaver catalog, pictures and screensaver downloads** come from ClockSpace's file host on Cloudflare R2.
- **The update check** asks GitHub for the latest ClockSpace release, at most once a day. You can turn it off in Settings › Updates.
- **Links** you click (the source code, licences, screensaver project pages) open in your web browser.

Cloudflare and GitHub may keep standard server logs under their own privacy policies.

## Screensavers you install

Each screensaver is made by its own author (see [THIRD_PARTY.md](THIRD_PARTY.md)). Once installed, it runs inside macOS, not inside ClockSpace, and some go online on their own. For example, Ealain downloads its images from an online image service. ClockSpace does not control what a screensaver does; check its project page if you want to know more.

## Questions

Open an issue at [github.com/HARSHRAO729/ClockSpace/issues](https://github.com/HARSHRAO729/ClockSpace/issues).
