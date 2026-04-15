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
    @State private var activeCategoryPage: Category? = nil
    
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
                        .padding(.top, 84) // Enforced spacing to clear the fixed navbar
                        .padding(.bottom, 100)
                }
            }
            .blur(radius: isSearchPresented ? 20 : 0)
            .scaleEffect(isSearchPresented ? 0.98 : 1.0)
            .animation(CSTheme.Animation.standard, value: isSearchPresented)
            
            // ── Fixed Navigation Bar (Strict Containment) ──
            AppNavbarView(
                selectedTab: $selectedTab,
                isSearchPresented: $isSearchPresented,
                showSettings: $showSettings,
                showAdd: $showAdd
            )
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            )
            .opacity(isSearchPresented || apiManager.detailedScreensaver != nil ? 0 : 1)
            .allowsHitTesting(!isSearchPresented && apiManager.detailedScreensaver == nil)
            .zIndex(100) // Ensure it stays above content
            
            if isSearchPresented {
                searchOverlay
                    .transition(.opacity)
                    .zIndex(200)
            }
            
            // ── Detailed Screensaver Overlay ──
            if let saver = apiManager.detailedScreensaver {
                ScreensaverDetailView(screensaver: saver)
                    .transition(.opacity)
                    .ignoresSafeArea()
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
            if let category = activeCategoryPage {
                CategoryScreensView(
                    category: category,
                    onBack: {
                        activeCategoryPage = nil
                        apiManager.selectedCategory = nil
                    }
                )
            } else {
                ExploreView(
                    onCategoryTap: { category in
                        activeCategoryPage = category
                    }
                )
            }
        case .library:
            LibraryView()
        }
    }
    
    // MARK: - Home Tab Content
    
    private var homeContent: some View {
        VStack(spacing: 28) {
            // ── Hero section with fading gradient ──
            HeroView(featuredScreensavers: featuredItems)
                .frame(height: 400)
                .frame(maxWidth: .infinity)
                .mask(
                    LinearGradient(
                        colors: [.white, .white, .white, .white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipped()
                .contentShape(Rectangle())
                .padding(.bottom, 8)
            
            VStack(spacing: 22) {
                sectionHeader(title: "Latest Wallpapers", subtitle: "Browse the newest additions to our collection")
                
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(apiManager.screensavers.filter { $0.isNew }.prefix(6)) { saver in
                            ScreensaverCard(screensaver: saver)
                            .frame(maxWidth: .infinity)
                            .frame(height: 186)
                        }
                    }
                .clipped()
                .contentShape(Rectangle())
                    
                sectionHeader(title: "Discover Community Wallpapers", subtitle: "Random wallpapers to discover")
                
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(apiManager.screensavers.dropFirst(6).prefix(6)) { saver in
                        ScreensaverCard(screensaver: saver)
                            .frame(maxWidth: .infinity)
                            .frame(height: 186)
                    }
                }
                    
                sectionHeader(title: "Categories", subtitle: "Browse screensavers by category")
                    
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(Category.allCases.prefix(9), id: \.self) { category in
                        categoryCard(for: category)
                    }
                    }
                    .clipped()
                    .contentShape(Rectangle())
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
            activeCategoryPage = category
        }) {
            ZStack(alignment: .bottomLeading) {
                // Background Image
                Group {
                    if let nsImage = categoryImage(for: category) {
                        Image(nsImage: nsImage)
                            .resizable()
                    } else {
                        category.tintColor.opacity(0.15)
                    }
                }
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .frame(minWidth: 0, maxWidth: .infinity)
                .clipped()
                .contentShape(Rectangle())
                
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
    
    private func categoryImage(for category: Category) -> NSImage? {
        let baseName = category.imageName
        let exts = ["png", "jpg", "jpeg", "webp"]
        for ext in exts {
            if let bundleURL = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "Categories"),
               let nsImage = NSImage(contentsOf: bundleURL) {
                return nsImage
            }
        }
        return NSImage(named: baseName)
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
