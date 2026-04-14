# 🚀 How to Create a New Release

This guide explains how to build, package, and release ClockSpace for users.

## 🛠️ Method 1: Automated Release (GitHub Actions)

We have configured a GitHub Action that automatically creates a release whenever you push a new version tag.

1.  **Commit your changes** to the main branch.
2.  **Create a version tag**:
    ```bash
    git tag -a v1.0.0 -m "Release version 1.0.0"
    ```
3.  **Push the tag**:
    ```bash
    git push origin v1.0.0
    ```
4.  **Wait for the build**: Go to the "Actions" tab in your GitHub repository. The workflow will build the app and automatically create a release with the `ClockSpace.dmg` attached.

---

## 💻 Method 2: Manual Local Build

If you want to build the `.dmg` on your own machine without using GitHub Actions:

1.  **Run the build script**:
    ```bash
    ./scripts/build_release.sh
    ```
2.  **Locate the output**: After the script finishes, you will find `ClockSpace.dmg` in the root of the project.
3.  **Upload to GitHub**:
    - Go to your repository on GitHub.
    - Click on **Releases** -> **Create a new release**.
    - Choose the tag you just created.
    - Drag and drop the `ClockSpace.dmg` into the upload section.

---

## 🎨 How it works under the hood

The `scripts/build_release.sh` script performs the following steps:
1.  **Clean**: Deletes previous build artifacts.
2.  **Archive**: Runs `xcodebuild archive` to package the app into an `.xcarchive`.
3.  **Extract**: Pulls the `.app` bundle out of the archive.
4.  **DMG**: Uses the system `hdiutil` tool to create a compressed disk image (`.dmg`) containing the app.

---

## ⚠️ Important Note on Code Signing

The automated build currently disables code signing (`CODE_SIGNING_ALLOWED: NO`) to allow the build to pass in CI without Apple Developer certificates.

**Result**: When users download the `.dmg`, macOS will show a warning that the app is from an "unidentified developer." 
**Fix**: Instruct users to **Right-click** the app and select **Open** the first time they launch it.
