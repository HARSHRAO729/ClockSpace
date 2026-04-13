//
//  ExploreView.swift
//  ClockSpace
//
//  Explore tab — curated discovery experience with
//  "Discover All" alphabetical browsing, category filtering,
//  and tag cloud navigation.
//

import SwiftUI

struct ExploreView: View {
    
    @EnvironmentObject var apiManager: APIManager
    @State private var selectedFilter: String? = "4K"
    @State private var showDiscoverAll: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showDiscoverAll {
                // ── Discover All: Full Alphabetical Grid ──
                discoverAllView
            } else if let category = apiManager.selectedCategory {
                // ── Category Detail View ──
                categoryDetailView(for: category)
            } else {
                // ── Standard Explore Content ──
                exploreHero
                
                VStack(spacing: CSTheme.Spacing.xxl) {
                    // ── Tag Discovery Hub ──
                    tagCloud
                    
                    // ── Latest Wallpapers (4-Column Grid) ──
                    exploreSection(
                        title: "Latest Wallpapers",
                        subtitle: "Browse the newest additions to our collection",
                        items: apiManager.screensavers.filter { $0.isNew }
                    )
                    
                    // ── Categories Grid ──
                    VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                        Text("Categories")
                            .font(CSTheme.Font.sectionTitle)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation(CSTheme.Animation.standard) {
                                        apiManager.selectedCategory = category
                                    }
                                }) {
                                    categoryCard(for: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, CSTheme.Spacing.xxl)
                .padding(.top, CSTheme.Spacing.xxl)
                .padding(.bottom, CSTheme.Spacing.xxxl)
            }
        }
        .onAppear {
            if apiManager.screensavers.isEmpty {
                Task {
                    _ = try? await apiManager.fetchScreensavers()
                }
            }
        }
    }
    
    // MARK: - Discover All View (Alphabetical Grid)
    
    private var discoverAllView: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
            // Header with Back button
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(CSTheme.Animation.standard) {
                        showDiscoverAll = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Explore")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(CSTheme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(CSTheme.accent.opacity(0.1)))
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("All Screensavers")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(apiManager.screensavers.count) screensavers · Sorted A–Z")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Alphabetical Grid — 4 columns, proper spacing
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 20
            ) {
                ForEach(apiManager.screensavers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { saver in
                    ScreensaverCard(screensaver: saver)
                }
            }
        }
        .padding(.horizontal, CSTheme.Spacing.xxl)
        .padding(.bottom, 60)
    }
    
    // MARK: - Category Detail View
    
    private func categoryDetailView(for category: Category) -> some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
            // Header with Back button
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(CSTheme.Animation.standard) {
                        apiManager.selectedCategory = nil
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Explore")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(CSTheme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(CSTheme.accent.opacity(0.1)))
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Found \(apiManager.screensavers.filter { $0.category == category }.count) screensavers")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Grid — 4 columns, alphabetically sorted within category
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 20
            ) {
                ForEach(
                    apiManager.screensavers
                        .filter { $0.category == category }
                        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                ) { saver in
                    ScreensaverCard(screensaver: saver)
                }
            }
        }
        .padding(.horizontal, CSTheme.Spacing.xxl)
        .padding(.bottom, 60)
    }
    
    // MARK: - Hero
    
    private var exploreHero: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x143D36), Color(hex: 0x0A201C)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 340)
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
                
                Button(action: {
                    withAnimation(CSTheme.Animation.standard) {
                        showDiscoverAll = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Discover All")
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
    }
    
    // MARK: - Tag Cloud
    
    private var tagCloud: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagPill("Retina")
                    tagPill("4K", active: true)
                    tagPill("Dynamic")
                    tagPill("5K+")
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Category.allCases.prefix(8), id: \.self) { cat in
                        Button(action: { 
                            withAnimation { apiManager.selectedCategory = cat }
                        }) {
                            tagPill(cat.rawValue, active: apiManager.selectedCategory == cat)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagPill("Generative Art", isNew: true)
                    tagPill("Minimal")
                    tagPill("Animated")
                    tagPill("AI-Powered", isNew: true)
                    tagPill("Open Source")
                    tagPill("Interactive")
                }
            }
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
        .foregroundColor(active ? .white : CSTheme.textMuted)
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
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 20
            ) {
                ForEach(items.prefix(8)) { saver in
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
            
            Text(category.rawValue)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
