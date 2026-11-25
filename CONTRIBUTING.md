# Contributing to ClockSpace

Thanks for helping. Bug reports, fixes and new screensaver suggestions are all welcome.

ClockSpace is source-available under the [PolyForm Noncommercial License 1.0.0](LICENSE). By contributing you agree that your contribution is shared under the same licence.

## Reporting a bug

Open an issue with:
- what you did, what you expected, and what happened instead;
- your macOS version and whether your Mac is Apple Silicon or Intel;
- the ClockSpace version (Settings › General › About).

## Setting up

You need **Xcode 26 or later** (the project uses Swift 6.2 features) and macOS 14 or later. No keys, accounts or secret files are needed.

```bash
git clone https://github.com/HARSHRAO729/ClockSpace.git
cd ClockSpace
open ClockSpace.xcodeproj
```

- **Run**: ⌘R. The app signs itself ad hoc, so no Apple developer account is needed.
- **Test**: ⌘U, or from the command line:
  ```bash
  xcodebuild test -project ClockSpace.xcodeproj -scheme ClockSpace -destination 'platform=macOS'
  ```

Every push and pull request runs the same tests plus a universal Release build in GitHub Actions ([ci.yml](.github/workflows/ci.yml)).

## How the code is laid out

| Folder | What lives there |
|---|---|
| `ClockSpaceApp/Models` | Catalog entries (`Screensaver`), categories, navigation state, constants |
| `ClockSpaceApp/Services` | Catalog loading (`APIManager`), downloading and checking savers (`InstallerService`), installing them (`ScreensaverManager`, `FileSystemService`), pictures (`ImagePipeline`), the update check |
| `ClockSpaceApp/Views` | SwiftUI screens: `Tabs` (Home, Explore, Library), `Dashboard` (main window, detail view), `Settings`, shared `Components` |
| `ClockSpaceApp/DesignSystem` | Colours, spacing and fonts (`CSTheme`) |
| `ClockSpaceTests` | Unit tests (Swift Testing) |
| `native-savers` | Source of ClockSpace's own screensavers (Word Clock) |
| `scripts` | Building savers, the catalog, screenshots and the DMG |

Conventions:
- Code runs on the main actor by default (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Mark slow work `@concurrent` or `nonisolated` so it runs off the main thread.
- Log with `CSConstants.log` (add `import os` to the file).
- Use the `CSTheme` tokens for colours and spacing rather than new literal values.
- The window has a fixed size (1100 × 720). Please don't make it resizable.
- Keep pull requests focused, and add a test when you change decoding, installing or version logic.

## Adding a screensaver to the catalog

The catalog is a static `catalog.json` on Cloudflare R2, with the zipped savers and their pictures next to it. Only the maintainer can upload, but you can prepare everything in a pull request or suggest a saver in an issue.

A screensaver can be added only if its licence allows redistribution, or its author agrees.

1. **Get a working `.saver`** that runs on current macOS:
   - a single-file Swift saver: `scripts/build_saver.sh <source.swift> <Module> <PrincipalClass> "<Name>" <bundle-id>`;
   - an open-source Xcode project on GitHub: `scripts/build_from_source.sh <owner/repo>` (builds it universal and signs it ad hoc).
2. **Zip it** without macOS metadata into `dist/r2-bucket/savers/<Key>.saver.zip`:
   ```bash
   ditto -c -k --norsrc --noextattr --keepParent dist/savers/<Key>.saver dist/r2-bucket/savers/<Key>.saver.zip
   ```
3. **Take a screenshot** (1280 × 800) into `dist/screenshots/<Key>.png`:
   ```bash
   xcrun swiftc -O scripts/capture_saver.swift -o /tmp/capture_saver
   /tmp/capture_saver dist/savers/<Key>.saver dist/screenshots/<Key>.png 6 --onscreen
   ```
4. **Describe it** in `scripts/build_catalog.py`: a row in `SAVERS` (name, author, category, tags), its source and licence in `SOURCES`, and add the key to `APPLE_SILICON_ONLY` if it has no Intel code.
5. **Generate and check**:
   ```bash
   CATALOG_BASE=https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev python3 scripts/build_catalog.py
   python3 scripts/audit_savers.py
   cp dist/r2-bucket/catalog.json ClockSpaceApp/Resources/catalog.json
   ```
   This also regenerates `THIRD_PARTY.md`. The audit must report no `BROKEN` bundles. The copy in `Resources` is the offline fallback built into the app; update the expected count in `ClockSpaceTests` if the number of savers changed.

## Code of conduct

Be kind and assume good intent. Harassment or personal attacks are not tolerated in issues, pull requests or discussions.
