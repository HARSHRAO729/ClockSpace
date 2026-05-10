# 🌌 ClockSpace

**ClockSpace** is an elite, premium macOS application that completely redefines the screensaver experience. While the name pays homage to our roots, ClockSpace is a comprehensive marketplace for **all** genres of digital art—from nature vistas and abstract motion to sci-fi digital rain and minimalist clocks. Built with the high-fidelity **CivicEase** design system, it delivers 60-FPS Quartz-rendered graphics straight to your lock screen.

[![Official Website](https://img.shields.io/badge/Website-clockspace.civicease.systems-blue?style=for-the-badge&logo=safari)](https://clockspace.civicease.systems)
[![Status: Development](https://img.shields.io/badge/Status-Early_Production-orange?style=for-the-badge)](https://github.com/HARSHRAO729/ClockSpace)

---

## ⚠️ Development Status & Disclaimer

**ClockSpace is currently in its early production and active development phase (v0.50).** 

While we strive for excellence in architectural design and visual fidelity, users may encounter installation complexities, feature malfunctions, or occasional application instability. We deeply regret any inconvenience caused by these early-stage issues and are working tirelessly to refine the experience. 

### What's New in v0.50
*   **🎨 Premium UI Overhaul**: Glassmorphism cards, 1.05x hover scale, live video previews, and dynamic "Apply" buttons on hover.
*   **🏗️ MVVM Architecture**: Introduced `GalleryViewModel`, centralized `AlertProvider`, and clean separation of concerns.
*   **🔧 Smart Installation Pipeline**: One-screensaver-at-a-time lifecycle, permission banners, success toast notifications, and deep-link to System Settings.
*   **📦 Remote Thumbnails**: 3-tier cached thumbnail loading (memory → disk → network) for Firebase-hosted images.
*   **🌍 Open Source Ready**: Added CONTRIBUTING.md, ROADMAP.md, in-app Credits page, and updated README.

**Join the Journey**: We believe in the power of community! If you're a developer or designer passionate about redefining the macOS experience, we warmly invite you to join us as a contributor and help shape the future of ClockSpace.

---

## 🚀 Installation & First Run

Because **ClockSpace** is currently in early development and not yet signed with an Apple Developer Certificate, macOS will show a warning when you first open it. 

### How to Open (macOS Gatekeeper)
If you see the "Apple could not verify..." message:
1. Open **System Settings** ⚙️ on your Mac.
2. Go to **Privacy & Security**.
3. Scroll down to the bottom where you see *"ClockSpace was blocked..."*
4. Click **Open Anyway** and enter your password.

*You only need to do this once per version!*

---

## ✨ Visual Experience

| Cinematic Previews | Community Favorites | Immersive Motion |
| :---: | :---: | :---: |
| ![Preview 1](ClockSpaceApp/Resources/Thumbnails/Preview1.gif) | ![Matrix](ClockSpaceApp/Resources/Thumbnails/github_matrix.gif) | ![Aerial](ClockSpaceApp/Resources/Thumbnails/Aerial.gif) |
| *Fluid Transitions* | *Digital Rain* | *Cinematic Loops* |

---

## 🚀 Key Features

*   **Cinematic Marketplace UI**: A flawlessly crafted Glassmorphism and SwiftUI design system with horizontal carousels, dynamic grids, and a full-screen blur focus mode.
*   **Vast Community Catalog**: Over 54 high-quality community-sourced screensavers pre-bundled, ranging from Matrix digital rains to minimalist flip clocks.
*   **Quartz Transformation Engine**: Dynamically compile Swift UI and CoreGraphics code on-the-fly (`swiftc`) directly into executable `.saver` bundles.
*   **One-Click Application**: Streamlined workflow that installs bundles to `~/Library/Screen Savers/` and triggers instant system activation.

---

## 🛠️ Installation & Usage

### Option 1: Run Without Xcode (Recommended)

1.  **Download**: Obtain the latest pre-compiled `.dmg` or `.app` from the [GitHub Releases](https://github.com/HARSHRAO729/ClockSpace/releases) page.
2.  **Launch**: Open the `ClockSpace.app`. You may need to right-click and select **Open** to bypass macOS gatekeeper for the first time.
3.  **Terminal Shortcut**:
    ```bash
    # If the app is in your Applications folder
    open /Applications/ClockSpace.app
    ```

### Option 2: Build from Source (Developers)

1.  Clone the repository: `git clone https://github.com/HARSHRAO729/ClockSpace.git`
2.  Open `ClockSpace.xcodeproj` in Xcode.
3.  Ensure **App Sandbox** is disabled in *Signing & Capabilities*.
4.  Hit **Cmd + R** to run.

---

## 📢 Open Source & Licensing

**ClockSpace is a CivicEase (CVK) project.** 
The brand, design language, and commercial rights are strictly reserved. This project is shared under the **PolyForm Noncommercial License 1.0.0**, which allows for personal, educational, and research use while prohibiting commercial application.

---

## 🤝 Community & Growth

ClockSpace is an open-source project that thrives on community contribution. We have a clear vision for the future and welcome developers of all skill levels.

*   **[Roadmap](ROADMAP.md)**: See what we're building next and where you can help.
*   **[Contributing Guide](CONTRIBUTING.md)**: Learn how to set up the project and submit your first PR.
*   **Good First Issues**: Check our issue tracker for tasks labeled `good-first-issue`.

---

## 📜 Credits & Curation

ClockSpace is built on the shoulders of giants. We curate and showcase some of the best open-source screensavers ever made. 

*   **Aerial**: Cinematic Apple TV screensavers by [John Coates](https://github.com/JohnCoates/Aerial).
*   **Brooklyn**: Abstract Apple animations by [Pedro Carrasco](https://github.com/pedrocarrasco/Brooklyn).
*   **Flurry**: Modern Quartz animations by [Thomas So](https://github.com/thomas-so/Flurry).

*Check the in-app **Credits** page for a full list of projects and original repositories.*

---

*Design with ❤️ by [HARSHRAO729](https://github.com/HARSHRAO729) & the Open Source Community.*
