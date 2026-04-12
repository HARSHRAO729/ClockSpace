//
//  HeroView.swift
//  ClockSpace
//
//  Massive edge-to-edge featured hero with gradient fade-out and
//  a horizontally scrolling "Featured" carousel overlapping the bottom edge.
//

import SwiftUI

struct HeroView: View {
    
    let featuredScreensavers: [Screensaver]
    @State private var hoveredCard: UUID?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Featured Hero Image (gradient placeholder) ──
            heroImage
            
            // ── Overlapping Carousel (Selection Overlay) ──
            VStack(alignment: .leading, spacing: CSTheme.Spacing.md) {
                // Section label
                Text("Wallspace's Pick")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, CSTheme.Spacing.xxl)
                
                // Horizontal carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CSTheme.Spacing.md) {
                        ForEach(featuredScreensavers.prefix(6)) { saver in
                            FeaturedThumbnail(
                                screensaver: saver,
                                isHovered: hoveredCard == saver.id
                            )
                            .onHover { hovering in
                                withAnimation(CSTheme.Animation.spring) {
                                    hoveredCard = hovering ? saver.id : nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CSTheme.Spacing.xxl)
                    .padding(.bottom, CSTheme.Spacing.lg)
                }
            }
            .offset(y: 40) // Overlap the hero bottom edge
        }
    }
    
    // MARK: - Hero Image
    
    private var heroImage: some View {
        ZStack {
            // Specific featured content (using the first item for mock)
            let heroItem = featuredScreensavers.first
            
            // Massive gradient background simulating a cinematic featured image
            LinearGradient(
                colors: [
                    Color(hex: 0x1E1B4B),
                    Color(hex: 0x312E81),
                    Color(hex: 0x4338CA).opacity(0.4),
                    Color(hex: 0x0F0F23).opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 480)
            
            // Hero info overlay (Left Aligned like Wallspace)
            VStack(alignment: .leading, spacing: CSTheme.Spacing.md) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FEATURED")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(CSTheme.textMuted)
                        .tracking(3)
                    
                    Text(heroItem?.name ?? "Midnight Aurora")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text(heroItem?.category.rawValue ?? "Nature")
                        Text(heroItem?.resolution ?? "4K")
                        Text(heroItem?.fileSize ?? "23MB")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CSTheme.textTertiary)
                }
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("View Screensaver")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "heart")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, CSTheme.Spacing.xxl)
            .padding(.bottom, 140)
        }
        .frame(height: 480)
        // CRUCIAL: Gradient mask for seamless fade into background
        .mask(
            LinearGradient(
                colors: [
                    .white,
                    .white,
                    .white,
                    .white.opacity(0.3),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Featured Thumbnail

struct FeaturedThumbnail: View {
    
    let screensaver: Screensaver
    let isHovered: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.sm) {
            // Thumbnail image
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                    .fill(thumbnailGradient)
                    .frame(width: 200, height: 130)
                    .overlay(
                        // Subtle sparkle
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.12))
                    )
                
                // Badge (PREMIUM / NEW)
                badgeView
                    .offset(x: -6, y: -6)
            }
            
            // Title
            Text(screensaver.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Author (muted gray)
            Text(screensaver.author)
                .font(CSTheme.Font.caption)
                .foregroundColor(CSTheme.textTertiary)
        }
        .frame(width: 200)
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .shadow(
            color: isHovered ? CSTheme.accent.opacity(0.2) : Color.clear,
            radius: 16,
            y: 6
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - Badge
    
    @ViewBuilder
    private var badgeView: some View {
        if screensaver.isPremium {
            pillBadge(text: "PREMIUM", color: CSTheme.premiumGold, textColor: .black)
        } else {
            pillBadge(text: "NEW", color: CSTheme.accent, textColor: .white)
        }
    }
    
    private func pillBadge(text: String, color: Color, textColor: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy))
            .tracking(0.8)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color)
            )
            .shadow(color: color.opacity(0.4), radius: 6, y: 2)
    }
    
    // MARK: - Gradient
    
    private var thumbnailGradient: LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(colors: [Color(hex: 0x0F172A), Color(hex: 0x1E3A5F), Color(hex: 0x0F766E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x2D1B69), Color(hex: 0x11998E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1F1C2C), Color(hex: 0x928DAB)], startPoint: .bottom, endPoint: .top),
            LinearGradient(colors: [Color(hex: 0x0D324D), Color(hex: 0x7F5A83)], startPoint: .topLeading, endPoint: .bottomTrailing),
        ]
        let index = abs(screensaver.name.hashValue) % gradients.count
        return gradients[index]
    }
}
