//
//  SettingsView.swift
//  ClockSpace
//
//  The Settings window (⌘,): General and Credits tabs.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            CreditsView()
                .tabItem { Label("Credits", systemImage: "heart") }
        }
        .frame(width: 520, height: 560)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @ObservedObject private var manager = ScreensaverManager.shared
    @ObservedObject private var updates = UpdateChecker.shared

    var body: some View {
        Form {
            Section("Screensaver") {
                LabeledContent("Installed", value: manager.installed?.name ?? "None")
                LabeledContent("Folder") {
                    Button("Show in Finder") { showFolder() }
                }
                LabeledContent("Choose the active screensaver") {
                    Button("Open System Settings") { manager.openScreenSaverSettings() }
                }
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $updates.automaticChecks)
                LabeledContent {
                    Button("Check Now") { Task { await updates.check() } }
                        .disabled(updates.status == .checking)
                } label: {
                    updateStatus
                }
                if case .available(let version, let url) = updates.status {
                    Text(UpdateChecker.installSteps(version: version, current: updates.currentVersion))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Download ClockSpace \(version)") { NSWorkspace.shared.open(url) }
                        .buttonStyle(.borderedProminent)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "\(CSConstants.appVersion) (\(CSConstants.buildNumber))")
                LabeledContent("Source code") {
                    Link("GitHub", destination: CSConstants.repoURL)
                }
                LabeledContent("Licence") {
                    Link("PolyForm Noncommercial 1.0.0", destination: CSConstants.licenseURL)
                }
                LabeledContent("Terms and privacy") {
                    HStack(spacing: 12) {
                        Link("Terms of Use", destination: CSConstants.termsURL)
                        Link("Privacy", destination: CSConstants.privacyURL)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var updateStatus: some View {
        switch updates.status {
        case .idle: Text("Version \(updates.currentVersion)")
        case .checking: Text("Checking…")
        case .upToDate: Text("ClockSpace is up to date")
        case .available(let version, _): Text("Version \(version) is available").foregroundStyle(CSTheme.accent)
        case .failed(let message): Text(message).foregroundStyle(.secondary)
        }
    }

    private func showFolder() {
        let folder = FileSystemService.shared.screenSaversDirectory
        if FileManager.default.fileExists(atPath: folder.path) {
            NSWorkspace.shared.open(folder)
        } else {
            NSWorkspace.shared.open(folder.deletingLastPathComponent())
        }
    }
}

// MARK: - Credits

struct CreditsView: View {
    @EnvironmentObject var apiManager: APIManager

    var body: some View {
        Form {
            Section {
                Text("Every screensaver in ClockSpace was made by the people below and belongs to them. ClockSpace only collects them in one place.")
                    .foregroundStyle(.secondary)
            }
            Section("Screensavers") {
                ForEach(apiManager.alphabetical) { saver in
                    LabeledContent(saver.name) {
                        HStack(spacing: 8) {
                            Text(saver.author)
                                .foregroundStyle(.secondary)
                            if let source = saver.sourceURL, let url = URL(string: source) {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .help("Open the project page")
                                .accessibilityLabel("Project page for \(saver.name)")
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
