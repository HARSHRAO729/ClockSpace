# Sprint 2 Completion Report

## 1. Service Decomposition
- **Goal:** Continue breaking down `ScreensaverManager` into `FileSystemService`, `CompilerService` (for `swiftc`/codesigning), and `InstallerService`.
- **Status:** **Completed**
- **Details:** Created `InstallerService.swift` which handles the strategy to install screensavers (either moving bundled files or triggering the `CompilerService` for templates/remote). Refactored `ScreensaverManager` to be a thin orchestrator that delegates to `InstallerService`.

## 2. JSON Migration
- **Goal:** Transition catalog data from hardcoded arrays within `APIManager` to dynamic loading from local/remote JSON.
- **Status:** **Completed**
- **Details:** Refactored `APIManager.swift` to include a `loadCatalog()` async method. It first attempts to fetch the `catalog.json` remotely via `URLSession`. If the remote call fails or is unreachable, it seamlessly falls back to the bundled local `catalog.json`.

## 3. Security
- **Goal:** Migrate sensitive data (specifically license keys) from `UserDefaults` to the macOS Keychain.
- **Status:** **Completed**
- **Details:** Verified that `LicenseManager.swift` and `KeychainService.swift` were correctly implemented to store the License Key in the Keychain securely, while retaining non-sensitive metadata (tier, active flag) in `UserDefaults`. A migration block guarantees that old keys are moved to the Keychain on startup.

## 4. UI Polish
- **Goal:** Formalize the Settings panel functionality and finalize the "Add" flow for custom screensavers.
- **Status:** **Completed**
- **Details:** 
  - Added a "License Section" to the `SettingsView.swift` which reads directly from the `LicenseManager` environment object to display the Pro status, tier, and the securely masked key.
  - Finalized the "Add" flow inside `AddScreensaverView.swift` by attaching a native `.fileImporter` that accepts `.movie` and `.video` types, enabling users to actually select an MP4 file from their system.
