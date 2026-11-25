//
//  ExploreView.swift
//  ClockSpace
//
//  Every category, then every screensaver A to Z.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var apiManager: APIManager
    let onCategoryTap: (Category) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explore")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(apiManager.screensavers.count) free screensavers that run on modern Macs.")
                    .font(CSTheme.Font.body)
                    .foregroundColor(CSTheme.textMuted)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Categories")
                CategoryGrid(onSelect: onCategoryTap)
            }

            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "All Screensavers", subtitle: "A to Z")
                if apiManager.screensavers.isEmpty {
                    EmptyStateView(symbol: "sparkles", title: "No screensavers yet")
                } else {
                    ScreensaverGrid(items: apiManager.alphabetical)
                }
            }
        }
    }
}
