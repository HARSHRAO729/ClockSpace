//
//  ExploreView.swift
//  ClockSpace
//
//  Placeholder for the Explore tab — curated discovery experience.
//

import SwiftUI

struct ExploreView: View {
    
    @EnvironmentObject var apiManager: APIManager
    @State private var selectedFilter: String? = "4K"
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // ── Illustrated Hero Section ──
                exploreHero
                
                VStack(spacing: CSTheme.Spacing.xxl) {
                    // ── Tag Discovery Hub ──
                    tagCloud
                    
                    // ── Latest Wallpapers (3-Column Grid) ──
                    exploreSection(
                        title: "Latest Wallpapers",
                        subtitle: "Browse the newest additions to our collection",
                        items: apiManager.screensavers.filter { $0.isNew }
                    )
                    
                    // ── Monochrome (B&W) Wallpapers ──
                    exploreSection(
                        title: "Monochrome Wallpapers",
                        subtitle: "Black and white wallpapers",
                        items: apiManager.screensavers.filter { $0.tags.contains("minimal") || $0.tags.contains("dark") }
                    )
                    
                    // ── Categories Grid ──
                    VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                        Text("Categories")
                            .font(CSTheme.Font.sectionTitle)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                            ForEach(Category.allCases, id: \.self) { category in
                                categoryCard(for: category)
                            }
                        }
                    }
                }
                .padding(.horizontal, CSTheme.Spacing.xxl)
                .padding(.top, CSTheme.Spacing.xxl)
                .padding(.bottom, CSTheme.Spacing.xxxl)
            }
        }
    }
    
    // MARK: - Hero
    
    private var exploreHero: some View {
        ZStack {
            // Illustrated background placeholder (Sonoma/Sequoia gradient style)
            LinearGradient(
                colors: [Color(hex: 0x143D36), Color(hex: 0x0A201C)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 380)
            .overlay(
                Image(systemName: "leaf.fill")
                    .font(.system(size: 160))
                    .foregroundColor(.white.opacity(0.05))
                    .rotationEffect(.degrees(-15))
                    .offset(x: 100, y: -40)
            )
            
            VStack(spacing: CSTheme.Spacing.md) {
                Text("Explore")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(.white)
                
                Text("Let your screen tell a story. No ads. No Limits.\nMade for Your Mac.")
                    .font(CSTheme.Font.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Coming Soon")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .mask(
            LinearGradient(
                colors: [.white, .white, .white.opacity(0.5), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Tag Cloud
    
    private var tagCloud: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Resolutions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagPill("Ultrawide (21:9)")
                    tagPill("Landscape (16:9)")
                    tagPill("HD (1920x1080)")
                    tagPill("4K (3840x2160)", active: true)
                }
            }
            
            // Row 2: Themes
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagPill("Nature")
                    tagPill("Space")
                    tagPill("Anime")
                    tagPill("Cars")
                    tagPill("City")
                    tagPill("Video Games")
                    tagPill("Fantasy")
                    tagPill("Cats")
                    tagPill("Monochrome (B&W)")
                }
            }
            
            tagPill("Lockscreen Exclusive", isNew: true)
        }
    }
    
    private func tagPill(_ text: String, active: Bool = false, isNew: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(text)
            if isNew {
                Text("NEW")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue))
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(active ? .white : CSTheme.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(active ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
        .overlay(
            Capsule()
                .stroke(active ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    // MARK: - Sections
    
    private func exploreSection(title: String, subtitle: String, items: [Screensaver]) -> some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(CSTheme.Font.sectionTitle)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CSTheme.textMuted)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                ForEach(items.prefix(6)) { saver in
                    ScreensaverCard(screensaver: saver)
                }
            }
        }
    }
    
    private func categoryCard(for category: Category) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .fill(category.tintColor.opacity(0.15))
                .frame(height: 140)
            
            Text(category.displayName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
