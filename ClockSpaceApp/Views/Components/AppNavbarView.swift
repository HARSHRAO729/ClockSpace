//
//  AppNavbarView.swift
//  ClockSpace
//

import SwiftUI

struct AppNavbarView: View {
    @Binding var selectedTab: NavTab
    @Binding var isSearchPresented: Bool
    @Binding var showSettings: Bool
    @Binding var showAdd: Bool
    
    var backAction: (() -> Void)? = nil
    
    @EnvironmentObject var apiManager: APIManager
    @Namespace private var namespace
    @State private var hoveredTab: NavTab? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            // ── Left: Profile & Context ──
            HStack(spacing: 12) {
                UserProfileView()
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Antigravity")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Online")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CSTheme.textTertiary)
                    }
                }
            }
            .frame(width: 200, alignment: .leading)
            
            Spacer()
            
            // ── Center: Perspectives or Title ──
            ZStack {
                if let backAction = backAction {
                    // Detail Mode Title
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(CSTheme.accent)
                        
                        Text(apiManager.detailedScreensaver?.name ?? "Preview")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    )
                } else {
                    // Main Tabs
                    HStack(spacing: 4) {
                        ForEach(NavTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(CSTheme.Animation.standard) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? .white : CSTheme.textMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        ZStack {
                                            if selectedTab == tab {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.12))
                                                    .matchedGeometryEffect(id: "tab", in: namespace)
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    )
                }
            }
            
            Spacer()
            
            // ── Right: Global Actions ──
            HStack(spacing: 12) {
                if let backAction = backAction {
                    // Close Button
                    Button(action: backAction) {
                        HStack(spacing: 6) {
                            Text("Close")
                            Image(systemName: "xmark")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // Search
                    navButton(icon: "magnifyingglass") {
                        withAnimation(CSTheme.Animation.standard) {
                            isSearchPresented.toggle()
                        }
                    }
                    
                    // Settings
                    navButton(icon: "slider.horizontal.3") {
                        showSettings = true
                    }
                    
                    // Add
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Circle().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 200, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial)
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(colors: [.black, .black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                        Spacer()
                    }
                )
        )
    }
    
    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
