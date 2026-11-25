//
//  CSConstants.swift
//  ClockSpace
//
//  App-wide constants.
//

import Foundation
import os

enum CSConstants {

    // MARK: - App Identity

    /// Marketing version from Info.plist (MARKETING_VERSION), e.g. "1.1.0".
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    /// Build number from Info.plist (CURRENT_PROJECT_VERSION), e.g. "110".
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    // MARK: - Hardware

    /// True on Apple Silicon Macs, even when this process runs under Rosetta.
    nonisolated static let isAppleSilicon: Bool = {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname("hw.optional.arm64", &value, &size, nil, 0) == 0 && value == 1
    }()

    /// True while the app is only hosting the unit tests (`xcodebuild test`).
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    // MARK: - CDN

    /// Where catalog.json, savers/ and thumbnails/ are hosted (Cloudflare R2).
    static let cdnBase = URL(string: "https://pub-78f2a94f0b354729b9535c615d11e9a9.r2.dev")!
    static let catalogURL = cdnBase.appending(path: "catalog.json")

    // MARK: - Project links

    static let repoURL = URL(string: "https://github.com/HARSHRAO729/ClockSpace")!
    static let licenseURL = repoURL.appending(path: "blob/main/LICENSE")
    static let termsURL = repoURL.appending(path: "blob/main/TERMS.md")
    static let privacyURL = repoURL.appending(path: "blob/main/PRIVACY.md")
    /// GitHub's "latest release" (excludes drafts and pre-releases).
    static let latestReleaseAPI = URL(string: "https://api.github.com/repos/HARSHRAO729/ClockSpace/releases/latest")!

    // MARK: - Logging

    /// Shared logger. View output in Console.app, filtered by subsystem.
    static let log = Logger(subsystem: "CivicEase.ClockSpace", category: "app")

    // MARK: - Layout

    /// The main window has one fixed size by design: it cannot be resized
    /// or made full screen. The layout is built for exactly this size.
    enum Layout {
        /// Whole window: 1100 × 720 (as in 1.0).
        static let contentWidth: CGFloat = 1100
        /// 720 minus the 32-pt hidden title bar the system adds above the content.
        static let contentHeight: CGFloat = 688
    }
}
