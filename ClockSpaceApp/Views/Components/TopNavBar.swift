//
//  TopNavBar.swift
//  ClockSpace
//
//  Floating translucent top navigation bar with CivicEase branding,
//  pill-shaped nav items, and circular action buttons.
//  Fully wired to state bindings for routing and sheet presentation.
//

import SwiftUI

/// The navigation tabs available in the top bar.
enum NavTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case explore = "Explore"
    case library = "Library"
    
    var id: String { rawValue }
    
    /// SF Symbol for each tab (used in placeholder views)
    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .explore: return "safari.fill"
        case .library: return "square.grid.2x2.fill"
        }
    }
}

struct TopNavBar: View {
    
    @Binding var selectedTab: NavTab
    @Binding var isSearchPresented: Bool
    @Binding var showSettings: Bool
    @Binding var showAdd: Bool
    @State private var hoveredTab: NavTab?
    @State private var hoveredAction: String?
    
    var body: some View {
        HStack(spacing: 0) {
            // ── Left: Brand Identity ──
            brandSection
            
            Spacer()
            
            // ── Center: Pill Navigation ──
            pillNavigation
            
            Spacer()
            
            // ── Right: Action Buttons ──
            actionButtons
        }
        .padding(.horizontal, CSTheme.Spacing.xl)
        .padding(.vertical, CSTheme.Spacing.md)
        .background(
            ZStack {
                // Native macOS translucent material
                RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle tint overlay
                RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                    .fill(CSTheme.backgroundPrimary.opacity(0.3))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.4), radius: 30, y: 10)
        .padding(.horizontal, CSTheme.Spacing.xl)
        .padding(.top, CSTheme.Spacing.md)
    }
    
    // MARK: - Brand Section
    
    private var brandSection: some View {
        HStack(spacing: CSTheme.Spacing.sm) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [CSTheme.accent, CSTheme.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("ClockSpace")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CSTheme.textPrimary)
                
                // CivicEase subtle branding — small caps
                Text("BY CIVICEASE")
                    .font(CSTheme.Font.micro)
                    .foregroundColor(CSTheme.civicEase.opacity(0.7))
                    .tracking(1.5)
            }
        }
    }
    
    // MARK: - Pill Navigation
    
    private var pillNavigation: some View {
        HStack(spacing: CSTheme.Spacing.xxs) {
            ForEach(NavTab.allCases) { tab in
                Button(action: {
                    withAnimation(CSTheme.Animation.standard) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : CSTheme.textMuted)
                        .padding(.horizontal, CSTheme.Spacing.lg)
                        .padding(.vertical, CSTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab
                                      ? Color.white.opacity(0.12)
                                      : (hoveredTab == tab ? Color.white.opacity(0.06) : Color.clear)
                                )
                        )
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(CSTheme.Animation.fast) {
                        hoveredTab = hovering ? tab : nil
                    }
                }
            }
        }
        .padding(CSTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: CSTheme.Spacing.sm) {
            // Search — toggles search bar, highlights when active
            navActionButton(
                icon: "magnifyingglass",
                id: "search",
                isActive: isSearchPresented
            ) {
                withAnimation(CSTheme.Animation.standard) {
                    isSearchPresented.toggle()
                }
            }
            
            // Add — presents add/import sheet
            navActionButton(
                icon: "plus",
                id: "add",
                isActive: showAdd
            ) {
                showAdd = true
            }
            
            // Settings — presents settings sheet
            navActionButton(
                icon: "gearshape",
                id: "settings",
                isActive: showSettings
            ) {
                showSettings = true
            }
        }
    }
    
    /// A circular translucent action button. Highlights with accent glow when `isActive`.
    private func navActionButton(
        icon: String,
        id: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(
                    isActive ? CSTheme.accent :
                    (hoveredAction == id ? .white : CSTheme.textMuted)
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            isActive ? CSTheme.accent.opacity(0.15) :
                            (hoveredAction == id ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            isActive ? CSTheme.accent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(CSTheme.Animation.fast) {
                hoveredAction = hovering ? id : nil
            }
        }
    }
}
