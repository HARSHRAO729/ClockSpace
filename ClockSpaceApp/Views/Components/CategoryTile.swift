//
//  CategoryTile.swift
//  ClockSpace
//
//  A category button: tint colour, symbol, name and how many screensavers it holds.
//

import SwiftUI

struct CategoryTile: View {
    let category: Category
    let count: Int
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: category.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(category.tintColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(category.tintColor.opacity(0.15)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(count == 1 ? "1 screensaver" : "\(count) screensavers")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CSTheme.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [category.tintColor.opacity(isHovering ? 0.22 : 0.14), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(isHovering ? 0.18 : 0.08), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(CSTheme.Animation.fast, value: isHovering)
        .accessibilityLabel("\(category.displayName), \(count) screensavers")
    }
}

/// Grid of every category that has at least one screensaver.
struct CategoryGrid: View {
    @EnvironmentObject var apiManager: APIManager
    let onSelect: (Category) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
            ForEach(apiManager.categoriesInUse, id: \.category) { entry in
                CategoryTile(category: entry.category, count: entry.count) {
                    onSelect(entry.category)
                }
            }
        }
    }
}
