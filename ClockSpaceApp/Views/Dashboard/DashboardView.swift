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
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    mainTabContent
                        .padding(.horizontal, 24)
                        .padding(.top, 20) // Spacing below navbar
                        .padding(.bottom, 40)
                }
            }
            .blur(radius: isSearchPresented ? 20 : 0)
            .scaleEffect(isSearchPresented ? 0.98 : 1.0)
            .animation(CSTheme.Animation.standard, value: isSearchPresented)
            .safeAreaInset(edge: .top) {
                FloatingNavbarView(
                    selectedTab: $selectedTab,
                    isSearchPresented: $isSearchPresented,
                    showSettings: $showSettings,
                    showAdd: $showAdd
                )
                .opacity(isSearchPresented ? 0 : 1)
            }
            
            if isSearchPresented {
                searchOverlay
                    .transition(.opacity)
                    .zIndex(200)
            }
            
            // ── Detailed Screensaver Overlay ──
            if let saver = apiManager.detailedScreensaver {
                ScreensaverDetailView(screensaver: saver)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(300)
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
        .onChange(of: apiManager.selectedCategory) {
            Task { await loadScreensavers() }
        }
    }
    
    @ViewBuilder
    private var mainTabContent: some View {
        switch selectedTab {
        case .home:
            homeContent
        case .explore:
            ExploreView()
        case .library:
            LibraryView()
        }
    }
    
    // MARK: - Home Tab Content
    
    private var homeContent: some View {
        VStack(spacing: 0) {
            // ── Hero section with fading gradient ──
            HeroView(featuredScreensavers: featuredItems)
                .frame(height: 480)
                .mask(
                    LinearGradient(
                        colors: [.white, .white, .white, .white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipped()
                .padding(.bottom, 40)
            
            VStack(spacing: CSTheme.Spacing.xxl) {
                // ── Latest Collection (Horizontal) ──
                sectionHeader(title: "Latest Collection", subtitle: "Most recent community screensavers")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(apiManager.screensavers.filter { $0.isNew }) { saver in
                            ScreensaverCard(screensaver: saver)
                                .frame(width: 280)
                        }
                    }
                }
                    
                    // ── Most Popular (Horizontal) ──
                    // Removed "Most Popular" section as per user request to remove rankings/ratings
                    
                    // ── Categories (Grid) ──
                    sectionHeader(title: "Categories", subtitle: "Browse screensavers by category")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                        ForEach(Category.allCases.prefix(9), id: \.self) { category in
                            categoryCard(for: category)
                        }
                    }
                }
            }
            .padding(.top, CSTheme.Spacing.xl)
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
        Button(action: {
            apiManager.selectedCategory = category
            selectedTab = .explore
        }) {
            ZStack(alignment: .bottomLeading) {
                // Background Image
                // In a real app, these would be in Assets.xcassets. 
                // For this environment, we use the generated images.
                Image(category.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .clipped()
                
                // Overlay Gradient for readability
                LinearGradient(
                    colors: [
                        .black.opacity(0.8),
                        .black.opacity(0.4),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 100)
                
                // Category Title
                Text(category.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(CSTheme.Spacing.lg)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.opacity)
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
        
        if let category = apiManager.selectedCategory {
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
            _ = try await apiManager.fetchScreensavers(category: apiManager.selectedCategory)
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
