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
                Text("ClockSpace")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.white.opacity(0.1))
                    
                    Text("Coming Soon")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("New settings and features are on their way.")
                        .font(.system(size: 16))
                        .foregroundColor(CSTheme.textTertiary)
                }
                .padding(.bottom, 60)
                
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
