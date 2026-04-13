# 🌌 ClockSpace

**ClockSpace** is an elite, premium macOS application that completely redefines the screensaver experience. Built with a high-fidelity "Wallspace" design system, it bypasses standard Apple sandbox limitations using shell interoperations to deliver compiled, 60-FPS Quartz-rendered graphics straight to your lock screen.

### 🚀 Key Features

*   **Cinematic Marketplace UI**: A flawlessly crafted Glassmorphism and SwiftUI design system with horizontal carousels, dynamic grids, and a full-screen blur focus mode.
*   **Vast Community Catalog**: Includes over 54 high-quality community-sourced screensavers pre-bundled, ranging from Matrix digital rains to minimalist flip clocks and WatchOS styles.
*   **Quartz Transformation Engine**: Features the ability to dynamically compile Swift UI and CoreGraphics code on-the-fly (`swiftc`) directly into executable `.saver` bundles.
*   **Seamless Application Flow**: A streamlined "Apply" workflow that installs bundles to `~/Library/Screen Savers/` and triggers a deep link to macOS System Settings for instant activation.
*   **Live Previews**: Dynamic, visual-first browsing experience with actual preview images from the catalog rendered in the dashboard and detail views.

### 🛠️ Architecture

*   **100% Native**: Built exclusively in SwiftUI for maximum macOS hardware acceleration.
*   **Fail-Soft Deployment**: The `ScreensaverManager.swift` engine features bulletproof compilation error-catching, automatic class mangling (`@objc`), and a fallback-resilient application flow.
*   **Secure Core**: Zero-auth architectural approach, relying on device `IOPlatformUUID` and keychain-secured license management instead of cumbersome logins.

### 🕰️ Generating the Minimal Clock

When you select "Install" from the ClockSpace application, the app generates raw Swift code, invokes your local macOS SDK path, and outputs a system-ready dynamic library:
```swift
swiftc -emit-library -o "Minimal Clock.saver/Contents/MacOS/Minimal Clock" source.swift -target arm64-apple-macosx14.4
```
It handles exact `NSPrincipalClass` linking under the hood so Apple's ScreenSaverEngine loads your code immediately, flawlessly bypassing the standard "Blue Whirlpool" placeholder.

### 📦 Installation

*(Development Version)*
1. Clone the repository: `git clone https://github.com/HARSHRAO729/ClockSpace.git`
2. Open `ClockSpace.xcodeproj` in Xcode.
3. Ensure **App Sandbox** is disabled in Signing & Capabilities.
4. Hit **Cmd + R** to run.

---
*Created by [HARSHRAO729](https://github.com/HARSHRAO729) & CivicEase Studios.*
