//
//  ScreensaverManager.swift
//  ClockSpace
//
//  Owns install state for the UI. ClockSpace keeps one screensaver installed at
//  a time and only ever removes the one file it recorded installing itself.
//

import Foundation
import SwiftUI
import AppKit
import Combine
import Security

@MainActor
final class ScreensaverManager: ObservableObject {

    /// The screensaver ClockSpace installed, as recorded on disk.
    struct InstalledRecord: Codable, Equatable {
        let id: UUID
        let name: String
        let fileName: String   // e.g. "Fliqlo.saver" in ~/Library/Screen Savers
    }

    // MARK: - Published State

    @Published private(set) var installed: InstalledRecord?
    @Published private(set) var installingID: UUID?
    @Published var successMessage: String?

    var isBusy: Bool { installingID != nil }

    // MARK: - Singleton

    static let shared = ScreensaverManager()

    private let fileSystem = FileSystemService.shared
    private var cancellables = Set<AnyCancellable>()
    private static let recordKey = "cs_installed"

    private init() {
        installed = Self.loadRecord() ?? Self.migrateLegacyRecord()
        Self.removeLegacyData()
        if let installed { Self.save(installed) }
        syncWithDisk()
        // The user may delete the saver in Finder while ClockSpace is open.
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.syncWithDisk() }
            .store(in: &cancellables)
    }

    // MARK: - Queries

    func isInstalled(_ screensaver: Screensaver) -> Bool {
        installed?.id == screensaver.id
    }

    func isInstalling(_ screensaver: Screensaver) -> Bool {
        installingID == screensaver.id
    }

    // MARK: - Install

    /// Downloads and installs `screensaver`. The previously installed one is
    /// removed only after the new one is fully downloaded and checked.
    /// - Parameter replacingExisting: true once the user agreed to replace a
    ///   same-named saver that ClockSpace did not install.
    func install(_ screensaver: Screensaver, replacingExisting: Bool = false) async {
        guard installingID == nil else { return }
        installingID = screensaver.id
        defer { installingID = nil }

        do {
            let prepared = try await InstallerService.prepare(screensaver)
            defer { InstallerService.discard(prepared) }

            let fileName = prepared.fileName
            let ownedByUs = installed?.fileName == fileName
            if fileSystem.saverExists(named: fileName) && !ownedByUs && !replacingExisting {
                askToReplace(screensaver, fileName: fileName)
                return
            }

            let previous = installed
            try fileSystem.install(bundle: prepared.bundle, as: fileName)
            if let previous, previous.fileName != fileName {
                try? fileSystem.remove(saverNamed: previous.fileName)
            }
            setRecord(InstalledRecord(id: screensaver.id, name: screensaver.name, fileName: fileName))

            var message = "Installed \(screensaver.name)"
            if let previous, previous.id != screensaver.id {
                message += ", replacing \(previous.name)"
            }
            showSuccess(message + ". Choose it in System Settings.")
        } catch {
            AlertProvider.shared.showAlert(
                title: "Couldn't Install \(screensaver.name)",
                message: InstallError.from(error).localizedDescription)
        }
    }

    private func askToReplace(_ screensaver: Screensaver, fileName: String) {
        let name = (fileName as NSString).deletingPathExtension
        AlertProvider.shared.currentAlert = AppAlert(
            title: "Replace “\(name)”?",
            message: "A screensaver named “\(name)” is already in your Screen Savers folder, and ClockSpace didn't install it. Replace it with the version from ClockSpace?",
            primaryButton: .destructive(Text("Replace")) { [weak self] in
                Task { await self?.install(screensaver, replacingExisting: true) }
            },
            secondaryButton: .cancel())
    }

    // MARK: - Uninstall

    func uninstall(_ screensaver: Screensaver) {
        guard installed?.id == screensaver.id else { return }
        uninstallCurrent()
    }

    /// Removes whatever ClockSpace installed, even if it is no longer in the catalog.
    func uninstallCurrent() {
        guard let record = installed else { return }
        do {
            try fileSystem.remove(saverNamed: record.fileName)
            setRecord(nil)
        } catch {
            AlertProvider.shared.showAlert(
                title: "Couldn't Remove \(record.name)",
                message: InstallError.from(error).localizedDescription)
        }
    }

    // MARK: - System Settings

    /// Opens the screen saver list in System Settings.
    func openScreenSaverSettings() {
        NSWorkspace.shared.open(Self.screenSaverSettingsURL())
    }

    /// macOS 26 moved Screen Saver into Wallpaper; the `ScreenSaver` anchor opens its sheet.
    /// macOS 14–15 still have a separate Screen Saver pane (the old link falls back to General on 26+).
    nonisolated static func screenSaverSettingsURL(
        isMacOS26OrLater: Bool = ProcessInfo.processInfo.isOperatingSystemAtLeast(.init(majorVersion: 26, minorVersion: 0, patchVersion: 0))
    ) -> URL {
        URL(string: isMacOS26OrLater
            ? "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension?ScreenSaver"
            : "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension")!
    }

    // MARK: - Disk sync

    /// Forgets the recorded saver if its file is no longer on disk.
    func syncWithDisk() {
        if let record = installed, !fileSystem.saverExists(named: record.fileName) {
            setRecord(nil)
        }
    }

    // MARK: - Persistence

    private func setRecord(_ record: InstalledRecord?) {
        installed = record
        Self.save(record)
    }

    private static func save(_ record: InstalledRecord?) {
        if let record, let data = try? JSONEncoder().encode(record) {
            UserDefaults.standard.set(data, forKey: recordKey)
        } else {
            UserDefaults.standard.removeObject(forKey: recordKey)
        }
    }

    private static func loadRecord() -> InstalledRecord? {
        guard let data = UserDefaults.standard.data(forKey: recordKey) else { return nil }
        return try? JSONDecoder().decode(InstalledRecord.self, from: data)
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            if self?.successMessage == message { self?.successMessage = nil }
        }
    }

    // MARK: - Upgrading from 1.0 and earlier

    /// Versions up to 1.0 stored the installed IDs and the file name separately.
    /// Keeping that file tracked means installing again replaces it instead of
    /// leaving a second copy under a different name.
    private static func migrateLegacyRecord() -> InstalledRecord? {
        let defaults = UserDefaults.standard
        guard let fileName = defaults.string(forKey: "cs_last_installed_file"),
              let data = defaults.data(forKey: "cs_installedSaverIDs"),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data),
              ids.count == 1, let id = ids.first else { return nil }
        let name = (fileName as NSString).deletingPathExtension
        return InstalledRecord(id: id, name: name, fileName: fileName)
    }

    /// Removes settings written by versions before 1.1 (license, folder bookmark,
    /// old install tracking).
    private static func removeLegacyData() {
        let defaults = UserDefaults.standard
        for key in ["cs_isProActivated", "cs_licenseKey", "cs_licenseTier", "cs_startOnLogin",
                    "ScreenSaversFolderBookmark", "cs_installedSaverIDs", "cs_last_installed_file"] {
            defaults.removeObject(forKey: key)
        }
        // Crash-report cache left by the Firebase SDK (removed in 1.1).
        let support = URL.applicationSupportDirectory.appending(path: "CivicEase.ClockSpace", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: support.appending(path: "com.crashlytics"))
        // License key stored in the Keychain by versions 0.50–1.0.
        SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                       kSecAttrService as String: "CivicEase.ClockSpace"] as CFDictionary)
    }
}
