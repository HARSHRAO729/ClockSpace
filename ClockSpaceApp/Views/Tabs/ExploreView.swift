//
//  ExploreView.swift
//  ClockSpace
//

import SwiftUI

struct ExploreView: View {
    
    @EnvironmentObject var apiManager: APIManager
    @State private var selectedFilter: String? = "4K"
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // ── Latest Collection (Top) ──
                    VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Latest Collection")
                                    .font(CSTheme.Font.sectionTitle)
                                    .foregroundColor(.white)
                                Text("The newest community additions, refreshed daily")
                                    .font(CSTheme.Font.caption)
                                    .foregroundColor(CSTheme.textTertiary)
                            }
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(apiManager.screensavers.filter { $0.isNew }.prefix(8)) { saver in
                                    ScreensaverCard(screensaver: saver)
                                        .frame(width: 280)
                                }
                            }
                        }
                    }
                    .padding(.top, CSTheme.Spacing.xl)
                    .id("latest-collection")
                    
                    // ── Category Filter Bar ──
                    VStack(alignment: .leading, spacing: CSTheme.Spacing.md) {
                        categoryFilterBar
                    }
                    .padding(.top, 40)
                    .id("category-filter")
                    
                    // ── Filtered Grid ──
                    VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                        let filtered = apiManager.screensavers.filter { saver in
                            if let selected = apiManager.selectedCategory {
                                return saver.category == selected
                            }
                            return true
                        }
                        
                        if filtered.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 20),
                                    GridItem(.flexible(), spacing: 20),
                                    GridItem(.flexible(), spacing: 20),
                                    GridItem(.flexible(), spacing: 20)
                                ],
                                spacing: 24
                            ) {
                                ForEach(filtered) { saver in
                                    ScreensaverCard(screensaver: saver)
                                }
                            }
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .onChange(of: apiManager.selectedCategory) { category in
                    if category != nil {
                        withAnimation(CSTheme.Animation.standard) {
                            proxy.scrollTo("category-filter", anchor: .top)
                        }
                    }
                }
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
    
    // MARK: - Category Filter Bar (High-End)
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // All Category
                filterPill(title: "All", icon: "square.grid.2x2", isSelected: apiManager.selectedCategory == nil) {
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
    }
    
    private func filterPill(title: String, icon: String, color: Color = .white, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
}
