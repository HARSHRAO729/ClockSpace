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
    @EnvironmentObject var apiManager: APIManager
    @StateObject private var manager = ScreensaverManager.shared
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(CSTheme.Animation.standard) {
                apiManager.detailedScreensaver = screensaver
            }
        }) {
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
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - Thumbnail (16pt radius enforced)
    
    private var thumbnailView: some View {
        ZStack(alignment: .topLeading) {
            // Live Preview Simulation (Animates on hover)
            gradient(for: screensaver)
                .scaleEffect(isHovering ? 1.4 : 1.0)
                .rotationEffect(Angle.degrees(isHovering ? 10 : 0))
                .animation(Animation.linear(duration: 8.0).repeatForever(autoreverses: true), value: isHovering)
                .frame(height: 160)
                .overlay(
                    Image(systemName: isHovering ? "play.circle.fill" : "sparkles")
                        .font(.system(size: isHovering ? 48 : 32, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.2))
                        .scaleEffect(isHovering ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: isHovering)
                )
            
            // Overlapping badge (Wallspace style)
            badgeOverlay
                .offset(x: -4, y: -4)
            
            // Heart/Like Toggle (Quick Action)
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        apiManager.toggleLiked(screensaver)
                    }
                }) {
                    Image(systemName: apiManager.isLiked(screensaver) ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(apiManager.isLiked(screensaver) ? .red : .white.opacity(0.6))
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.3)).background(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .padding(CSTheme.Spacing.sm)
            }
            
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
                    .offset(y: 30) // Push below the heart
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
            if manager.isInstalled(screensaver) || manager.activeID == screensaver.id {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(CSTheme.accent)
                        .shadow(color: CSTheme.accent.opacity(0.5), radius: 8)
                        .padding(CSTheme.Spacing.sm)
                        .offset(y: 40) // Below heart
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
            
            // Resolution + Downloads
            HStack(spacing: CSTheme.Spacing.lg) {
                // Metadata Label
                HStack(spacing: 6) {
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
            
            // Tags row + Action Indicator
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
                
                // ── Preview CTA Indicator ──
                HStack(spacing: 4) {
                    Text("Preview")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(isHovering ? .white : CSTheme.textTertiary)
            }
        }
        .padding(CSTheme.Spacing.lg)
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
