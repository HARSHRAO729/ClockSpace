//
//  LibraryView.swift
//  ClockSpace
//
//  Placeholder for the Library tab — user's installed and saved screensavers.
//

import SwiftUI

struct LibraryView: View {
    
    @EnvironmentObject var apiManager: APIManager
    @State private var hoveredPlaylist: Int?
    
    var body: some View {
        VStack(spacing: CSTheme.Spacing.xxl) {
            // ── Wallpaper Playlists Section ──
            VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wallpaper Playlists")
                            .font(CSTheme.Font.sectionTitle)
                            .foregroundColor(.white)
                        Text("Create playlists and auto-rotate your favorite screensavers")
                            .font(CSTheme.Font.caption)
                            .foregroundColor(CSTheme.textTertiary)
                    }
                    Spacer()
                    Button("Clear all") {
                        withAnimation {
                            apiManager.clearLikedItems()
                            ScreensaverManager.shared.clearAllInstalled()
                        }
                    }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                        .buttonStyle(.plain)
                }
                
                HStack(spacing: CSTheme.Spacing.lg) {
                    // Create Playlist Card
                    createPlaylistCard
                    
                    // Existing Playlist Mock
                    ForEach(apiManager.playlists, id: \.self) { playlist in
                        playlistCard(title: playlist, color: Color.red.opacity(0.2))
                    }
                    
                    if apiManager.playlists.isEmpty {
                        Text("No playlists created.")
                            .font(CSTheme.Font.caption)
                            .foregroundColor(CSTheme.textTertiary)
                    }
                    
                    Spacer()
                }
            }
            
            // ── Saved Wallpapers Section ──
            let likedScreensavers = apiManager.screensavers.filter { apiManager.isLiked($0) }
            
            VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Wallpapers")
                        .font(CSTheme.Font.sectionTitle)
                        .foregroundColor(.white)
                    Text("Your collection of \(likedScreensavers.count) favorited screensavers")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                }
                
                if likedScreensavers.isEmpty {
                    emptySavedState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                        ForEach(likedScreensavers) { saver in
                            ScreensaverCard(screensaver: saver)
                        }
                    }
                }
            }
        }
        }
        .padding(.top, CSTheme.Spacing.xl)
        .padding(.bottom, 60)
    }
    
    private var emptySavedState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(CSTheme.textTertiary)
            Text("No saved wallpapers yet")
                .font(CSTheme.Font.headline)
                .foregroundColor(CSTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.02)))
    }
    
    private var createPlaylistCard: some View {
        VStack {
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .foregroundColor(Color.white.opacity(0.2))
                .frame(width: 200, height: 130)
                .overlay(
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Create Playlist")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                )
        }
    }
    
    private func playlistCard(title: String, color: Color) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .fill(color)
                .frame(width: 200, height: 130)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(CSTheme.Spacing.md)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
