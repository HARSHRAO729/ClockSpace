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
    @State private var enableLockScreen: Bool = true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Header (App Name branding)
                Text("wallspace")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                VStack(spacing: 48) {
                    // ── Support Section ──
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Join the Community")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "bubble.left.fill")
                                Text("Discord")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // ── Preferences Section ──
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Preferences")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                        
                        VStack(spacing: 24) {
                            toggleRow(title: "Start on Login", isOn: $startOnLogin)
                            toggleRow(title: "Enable Lock Screen", isOn: $enableLockScreen)
                            
                            HStack {
                                Text("Cache - 169 MB")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {}) {
                                    Image(systemName: "trash")
                                        .foregroundColor(CSTheme.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // ── Earn / Affiliate Section ──
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Text("Earn with Wallspace")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("40%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                        
                        HStack(spacing: 6) {
                            Text("wallspace.app/affiliate")
                                .font(.system(size: 13))
                                .foregroundColor(CSTheme.textTertiary)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(CSTheme.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // ── License Status ──
                    HStack {
                        Text("Licence")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Activated")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 160)
                .padding(.top, 60)
                
                Spacer()
                
                // ── Footer Links ──
                HStack(spacing: 32) {
                    Text("Terms of Use")
                    Text("Privacy Policies")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(CSTheme.textTertiary)
                .padding(.bottom, 24)
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
