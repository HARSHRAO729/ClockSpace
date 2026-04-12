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
        ScrollView(.vertical, showsIndicators: false) {
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
                        Button("Clear all") { }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                            .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: CSTheme.Spacing.lg) {
                        // Create Playlist Card
                        createPlaylistCard
                        
                        // Existing Playlist Mock
                        playlistCard(title: "Nature", color: Color.green.opacity(0.2))
                        
                        Spacer()
                    }
                }
                
                // ── Saved Wallpapers Section ──
                VStack(alignment: .leading, spacing: CSTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saved Wallpapers")
                            .font(CSTheme.Font.sectionTitle)
                            .foregroundColor(.white)
                        Text("Your collection of \(apiManager.screensavers.count) saved screensavers")
                            .font(CSTheme.Font.caption)
                            .foregroundColor(CSTheme.textTertiary)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: CSTheme.Spacing.lg) {
                        ForEach(apiManager.screensavers.prefix(5)) { saver in
                            ScreensaverCard(screensaver: saver)
                        }
                    }
                }
            }
            .padding(.horizontal, CSTheme.Spacing.xxl)
            .padding(.top, CSTheme.Spacing.xl)
            .padding(.bottom, CSTheme.Spacing.xxxl)
        }
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
