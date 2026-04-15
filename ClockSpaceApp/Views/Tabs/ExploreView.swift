//
//  ExploreView.swift
//  ClockSpace
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var apiManager: APIManager
    var onCategoryTap: ((Category) -> Void)? = nil
    @State private var selectedFilter: String? = "4K"
    @State private var randomizedPopular: [Screensaver] = []

    private var filteredScreensavers: [Screensaver] {
        apiManager.screensavers.filter { saver in
            guard let selected = apiManager.selectedCategory else { return true }
            return saver.category == selected
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            exploreHeroSection
            latestWallpapersSection
            discoverCommunitySection
            categoriesSection
            mostPopularSection
        }
        .task {
            if apiManager.screensavers.isEmpty {
                _ = try? await apiManager.fetchScreensavers()
            }
            randomizedPopular = filteredScreensavers.shuffled()
        }
        .onChange(of: apiManager.screensavers) { _, _ in
            randomizedPopular = filteredScreensavers.shuffled()
        }
        .onChange(of: apiManager.selectedCategory) { _, _ in
            randomizedPopular = filteredScreensavers.shuffled()
        }
    }
    
    private var exploreHeroSection: some View {
        ZStack {
            Group {
                if let hero = apiManager.screensavers.first,
                   hero.thumbnailURL != "placeholder",
                   let nsImage = NSImage(named: hero.thumbnailURL) ?? NSImage(contentsOfFile: "/Users/harshrao/ClockSpace/scratch/all_previews/" + hero.thumbnailURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(colors: [CSTheme.civicEase.opacity(0.65), CSTheme.backgroundPrimary], startPoint: .top, endPoint: .bottom)
                }
            }
            .frame(height: 220)
            .clipped()
            
            LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
            
            VStack(spacing: 12) {
                Text("Explore")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                Text("Discover community screensavers curated for your setup.")
                    .font(CSTheme.Font.body)
                    .foregroundColor(.white.opacity(0.8))
                Button("Discord Coming Soon") {}
                    .buttonStyle(.borderedProminent)
                    .tint(CSTheme.accent)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipped()
        .contentShape(Rectangle())
    }
    
    private var latestWallpapersSection: some View {
        sectionBlock(
            title: "Latest Wallpapers",
            subtitle: "Browse the newest additions to our collection",
            items: apiManager.screensavers.filter { $0.isNew }.prefix(6).map { $0 }
        )
    }
    
    private var discoverCommunitySection: some View {
        sectionBlock(
            title: "Discover Community Wallpapers",
            subtitle: "Random wallpapers to discover",
            items: Array(filteredScreensavers.prefix(6))
        )
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(CSTheme.Font.sectionTitle)
                .foregroundColor(.white)
            Text("Browse wallpapers by category")
                .font(CSTheme.Font.caption)
                .foregroundColor(CSTheme.textTertiary)
            
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(Category.allCases.prefix(9), id: \.self) { category in
                    Button {
                        apiManager.selectedCategory = category
                        onCategoryTap?(category)
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            Group {
                                if let categoryImage = categoryPreviewImage(for: category) {
                                    Image(nsImage: categoryImage)
                                        .resizable()
                                } else {
                                    category.tintColor.opacity(0.2)
                                }
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 136)
                            .clipped()
                            LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .top)
                            Text(category.rawValue)
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.45)
                                .lineLimit(2)
                                .padding(12)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var mostPopularSection: some View {
        sectionBlock(
            title: "Most Popular Wallpapers",
            subtitle: "Trending wallpapers loved by the community",
            items: randomizedPopular
        )
        .padding(.bottom, 120)
    }
    
    private func sectionBlock(title: String, subtitle: String, items: [Screensaver]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text(title)
                    .font(CSTheme.Font.sectionTitle)
                    .foregroundColor(.white)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(CSTheme.textMuted)
            }
            Text(subtitle)
                .font(CSTheme.Font.caption)
                .foregroundColor(CSTheme.textTertiary)
            
            if items.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(items) { saver in
                        ScreensaverCard(screensaver: saver)
                            .frame(maxWidth: .infinity)
                            .frame(height: 186)
                    }
                }
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                filterPill(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: apiManager.selectedCategory == nil
                ) {
                    apiManager.selectedCategory = nil
                }

                ForEach(Category.allCases, id: \.self) { category in
                    filterPill(
                        title: category.rawValue,
                        icon: category.iconName,
                        color: category.tintColor,
                        isSelected: apiManager.selectedCategory == category
                    ) {
                        apiManager.selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
            }
        )
    }

    private func filterPill(
        title: String,
        icon: String,
        color: Color = .white,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(CSTheme.Animation.standard) {
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : color.opacity(0.8))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(color.opacity(0.2))
                            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(CSTheme.textTertiary)
            Text("No screensavers found in this category")
                .font(CSTheme.Font.body)
                .foregroundColor(CSTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }
    
    private func categoryPreviewImage(for category: Category) -> NSImage? {
        let baseName = category.imageName
        let exts = ["png", "jpg", "jpeg", "webp"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "Categories"),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        if let image = NSImage(named: baseName) {
            return image
        }
        return nil
    }
}
