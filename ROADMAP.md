# Roadmap

ClockSpace aims to be a small, reliable way to find and install good screensavers on the Mac.

## Done in 1.1

- Catalog of 19 screensavers that run on current macOS, with real screenshots, authors, sources and licences ([THIRD_PARTY.md](THIRD_PARTY.md)).
- Safer installs: checksum and signature checks, and the old screensaver is replaced only after the new one is ready.
- Works offline with the last catalog; faster, cached pictures.
- Home, Explore and Library, search (⌘F), favourites, keyboard navigation and VoiceOver support.
- Update check, Terms and Privacy pages.
- Firebase, accounts, licensing and the Pro tier removed; no data leaves your Mac.
- Unit tests and CI.

## Ideas for later

- More screensavers, especially open-source ones with a clear licence.
- A custom domain for the catalog.
- Localization.
- Testing on macOS 14 and 15 and on Intel Macs (help welcome if you have one).

## Left out on purpose

- **Developer ID signing and notarization.** The app is signed ad hoc, so macOS asks you to choose Open Anyway once per version.
- **Choosing the active screensaver for you.** macOS has no supported way for apps to do this; ClockSpace opens System Settings instead.
- **Accounts, sync and community uploads.** They would need a server and personal data.
- **Configuring a screensaver inside ClockSpace.** Each screensaver has its own Options button in System Settings.
- **Playlists, Launch at Login and sharing.** Removed to keep the app focused.

## Good first issues

Look for issues labelled `good first issue`, or suggest a screensaver (see [CONTRIBUTING.md](CONTRIBUTING.md#adding-a-screensaver-to-the-catalog)).
