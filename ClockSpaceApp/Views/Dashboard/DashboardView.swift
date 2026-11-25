//
//  DashboardView.swift
//  ClockSpace
//
//  Root view: tab content (Home / Explore / Library) under a fixed navbar,
//  with the search and detail overlays on top.
//

import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var apiManager: APIManager
    @StateObject private var alertProvider = AlertProvider.shared
    @StateObject private var manager = ScreensaverManager.shared

    @EnvironmentObject var navigation: NavigationModel
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if apiManager.isOffline {
                        offlineNote
                    }
                    mainTabContent
                }
                .padding(.horizontal, 24)
                .padding(.top, 84) // Clears the fixed navbar
                .padding(.bottom, 100)
            }
            .blur(radius: navigation.isSearchPresented ? 20 : 0)
            .accessibilityHidden(navigation.isSearchPresented || apiManager.detailedScreensaver != nil)
            .animation(CSTheme.Animation.standard, value: navigation.isSearchPresented)

            if let message = manager.successMessage {
                VStack {
                    Spacer()
                    successToast(message: message)
                        .padding(.bottom, 110)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(500)
            }

            AppNavbarView(
                selectedTab: $navigation.selectedTab,
                isSearchPresented: $navigation.isSearchPresented
            )
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            )
            .opacity(navigation.isSearchPresented || apiManager.detailedScreensaver != nil ? 0 : 1)
            .allowsHitTesting(!navigation.isSearchPresented && apiManager.detailedScreensaver == nil)
            .zIndex(100)

            if navigation.isSearchPresented {
                searchOverlay
                    .transition(.opacity)
                    .zIndex(200)
            }

            if let saver = apiManager.detailedScreensaver {
                ScreensaverDetailView(screensaver: saver)
                    .transition(.opacity)
                    .ignoresSafeArea()
                    .zIndex(300)
            }
        }
        .alert(item: $alertProvider.currentAlert) { alert in
            if let secondary = alert.secondaryButton {
                return Alert(title: Text(alert.title), message: Text(alert.message), primaryButton: alert.primaryButton, secondaryButton: secondary)
            } else {
                return Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: alert.primaryButton)
            }
        }
    }

    // MARK: - Tabs

    @ViewBuilder
    private var mainTabContent: some View {
        switch navigation.selectedTab {
        case .home:
            homeContent
        case .explore:
            if let category = navigation.categoryPage {
                CategoryScreensView(category: category, onBack: { navigation.categoryPage = nil })
            } else {
                ExploreView(onCategoryTap: { navigation.categoryPage = $0 })
            }
        case .library:
            LibraryView()
        }
    }

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 36) {
            HeroView(items: apiManager.featured)

            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Recently Added", subtitle: "The newest screensavers in the catalog")
                ScreensaverGrid(items: Array(apiManager.newestFirst.prefix(6)))
            }

            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Categories", subtitle: "Browse screensavers by category")
                CategoryGrid { navigation.openCategory($0) }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Search

    private var searchResults: [Screensaver] {
        apiManager.search(searchText)
    }

    private func closeSearch() {
        withAnimation(CSTheme.Animation.standard) {
            navigation.isSearchPresented = false
            searchText = ""
        }
    }

    private var searchOverlay: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { closeSearch() }

            VStack(spacing: 24) {
                HStack(spacing: CSTheme.Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(CSTheme.textMuted)

                    TextField("Search by name, author, tag or category", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .focused($searchFocused)
                        .onKeyPress(.escape) {
                            closeSearch()
                            return .handled
                        }

                    Button("Done") { closeSearch() }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(CSTheme.textMuted)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                )
                .frame(maxWidth: 760)

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        if searchResults.isEmpty {
                            EmptyStateView(symbol: "magnifyingglass",
                                           title: "No screensavers match “\(searchText)”",
                                           message: "Try a different name, author or category.")
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(searchResults.count == 1 ? "1 result" : "\(searchResults.count) results")
                                    .font(CSTheme.Font.caption)
                                    .foregroundColor(CSTheme.textMuted)
                                ScreensaverGrid(items: searchResults)
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 60)
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            CSTheme.backgroundPrimary
            RadialGradient(colors: [CSTheme.civicEase.opacity(0.08), .clear],
                           center: .top, startRadius: 100, endRadius: 700)
            RadialGradient(colors: [CSTheme.accent.opacity(0.04), .clear],
                           center: .init(x: 0.2, y: 0.6), startRadius: 60, endRadius: 400)
            RadialGradient(colors: [CSTheme.violet.opacity(0.03), .clear],
                           center: .bottomTrailing, startRadius: 50, endRadius: 350)
        }
    }

    // MARK: - Notes and toasts

    private var offlineNote: some View {
        Label("Offline — showing the saved catalog", systemImage: "wifi.slash")
            .font(CSTheme.Font.caption)
            .foregroundColor(CSTheme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func successToast(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(CSTheme.success)
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Button("Open Settings") {
                manager.openScreenSaverSettings()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.15)))
            .foregroundColor(.white)
            .font(.system(size: 11, weight: .bold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}
