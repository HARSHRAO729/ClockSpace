//
//  FloatingNavbarView.swift
//  ClockSpace
//
//  Premium persistent top navigation bar. 
//  Features a fixed 50pt height, glassmorphic backdrop, and centered pill navigation.
//

import SwiftUI

struct FloatingNavbarView: View {
    
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
                .frame(width: 200, alignment: .leading)
            
            Spacer()
            
            // ── Center: Pill Navigation ──
            pillNavigation
            
            Spacer()
            
            // ── Right: Action Buttons ──
            actionButtons
                .frame(width: 200, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Glassmorphism effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                
                // Content subtle gradient tint
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        )
        .zIndex(100)
    }
    
    // MARK: - Brand Section
    
    private var brandSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [CSTheme.accent, CSTheme.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("ClockSpace")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Pill Navigation
    
    private var pillNavigation: some View {
        HStack(spacing: 4) {
            ForEach(NavTab.allCases) { tab in
                Button(action: {
                    withAnimation(CSTheme.Animation.standard) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.white.opacity(0.15) : (hoveredTab == tab ? Color.white.opacity(0.08) : Color.clear))
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(CSTheme.Animation.fast) {
                        hoveredTab = hovering ? tab : nil
                    }
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.05)))
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            navActionButton(icon: "magnifyingglass", id: "search", isActive: isSearchPresented) {
                withAnimation(CSTheme.Animation.standard) {
                    isSearchPresented.toggle()
                }
            }
            
            navActionButton(icon: "plus", id: "add", isActive: showAdd) {
                showAdd = true
            }
            
            navActionButton(icon: "gearshape", id: "settings", isActive: showSettings) {
                showSettings = true
            }
        }
    }
    
    private func navActionButton(
        icon: String,
        id: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? CSTheme.accent : (hoveredAction == id ? .white : .white.opacity(0.6)))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isActive ? CSTheme.accent.opacity(0.15) : (hoveredAction == id ? Color.white.opacity(0.12) : Color.clear))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(CSTheme.Animation.fast) {
                hoveredAction = hovering ? id : nil
            }
        }
    }
}
