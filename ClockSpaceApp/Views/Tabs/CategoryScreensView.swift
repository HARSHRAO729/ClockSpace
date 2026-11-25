//
//  CategoryScreensView.swift
//  ClockSpace
//
//  All screensavers in one category.
//

import SwiftUI

struct CategoryScreensView: View {
    let category: Category
    let onBack: () -> Void

    @EnvironmentObject var apiManager: APIManager

    private var items: [Screensaver] {
        apiManager.screensavers(in: category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Explore")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("[", modifiers: .command)

                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(category.tintColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(CSTheme.Font.sectionTitle)
                        .foregroundColor(.white)
                    Text("\(category.subtitle) · \(items.count == 1 ? "1 screensaver" : "\(items.count) screensavers")")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.top, 8)

            if items.isEmpty {
                EmptyStateView(symbol: "sparkles", title: "No screensavers in this category")
            } else {
                ScreensaverGrid(items: items)
            }
        }
    }
}
