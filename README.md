# ClockSpace

A Mac app for finding and installing screensavers. Browse a curated catalog of clocks and animated art, pick one, and ClockSpace installs it into macOS for you.

[![Latest release](https://img.shields.io/github/v/release/HARSHRAO729/ClockSpace?label=download)](https://github.com/HARSHRAO729/ClockSpace/releases/latest)
[![CI](https://github.com/HARSHRAO729/ClockSpace/actions/workflows/ci.yml/badge.svg)](https://github.com/HARSHRAO729/ClockSpace/actions/workflows/ci.yml)
[![Licence: PolyForm Noncommercial](https://img.shields.io/badge/licence-PolyForm%20Noncommercial-blue)](LICENSE)
[![Website](https://img.shields.io/badge/website-clockspace.civicease.systems-blue)](https://clockspace.civicease.systems)

| Word Clock | Matrix | MultiClock |
| :---: | :---: | :---: |
| ![Word Clock](https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev/thumbnails/WordClock.png) | ![Matrix](https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev/thumbnails/Matrix.png) | ![MultiClock](https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev/thumbnails/MultiClock.png) |

## What it does

- **A catalog of 19 screensavers**: clocks, retro, sci-fi and more, sorted into categories, with search and favourites.
- **One-click install** into `~/Library/Screen Savers`. Each download is checked against its published checksum and its code signature before anything on your Mac is touched.
- **One at a time**: installing a new screensaver replaces the one ClockSpace installed before. Screensavers you installed yourself are left alone; if one has the same name, ClockSpace asks before replacing it.
- **Works offline** with the last catalog it downloaded.
- **Update check**: tells you when a new version of ClockSpace is out (you can turn this off in Settings).
- **Apple Silicon and Intel**. Two screensavers only run on Apple Silicon and are hidden on Intel Macs.
- **No accounts, no tracking**. See [PRIVACY.md](PRIVACY.md).

macOS does not let apps choose the active screensaver. After installing, click **Open Settings**: ClockSpace opens the screen saver list in System Settings (Wallpaper › Screen Saver on macOS 26 and later), where you pick it.

## Install

Requires macOS 14 or later.

1. Download `ClockSpace.dmg` from the [latest release](https://github.com/HARSHRAO729/ClockSpace/releases/latest).
2. Open it and drag ClockSpace into Applications.
3. ClockSpace isn't signed with an Apple Developer ID, so macOS blocks it the first time. Open **System Settings › Privacy & Security**, scroll down and click **Open Anyway**. You need to do this once per version.

## Build from source

You need Xcode 26 or later. No keys or secret files are needed.

```bash
git clone https://github.com/HARSHRAO729/ClockSpace.git
cd ClockSpace
open ClockSpace.xcodeproj
```

Press ⌘R to run and ⌘U to run the tests. See [CONTRIBUTING.md](CONTRIBUTING.md) for how the project is laid out and how to add a screensaver to the catalog.

## Screensavers and credits

Every screensaver belongs to its author and comes under its author's own terms. [THIRD_PARTY.md](THIRD_PARTY.md) lists each one with its source and licence, and the app shows the same list under Settings › Credits.

If you made one of these screensavers and want it credited differently or removed, [open an issue](https://github.com/HARSHRAO729/ClockSpace/issues).

## Licence

ClockSpace is **source-available** under the [PolyForm Noncommercial License 1.0.0](LICENSE): you may use, study and change it for non-commercial purposes; commercial use is not permitted. The screensavers in the catalog are not covered by this licence (see above). Using the app also means agreeing to the [Terms](TERMS.md).

Required Notice: Copyright CivicEase Studios. (https://civicease.com)

## More

- [ROADMAP.md](ROADMAP.md): what's next and what is deliberately left out.
- [RELEASING.md](RELEASING.md): how a release is built and published.
