# Releasing ClockSpace

A release is a git tag (`v1.1.0`) plus a DMG on GitHub Releases. Pushing the tag builds the DMG and opens a **draft** release; nothing is public until you publish the draft.

## 1. Before tagging

1. **Version**: in Xcode, set the ClockSpace target's Version (`MARKETING_VERSION`, e.g. `1.1.0`) and Build (`CURRENT_PROJECT_VERSION`, e.g. `110`). The release fails if the tag doesn't match the version.
2. **Catalog**, if it changed:
   1. Regenerate `dist/r2-bucket` (see [CONTRIBUTING.md](CONTRIBUTING.md#adding-a-screensaver-to-the-catalog)) and run `python3 scripts/audit_savers.py`; it must report no `BROKEN` bundles.
   2. Upload the contents of **`dist/r2-bucket`** (not a backup folder) to the R2 bucket, in this order: `savers/` and `thumbnails/` first, **`catalog.json` last**. The app reads the catalog first, so every file it points to must already be there.
   3. Check that the live catalog is the new one and every file it points to answers (and every download matches its checksum):
      ```bash
      B=https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev
      [ "$(curl -s $B/catalog.json | shasum -a 256)" = "$(shasum -a 256 < dist/r2-bucket/catalog.json)" ] && echo "catalog is live"
      python3 -c "import json;[print(s['downloadURL'],s['sha256'],s['thumbnailURL']) for s in json.load(open('dist/r2-bucket/catalog.json'))]" |
        while read dl sha th; do
          [ "$(curl -sf "$dl" | shasum -a 256 | cut -d' ' -f1)" = "$sha" ] || echo "BAD $dl"
          curl -sfI "$th" >/dev/null || echo "MISSING $th"
        done
      ```
   4. Copy `dist/r2-bucket/catalog.json` to `ClockSpaceApp/Resources/catalog.json` (the copy built into the app).
3. **Tests**: `xcodebuild test -project ClockSpace.xcodeproj -scheme ClockSpace -destination 'platform=macOS'`, and make sure CI is green on the branch.

## 2. Tag and publish

```bash
git tag -a v1.1.0 -m "ClockSpace 1.1.0"
git push origin v1.1.0
```

The [Release workflow](.github/workflows/release.yml) then:
1. runs the tests;
2. builds a universal (Apple Silicon + Intel) Release app;
3. runs `scripts/check_bundle.sh` on it: universal binary, bundled catalog present, no leftover config, entitlements or source files, no `/Users/` path in the binary, and version equal to the tag;
4. builds `ClockSpace.dmg` and attaches it to a draft release with install steps and GitHub's generated notes.

Open the draft under Releases, edit the notes, and publish it. Once published, the app's update check offers it to people on older versions.

## Building locally

```bash
EXPECTED_VERSION=v1.1.0 ./scripts/build_release.sh
```

This produces `ClockSpace.dmg` in the project folder, with the same bundle check. The DMG window layout uses Finder scripting; if that isn't available the DMG is still built, with the default layout.

The DMG background is `scripts/assets/dmg_background.tiff`. To change it, edit and run `swift scripts/make_dmg_background.swift`; its window size and icon positions must match `scripts/create_dmg.sh`.

## Signing

The app is signed ad hoc (no Apple Developer ID), so it is not notarized. People open it the first time through System Settings › Privacy & Security › Open Anyway; the README, the release notes and the DMG background all say so.
