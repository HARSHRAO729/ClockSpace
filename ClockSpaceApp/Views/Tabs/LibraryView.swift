//
//  LibraryView.swift
//  ClockSpace
//
//  The Library tab: the installed screensaver and the user's favourites.
//

import SwiftUI

struct LibraryView: View {

    @EnvironmentObject var apiManager: APIManager
    @ObservedObject private var manager = ScreensaverManager.shared
    @State private var confirmRemoveAll = false

    private var favourites: [Screensaver] {
        apiManager.alphabetical.filter { apiManager.isLiked($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            installedSection
            favouritesSection
        }
        .padding(.top, 8)
        .padding(.bottom, 60)
        .confirmationDialog("Remove all favourites?", isPresented: $confirmRemoveAll) {
            Button("Remove All", role: .destructive) {
                withAnimation { apiManager.clearLikedItems() }
            }
        } message: {
            Text("Installed screensavers are not affected.")
        }
    }

    // MARK: - Installed

    private var installedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Installed", subtitle: "ClockSpace keeps one screensaver installed at a time")

            if let record = manager.installed {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(CSTheme.success)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Click Open Settings and choose it in the screen saver list")
                            .font(CSTheme.Font.caption)
                            .foregroundColor(CSTheme.textMuted)
                    }

                    Spacer()

                    if let saver = apiManager.screensavers.first(where: { $0.id == record.id }) {
                        Button("Details") {
                            withAnimation(CSTheme.Animation.standard) { apiManager.detailedScreensaver = saver }
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Open Settings") { manager.openScreenSaverSettings() }
                        .buttonStyle(.borderedProminent)
                        .tint(CSTheme.accent)
                    Button("Uninstall", role: .destructive) {
                        withAnimation { manager.uninstallCurrent() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
            } else {
                EmptyStateView(symbol: "display",
                               title: "Nothing installed",
                               message: "Open any screensaver and click Install.")
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.02)))
            }
        }
    }

    // MARK: - Favourites

    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                SectionHeader(
                    title: "Favourites",
                    subtitle: favourites.count == 1 ? "1 favourite screensaver" : "\(favourites.count) favourite screensavers")
                if !favourites.isEmpty {
                    Button("Remove All Favourites") { confirmRemoveAll = true }
                        .buttonStyle(.bordered)
                }
            }

            if favourites.isEmpty {
                EmptyStateView(symbol: "heart",
                               title: "No favourites yet",
                               message: "Click the heart on any screensaver to save it here.")
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.02)))
            } else {
                ScreensaverGrid(items: favourites)
            }
        }
    }
}
