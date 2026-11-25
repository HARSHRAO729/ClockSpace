//
//  Sections.swift
//  ClockSpace
//
//  Shared section header and screensaver grid used by every tab.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(CSTheme.Font.sectionTitle)
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(CSTheme.Font.caption)
                    .foregroundColor(CSTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Adaptive grid of screensaver cards: more columns as the window widens.
struct ScreensaverGrid: View {
    let items: [Screensaver]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 14)], spacing: 14) {
            ForEach(items) { saver in
                ScreensaverCard(screensaver: saver)
            }
        }
    }
}

/// Shown when a list has nothing to display.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(CSTheme.textTertiary)
            Text(title)
                .font(CSTheme.Font.headline)
                .foregroundColor(CSTheme.textMuted)
            if let message {
                Text(message)
                    .font(CSTheme.Font.body)
                    .foregroundColor(CSTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
