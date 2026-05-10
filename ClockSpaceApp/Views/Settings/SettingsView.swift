//
//  SettingsView.swift
//  ClockSpace
//
//  Dark-mode settings sheet matching macOS utility app conventions.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var licenseManager: LicenseManager
    @State private var startOnLogin: Bool = true
    @Environment(\.openURL) var openURL
    @State private var installedCount: Int = 0
    @AppStorage("cs_checkForUpdates") private var checkForUpdates: Bool = true
    @State private var showCredits: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "gear")
                            .font(.system(size: 24))
                        Text("Settings")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .padding(.bottom, 8)
                    
                    // General Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("General")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CSTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            toggleRow(title: "Launch at Login", isOn: $startOnLogin)
                            Divider().background(Color.white.opacity(0.1))
                            toggleRow(title: "Check for Updates automatically", isOn: $checkForUpdates)
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Screensaver Directory")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Open in Finder") {
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: FileSystemService.shared.screenSaversDirectory.path)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                                .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CSTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Theme")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Dark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(CSTheme.textSecondary)
                            }
                            .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // License Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("License")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CSTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Status")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(licenseManager.isPro ? "\(licenseManager.tierName) Activated" : "Free Tier")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(licenseManager.isPro ? .green : CSTheme.textSecondary)
                            }
                            .padding(.vertical, 12)
                            
                            if licenseManager.isPro {
                                Divider().background(Color.white.opacity(0.1))
                                HStack {
                                    Text("License Key")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(licenseManager.maskedKey)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(CSTheme.textSecondary)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CSTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Version")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("v\(CSConstants.appVersion) (Build \(CSConstants.buildNumber))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(CSTheme.textSecondary)
                            }
                            .padding(.vertical, 12)
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Installed Screensavers")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(installedCount)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(CSTheme.textSecondary)
                            }
                            .padding(.vertical, 12)
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("GitHub Repository")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Open Repo") {
                                    if let url = URL(string: "https://github.com/CivicEase/ClockSpace") {
                                        openURL(url)
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                                .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.vertical, 12)
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("License")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button("View License") {
                                    if let url = URL(string: "https://github.com/CivicEase/ClockSpace/blob/main/LICENSE") {
                                        openURL(url)
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                                .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Project")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CSTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("About & Credits")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button("View Credits") {
                                    showCredits = true
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                                .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.vertical, 12)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Version")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("0.50 (Open Source)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(CSTheme.textSecondary)
                            }
                            .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Footer Links
                    HStack(spacing: 32) {
                        Button("Terms of Use") {}
                        Button("Privacy Policy") {}
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(CSTheme.textTertiary)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Close Action
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(32)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 800, height: 600)
        .background(CSTheme.backgroundPrimary)
        .preferredColorScheme(.dark)
        .onAppear {
            installedCount = ScreensaverManager.shared.installedIDs.count
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
    
    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.8)
                .labelsHidden()
        }
    }
}
