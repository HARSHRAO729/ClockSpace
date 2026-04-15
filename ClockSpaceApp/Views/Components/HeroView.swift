//
//  HeroView.swift
//  ClockSpace
//
//  Massive edge-to-edge featured hero with gradient fade-out and
//  a horizontally scrolling "Featured" carousel overlapping the bottom edge.
//

import SwiftUI
import Combine

struct HeroView: View {
    
    let featuredScreensavers: [Screensaver]
    @EnvironmentObject var apiManager: APIManager
    @State private var hoveredCard: UUID?
    @State private var currentIndex: Int = 0
    
    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    
    var currentItem: Screensaver? {
        guard !featuredScreensavers.isEmpty else { return nil }
        return featuredScreensavers[currentIndex % featuredScreensavers.count]
    }
    
    var body: some View {
        GeometryReader { container in
            ZStack(alignment: .bottom) {
                // ── Featured Hero Image (animated transition) ──
                Group {
                    if let item = currentItem {
                        heroImage(for: item, containerWidth: container.size.width)
                            .id(item.id)
                            .transition(.opacity)
                    } else {
                        heroPlaceholder
                            .frame(width: container.size.width, height: 400)
                    }
                }
                .animation(.easeInOut(duration: 1.2), value: currentIndex)
                
                // ── Overlapping Carousel (Selection Overlay) ──
                VStack(alignment: .leading, spacing: CSTheme.Spacing.md) {
                    Text("Wallspace's Pick")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, CSTheme.Spacing.xxl)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: CSTheme.Spacing.md) {
                            ForEach(Array(featuredScreensavers.prefix(6).enumerated()), id: \.offset) { index, saver in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        currentIndex = index
                                    }
                                }) {
                                    FeaturedThumbnail(
                                        screensaver: saver,
                                        isHovered: hoveredCard == saver.id,
                                        isActive: currentIndex == index
                                    )
                                }
                                .buttonStyle(.plain)
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
                    .frame(width: container.size.width, alignment: .leading)
                }
                .frame(width: container.size.width, alignment: .leading)
                .padding(.bottom, 8)
            }
            .frame(width: container.size.width, height: 400, alignment: .topLeading)
        }
        .frame(height: 400)
        .clipped()
        .contentShape(Rectangle())
        .onChange(of: currentIndex) { _, _ in
            // Index changed
        }
        .onReceive(timer) { _ in
            let nextIndex = featuredScreensavers.isEmpty ? 0 : (currentIndex + 1) % featuredScreensavers.count
            withAnimation(.easeInOut(duration: 1.2)) {
                currentIndex = (currentIndex + 1) % featuredScreensavers.count
            }
        }
    }
    
    // MARK: - Hero Image
    
    private func heroImage(for heroItem: Screensaver, containerWidth: CGFloat) -> some View {
        ZStack {
            // Cinematic background (Image or gradient)
            if heroItem.thumbnailURL != "placeholder",
               let nsImage = NSImage(named: heroItem.thumbnailURL) ?? NSImage(contentsOfFile: "/Users/harshrao/ClockSpace/scratch/all_previews/" + heroItem.thumbnailURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: containerWidth)
                    .frame(height: 400)
                    .clipped()
            } else {
                gradient(for: heroItem)
                    .frame(width: containerWidth)
                    .frame(height: 400)
            }
            
            // Hero info overlay
            VStack(alignment: .leading, spacing: CSTheme.Spacing.md) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(heroItem.name)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 20)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: 760, alignment: .leading)
                    
                    Text(heroItem.category.rawValue.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(4)
                        .padding(.top, -10)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    HStack(spacing: 12) {
                        Text(heroItem.category.rawValue)
                        Text(heroItem.resolution ?? "4K")
                        Text(heroItem.fileSize ?? "Dynamic")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(CSTheme.Animation.standard) {
                            apiManager.detailedScreensaver = heroItem
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("View Screensaver")
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 30).fill(Color.white))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        apiManager.toggleLiked(heroItem)
                    }) {
                        Image(systemName: apiManager.isLiked(heroItem) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(apiManager.isLiked(heroItem) ? .red : .white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, CSTheme.Spacing.xxl)
            .padding(.bottom, 100) // Reduced bottom padding to fit 400 height
        }
        .frame(width: containerWidth)
        .frame(height: 400)
        .clipped()
        .contentShape(Rectangle())
    }
    
    private var heroPlaceholder: some View {
        CSTheme.surface
            .frame(height: 400)
            .shimmer()
    }
    
    private func gradient(for saver: Screensaver) -> LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(colors: [Color(hex: 0x1E1B4B), Color(hex: 0x312E81), Color(hex: 0x4338CA).opacity(0.4)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x064E3B), Color(hex: 0x065F46), Color(hex: 0x047857).opacity(0.4)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x7C2D12), Color(hex: 0x9A3412), Color(hex: 0xB45309).opacity(0.4)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x4C1D95), Color(hex: 0x5B21B6), Color(hex: 0x6D28D9).opacity(0.4)], startPoint: .top, endPoint: .bottom),
        ]
        let index = abs(saver.name.hashValue) % gradients.count
        return gradients[index]
    }
}

// MARK: - Featured Thumbnail

struct FeaturedThumbnail: View {
    
    let screensaver: Screensaver
    let isHovered: Bool
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.sm) {
            // Thumbnail image
            ZStack(alignment: .topLeading) {
                Group {
                    if screensaver.thumbnailURL != "placeholder",
                       let nsImage = NSImage(named: screensaver.thumbnailURL) ?? NSImage(contentsOfFile: "/Users/harshrao/ClockSpace/scratch/all_previews/" + screensaver.thumbnailURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                            .fill(thumbnailGradient)
                            .frame(width: 200, height: 130)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                        .stroke(isActive ? Color.white : Color.clear, lineWidth: 3)
                )
                
                // Badge
                badgeView
                    .offset(x: -6, y: -6)
            }
            
            Text(screensaver.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isActive ? .white : CSTheme.textMuted)
                .lineLimit(1)
        }
        .frame(width: 200)
        .scaleEffect(isHovered ? 1.05 : (isActive ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered || isActive)
    }
    
    @ViewBuilder
    private var badgeView: some View {
        if screensaver.isPremium {
            pillBadge(text: "PREMIUM", color: CSTheme.premiumGold, textColor: .black)
        } else if screensaver.isNew {
            pillBadge(text: "NEW", color: CSTheme.accent, textColor: .white)
        }
    }
    
    private func pillBadge(text: String, color: Color, textColor: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
            .foregroundColor(textColor)
    }
    
    private var thumbnailGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
    }
}
