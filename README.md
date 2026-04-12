# 🌌 ClockSpace: Premium macOS Marketplace

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0+-black.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-Pro%20Activated-blue.svg)](LICENSE)

**ClockSpace** is a high-end, media-centric marketplace for macOS, engineered to transform your screen into a cinematic canvas. Inspired by the Wallspace design language, it offers a seamless, immersive experience for discovering and managing premium screensaver content.

---

## ✨ Key Features

### 💎 Immersive Marketplace
Browse a curated inventory of 4K and Ultrawide screensavers. Features horizontal carousels for "Latest" and "Popular" content, and a 3-column category grid for deep discovery.

### 🔎 Search Focus Mode
Clicking the search icon triggers a **Z-Stack Focus Layer**:
- The main UI scales and blurs using an `ultraThinMaterial` overlay.
- A centered, high-utility search pill provides a friction-less discovery experience.

### 📼 Wallpaper Playlists
Create custom playlists with a dedicated management tab. Features a minimalist "Create" card with a signature dashed-border design and high-performance inventory tracking.

### 🛡️ Pro Activation Hub
A hardware-bound licensing system that recognizes your device via `IOPlatformUUID` (IOKit). No sign-in required—simply activate your pro key and unlock the community hub.

### ⚡ Community Hub (Upload)
A specialized "Share with Community" dashboard with technical drop-zones for 4K/MP4 assets. Features automated meta-data verification and "Approved" status badges.

---

## 🛠️ Technical Architecture

ClockSpace is built with **SwiftUI** and a specialized **Shell Interop Engine** that bypasses standard macOS constraints:

1. **Programmatic Installation**: Compiles and installs `.saver` bundles directly to `~/Library/Screen Savers/`.
2. **Preference Injection**: Modifies system-level `plist` domains (`com.apple.screensaver`) via shell to enable "Auto-Apply" functionality.
3. **Elite Design System**: 
    - **Color Palette**: Deep Indigo-Black (`#0F0F23`) and Premium Gold (`#FBBF24`).
    - **Glassmorphism**: Custom `ultraThinMaterial` modifiers for native macOS vibrancy.

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 or later.
- Xcode 15.3+ (for compilation).

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/HARSHRAO729/ClockSpace.git
   ```
2. Open `ClockSpace.xcodeproj`.
3. Disable **App Sandbox** in the Signing & Capabilities tab (Required for shell-based screensaver application).
4. Build and Run (`Cmd + R`).

---

## 🤝 Community & Support

Join us on **Discord** to share your custom wallpapers or get technical help.

---

*Built with ❤️ by the ClockSpace Team. Follow us on [Twitter/X](https://x.com/ClockSpaceApp).*
