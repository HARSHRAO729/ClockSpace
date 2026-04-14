# 🌌 ClockSpace

**ClockSpace** is an elite, premium macOS application that completely redefines the screensaver experience. Built with the high-fidelity **CivicEase** design system, it delivers 60-FPS Quartz-rendered graphics straight to your lock screen.

[![Official Website](https://img.shields.io/badge/Website-clockspace.civicease.systems-blue?style=for-the-badge&logo=safari)](https://clockspace.civicease.systems)
[![Status: Development](https://img.shields.io/badge/Status-Early_Production-orange?style=for-the-badge)](https://github.com/HARSHRAO729/ClockSpace)

---

## ⚠️ Development Status & Disclaimer

**ClockSpace is currently in its early production and active development phase.** 

While we strive for excellence in architectural design and visual fidelity, users may encounter installation complexities, feature malfunctions, or occasional application instability. We deeply regret any inconvenience caused by these early-stage issues and are working tirelessly to refine the experience. 

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

## 🤝 Contributing
We welcome community contributions specifically for the `Community/` folder and UI refinements. Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

For founders and maintainers: See [RELEASING.md](RELEASING.md) for instructions on building and publishing new versions.

*Design with ❤️ by [HARSHRAO729](https://github.com/HARSHRAO729) & CivicEase Studios.*
