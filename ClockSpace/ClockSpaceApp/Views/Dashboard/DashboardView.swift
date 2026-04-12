//
//  DashboardView.swift
//  ClockSpace
//
//  Root view: Full-screen immersive ZStack with floating top navigation,
//  tab-based routing (Home / Explore / Library), and sheet presentation
//  for Settings and Add flows.
//

import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject var apiManager: APIManager
    
    // MARK: - Navigation State
    
    @State private var selectedTab: NavTab = .home
    @State private var selectedCategory: Category? = nil
    @State private var searchText: String = ""
    
    // MARK: - Sheet / Overlay State
    
    @State private var isSearchPresented: Bool = false
    @State private var showSettings: Bool = false
    @State private var showAdd: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // ── Deep dark background ──
            backgroundLayer
                .ignoresSafeArea()
            
            // ── Routed content based on selectedTab ──
            Group {
                switch selectedTab {
                case .home:
                    homeContent
                case .explore:
                    exploreContent
                case .library:
                    libraryContent
                }
            }
            .blur(radius: isSearchPresented ? 20 : 0)
            .scaleEffect(isSearchPresented ? 0.98 : 1.0)
            .animation(CSTheme.Animation.standard, value: isSearchPresented)
            
            // ── Floating top nav bar (always visible) ──
            TopNavBar(
                selectedTab: $selectedTab,
                isSearchPresented: $isSearchPresented,
                showSettings: $showSettings,
                showAdd: $showAdd
            )
            .opacity(isSearchPresented ? 0 : 1)
            
            // ── Immersive Search Overlay ──
            if isSearchPresented {
                searchOverlay
                    .transition(.opacity)
            }
        }
        // ── Sheet Presentations ──
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAdd) {
            AddScreensaverView()
        }
        // ── Initial Data Load ──
        .task {
            await loadAllScreensavers()
        }
        .onChange(of: selectedCategory) {
            Task { await loadScreensavers() }
        }
    }
    
    // MARK: - Home Tab Content
    
    private var homeContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Spacer for floating navbar height
                Color.clear.frame(height: 70)
                
                // ── Hero section with fading gradient ──
                HeroView(featuredScreensavers: featuredItems)
                
                VStack(spacing: CSTheme.Spacing.xxl) {
                    // ── Latest Collection (Horizontal) ──
                    sectionHeader(title: "Latest Collection", subtitle: "Most recent community screensavers")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: CSTheme.Spacing.lg) {
                            ForEach(apiManager.screensavers.filter { $0.isNew }) { saver in
                                ScreensaverCard(screensaver: saver)
                                    .frame(width: 280)
                            }
                        }
                    }
                    
                    // ── Most Popular (Horizontal) ──
                    sectionHeader(title: "Most Popular", subtitle: "Trending screensavers loved by the community")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: CSTheme.Spacing.lg) {
                            ForEach(apiManager.screensavers.filter { $0.rank != nil }.sorted(by: { ($0.rank ?? 99) < ($1.rank ?? 99) })) { saver in
                                ScreensaverCard(screensaver: saver)
                                    .frame(width: 280)
                            }
                        }
                    }
                    
                    // ── Categories (Grid) ──
                    sectionHeader(title: "Categories", subtitle: "Browse screensavers by category")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                        ForEach(Category.allCases, id: \.self) { category in
                            categoryCard(for: category)
                        }
                    }
                }
                .padding(.horizontal, CSTheme.Spacing.xxl)
                .padding(.top, CSTheme.Spacing.xl)
                .padding(.bottom, CSTheme.Spacing.xxxl)
            }
        }
    }
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
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
            
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(CSTheme.textMuted)
        }
    }
    
    private func categoryCard(for category: Category) -> some View {
        ZStack {
            // Background image placeholder with category specific color
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .fill(category.tintColor.opacity(0.15))
                .frame(height: 140)
            
            // Text overlay
            Text(category.rawValue)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .onTapGesture {
            selectedCategory = category
            selectedTab = .explore
        }
    }
    
    // MARK: - Explore Tab Content
    
    private var exploreContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 70)
                ExploreView()
                    .frame(minHeight: 500)
            }
        }
    }
    
    // MARK: - Library Tab Content
    
    private var libraryContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 70)
                LibraryView()
                    .frame(minHeight: 500)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            CSTheme.backgroundPrimary
            
            // Subtle indigo glow top
            RadialGradient(
                colors: [
                    CSTheme.civicEase.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 700
            )
            
            // Subtle accent glow mid-left
            RadialGradient(
                colors: [
                    CSTheme.accent.opacity(0.04),
                    Color.clear
                ],
                center: .init(x: 0.2, y: 0.6),
                startRadius: 60,
                endRadius: 400
            )
            
            // Violet hint bottom-right
            RadialGradient(
                colors: [
                    CSTheme.violet.opacity(0.03),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 50,
                endRadius: 350
            )
        }
    }
    
    // MARK: - Data
    
    private var featuredItems: [Screensaver] {
        apiManager.screensavers
    }
    
    private var filteredScreensavers: [Screensaver] {
        var results = apiManager.screensavers
        
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            let lowered = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(lowered) ||
                $0.author.lowercased().contains(lowered) ||
                $0.tags.contains(where: { $0.lowercased().contains(lowered) })
            }
        }
        
        return results
    }
    
    // MARK: - Grid Components
    
    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 320), spacing: CSTheme.Spacing.lg)
    ]
    
    private var screensaverGrid: some View {
        LazyVGrid(columns: columns, spacing: CSTheme.Spacing.lg) {
            ForEach(filteredScreensavers) { saver in
                ScreensaverCard(screensaver: saver)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(CSTheme.Animation.standard, value: filteredScreensavers)
    }
    
    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: CSTheme.Spacing.lg) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                    .fill(CSTheme.surfaceElevated.opacity(0.3))
                    .frame(height: 260)
                    .shimmer()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: CSTheme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(CSTheme.textTertiary)
            
            Text("No screensavers found")
                .font(CSTheme.Font.headline)
                .foregroundColor(CSTheme.textMuted)
            
            Text("Try adjusting your search or browse a different category.")
                .font(CSTheme.Font.body)
                .foregroundColor(CSTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CSTheme.Spacing.xxxl)
    }
    
    // MARK: - Data Loading
    
    private func loadAllScreensavers() async {
        do {
            _ = try await apiManager.fetchScreensavers(category: nil)
        } catch {
            apiManager.errorMessage = error.localizedDescription
        }
    }
    
    private func loadScreensavers() async {
        do {
            _ = try await apiManager.fetchScreensavers(category: selectedCategory)
        } catch {
            apiManager.errorMessage = error.localizedDescription
        }
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else {
            await loadScreensavers()
            return
        }
        _ = try? await apiManager.searchScreensavers(query: searchText)
    }
    
    // MARK: - Search Overlay Detail
    
    private var searchOverlay: some View {
        ZStack {
            // Background Dim & Dismiss Gesture
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(CSTheme.Animation.standard) {
                        isSearchPresented = false
                        searchText = ""
                    }
                }
            
            VStack(spacing: CSTheme.Spacing.xxl) {
                // Search Pill
                HStack(spacing: CSTheme.Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(CSTheme.textMuted)
                    
                    TextField("Search Screensavers", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(CSTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                )
                .padding(.horizontal, 100)
                .offset(y: -40) // Position near top-center
                
                // Result Hints or Recent Searches could go here
                if !searchText.isEmpty {
                    Text("Press Return to search community...")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                        .transition(.opacity)
                }
            }
        }
    }
}
