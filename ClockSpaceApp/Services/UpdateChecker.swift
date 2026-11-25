//
//  UpdateChecker.swift
//  ClockSpace
//
//  Asks GitHub for the latest ClockSpace release and, if it is newer than this
//  copy, tells the user how to install it. Runs at most once a day at launch
//  (can be turned off in Settings) and on demand from Settings › Check Now.
//  Sends no data about the user: it is a plain GET of a public URL.
//

import Foundation
import os
import SwiftUI
import AppKit
import Combine

@MainActor
final class UpdateChecker: ObservableObject {

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, downloadURL: URL)
        case failed(String)
    }

    struct Release: Decodable {
        let tag_name: String
        let html_url: URL
        let assets: [Asset]
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
        }
    }

    static let shared = UpdateChecker()

    @Published private(set) var status: Status = .idle
    @AppStorage("cs_checkForUpdates") var automaticChecks = true
    @AppStorage("cs_lastUpdateCheck") private var lastCheck: Double = 0

    private init() {}

    /// The version this copy reports. Debug builds can pretend to be older with
    /// CLOCKSPACE_PRETEND_VERSION=1.0 to test the update prompt.
    var currentVersion: String {
        #if DEBUG
        if let pretend = ProcessInfo.processInfo.environment["CLOCKSPACE_PRETEND_VERSION"] { return pretend }
        #endif
        return CSConstants.appVersion
    }

    // MARK: - Checks

    /// At launch: checks if automatic checks are on and the last check was over a day ago.
    /// Shows the install prompt only when a newer version exists.
    func checkAtLaunchIfDue() async {
        guard automaticChecks, Date().timeIntervalSince1970 - lastCheck > 24 * 60 * 60 else { return }
        await check()
        if case .available(let version, let url) = status {
            promptToInstall(version: version, downloadURL: url)
        }
    }

    /// Checks now and updates `status` (used by Settings › Check Now).
    func check() async {
        status = .checking
        var request = URLRequest(url: CSConstants.latestReleaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                status = .failed("GitHub didn't answer. Try again later.")
                return
            }
            let release = try JSONDecoder().decode(Release.self, from: data)
            lastCheck = Date().timeIntervalSince1970
            let latest = Self.normalized(release.tag_name)
            if Self.isVersion(latest, newerThan: currentVersion) {
                // Prefer the DMG itself; fall back to the release page.
                let dmg = release.assets.first { $0.name.lowercased().hasSuffix(".dmg") }?.browser_download_url
                status = .available(version: latest, downloadURL: dmg ?? release.html_url)
            } else {
                status = .upToDate
            }
        } catch {
            status = .failed("Couldn't check for updates. Check your internet connection.")
            CSConstants.log.error("Update check failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Prompt

    static func installSteps(version: String, current: String) -> String {
        """
        ClockSpace \(version) is available (you have \(current)).

        To install it:
        1. Click Download and open the downloaded ClockSpace.dmg.
        2. Quit ClockSpace.
        3. Drag ClockSpace into Applications and choose Replace.
        4. Open ClockSpace again. If macOS blocks it, go to System Settings › Privacy & Security and click Open Anyway.
        """
    }

    func promptToInstall(version: String, downloadURL: URL) {
        AlertProvider.shared.currentAlert = AppAlert(
            title: "A New Version of ClockSpace Is Available",
            message: Self.installSteps(version: version, current: currentVersion),
            primaryButton: .default(Text("Download")) { NSWorkspace.shared.open(downloadURL) },
            secondaryButton: .cancel(Text("Later")))
    }

    // MARK: - Versions

    /// "v1.2" → "1.2"
    nonisolated static func normalized(_ tag: String) -> String {
        let t = tag.trimmingCharacters(in: .whitespaces)
        return t.lowercased().hasPrefix("v") ? String(t.dropFirst()) : t
    }

    /// Numeric, part by part; missing parts count as 0, so "1.1" == "1.1.0".
    nonisolated static func isVersion(_ a: String, newerThan b: String) -> Bool {
        func parts(_ v: String) -> [Int] {
            normalized(v).split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 }
        }
        let x = parts(a), y = parts(b)
        for i in 0..<max(x.count, y.count) {
            let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}
