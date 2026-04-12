//
//  ScreensaverCard.swift
//  ClockSpace
//
//  Elite screensaver card: 16pt radius, vibrant overlapping badge,
//  stark white title, muted gray metadata. Install button wired to
//  ScreensaverManager with Installing → Installed state transitions.
//

import SwiftUI

struct ScreensaverCard: View {
    
    let screensaver: Screensaver
    @StateObject private var manager = ScreensaverManager.shared
    @State private var isHovering: Bool = false
    
    /// Derived install state
    private var installState: InstallState {
        if manager.activeID == screensaver.id {
            return .active
        } else if manager.isInstalling(screensaver) {
            return .installing
        } else if manager.isInstalled(screensaver) {
            return .installed
        } else {
            return .ready
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Thumbnail ──
            thumbnailView
            
            // ── Info ──
            infoSection
        }
        .background(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .fill(CSTheme.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(
                    isHovering ? screensaver.category.tintColor.opacity(0.35) : Color.white.opacity(0.06),
                    lineWidth: isHovering ? 1.0 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous))
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .shadow(
            color: isHovering ? screensaver.category.tintColor.opacity(0.15) : Color.black.opacity(0.2),
            radius: isHovering ? 24 : 12,
            y: isHovering ? 10 : 4
        )
        .animation(CSTheme.Animation.spring, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        // Error alert
        .alert(
            "Installation Error",
            isPresented: .init(
                get: { manager.lastError != nil },
                set: { if !$0 { manager.lastError = nil } }
            )
        ) {
            Button("OK") { manager.lastError = nil }
        } message: {
            Text(manager.lastError?.localizedDescription ?? "Unknown error")
        }
    }
    
    // MARK: - Thumbnail (16pt radius enforced)
    
    private var thumbnailView: some View {
        ZStack(alignment: .topLeading) {
            // Gradient placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(gradient(for: screensaver))
                .frame(height: 160)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.1))
                )
            
            // Overlapping badge (Wallspace style)
            badgeOverlay
                .offset(x: -4, y: -4)
            
            // "NEW" Badge (Wallspace style)
            if screensaver.isNew {
                Text("NEW")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color.blue)
                    )
                    .padding(CSTheme.Spacing.sm)
            }
            
            // Rank Number (Wallspace popular style)
            if let rank = screensaver.rank {
                Text("\(rank)")
                    .font(.system(size: 80, weight: .black))
                    .italic()
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: 8, y: 50)
            }
            
            // Installed/Active checkmark overlay (top-right)
            if installState == .installed || installState == .active {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(CSTheme.accent)
                        .shadow(color: CSTheme.accent.opacity(0.5), radius: 8)
                        .padding(CSTheme.Spacing.sm)
                }
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: CSTheme.Radius.large,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CSTheme.Radius.large
            )
        )
    }
    
    // MARK: - Badge
    
    @ViewBuilder
    private var badgeOverlay: some View {
        if screensaver.isPremium {
            vibrantBadge(text: "PREMIUM", icon: "crown.fill", bg: CSTheme.premiumGold, fg: .black)
        } else {
            vibrantBadge(text: "FREE", icon: "gift.fill", bg: screensaver.category.tintColor, fg: .white)
        }
    }
    
    private func vibrantBadge(text: String, icon: String, bg: Color, fg: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(text)
                .font(.system(size: 8, weight: .heavy))
                .tracking(0.6)
        }
        .foregroundColor(fg)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(bg)
        )
        .shadow(color: bg.opacity(0.4), radius: 8, y: 2)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.sm) {
            // Title — stark white, SF Pro semibold
            Text(screensaver.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Author — muted gray
            Text("by \(screensaver.author)")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(CSTheme.textTertiary)
            
            // Rating + Downloads
            HStack(spacing: CSTheme.Spacing.lg) {
                // Stars
                HStack(spacing: 1) {
                    ForEach(Array(screensaver.starIcons.prefix(5).enumerated()), id: \.offset) { _, icon in
                        Image(systemName: icon)
                            .font(.system(size: 8))
                            .foregroundColor(CSTheme.premiumGold)
                    }
                    
                    if let res = screensaver.resolution {
                        Text(res)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                            .padding(.horizontal, 4)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(2)
                    }
                    
                    if let size = screensaver.fileSize {
                        Text(size)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                    }
                    
                    Text(String(format: "%.1f", screensaver.rating))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(CSTheme.textMuted)
                        .padding(.leading, 2)
                }
                
                Spacer()
                
                // Downloads
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 9))
                        .foregroundColor(CSTheme.textTertiary)
                    
                    Text(screensaver.formattedDownloads)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(CSTheme.textMuted)
                }
            }
            
            // Tags row + CTA
            HStack {
                HStack(spacing: CSTheme.Spacing.xs) {
                    ForEach(screensaver.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                }
                
                Spacer()
                
                // ── CTA Button (stateful) ──
                installButton
            }
        }
        .padding(CSTheme.Spacing.lg)
    }
    
    // MARK: - Install Button (3-state)
    
    @ViewBuilder
    private var installButton: some View {
        switch installState {
        case .ready:
            // Default: "Install" or "$X.XX"
            Button(action: {
                Task {
                    await manager.installFromMarketplace(screensaver)
                }
            }) {
                Text(screensaver.isPremium ? screensaver.formattedPrice : "Install")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(screensaver.isPremium ? .black : .white)
                    .padding(.horizontal, CSTheme.Spacing.md)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(screensaver.isPremium ? CSTheme.premiumGold : CSTheme.accent)
                    )
            }
            .buttonStyle(.plain)
            
        case .installing:
            // Progress spinner
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.mini)
                    .tint(.white)
                
                Text("Installing…")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(CSTheme.textMuted)
            }
            .padding(.horizontal, CSTheme.Spacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
        case .installed:
            // Installed — show "Apply"
            Button(action: {
                // Determine raw system name and temp mock path
                let saverName = screensaver.name
                    .replacingOccurrences(of: " ", with: "-")
                    .lowercased()
                let saverPath = manager.screenSaversDirectory.appendingPathComponent("\(saverName).saver").path
                
                let success = manager.applyScreensaver(name: saverName, path: saverPath)
                if success {
                    manager.activeID = screensaver.id
                } else {
                    manager.lastError = ScreensaverInstallError.unknown("Failed to apply screensaver preferences.")
                }
            }) {
                HStack(spacing: 4) {
                    Text("Apply")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, CSTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(CSTheme.surfaceElevated)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            
        case .active:
            // Active checkmark state
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                Text("Active")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(CSTheme.accent)
            .padding(.horizontal, CSTheme.Spacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(CSTheme.accent.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(CSTheme.accent.opacity(0.3), lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Gradient Generator
    
    private func gradient(for saver: Screensaver) -> LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(colors: [Color(hex: 0x0F172A), Color(hex: 0x1E3A5F), Color(hex: 0x0F766E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x2D1B69), Color(hex: 0x11998E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1F1C2C), Color(hex: 0x928DAB)], startPoint: .bottom, endPoint: .top),
            LinearGradient(colors: [Color(hex: 0x0D324D), Color(hex: 0x7F5A83)], startPoint: .topLeading, endPoint: .bottomTrailing),
        ]
        let index = abs(saver.name.hashValue) % gradients.count
        return gradients[index]
    }
}

// MARK: - Install State

/// The three possible states of the install CTA button.
enum InstallState {
    case ready       // Default — show "Install" or price
    case installing  // In progress — show spinner
    case installed   // Done — show "Apply" button
    case active      // Active on system — show "Active" checkmark
}
