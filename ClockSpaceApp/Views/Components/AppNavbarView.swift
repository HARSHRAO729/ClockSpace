//
//  AppNavbarView.swift
//  ClockSpace
//

import SwiftUI

struct AppNavbarView: View {
    @Binding var selectedTab: NavTab
    @Binding var isSearchPresented: Bool

    @Environment(\.openSettings) private var openSettings
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            // ── Left: Logo & name ──
            HStack(spacing: 12) {
                AppLogoView()

                Text("ClockSpace")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 200, alignment: .leading)

            Spacer()

            // ── Center: Tabs ──
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
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            )

            Spacer()

            // ── Right: Global Actions ──
            HStack(spacing: 12) {
                navButton(icon: "magnifyingglass", label: "Search") {
                    withAnimation(CSTheme.Animation.standard) {
                        isSearchPresented.toggle()
                    }
                }

                navButton(icon: "gearshape", label: "Settings") {
                    openSettings()
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

    private func navButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}
