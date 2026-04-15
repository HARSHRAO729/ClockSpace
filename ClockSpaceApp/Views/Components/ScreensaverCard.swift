//
//  ScreensaverCard.swift
//  ClockSpace
//
//  Elite screensaver card: 16pt radius, vibrant overlapping badge,
//  stark white title, muted gray metadata. Install button wired to
//  ScreensaverManager with Installing → Installed state transitions.
//

import SwiftUI
import AVKit

struct ScreensaverCard: View {
       let screensaver: Screensaver
    @EnvironmentObject var apiManager: APIManager
    @StateObject private var manager = ScreensaverManager.shared
    @State private var isHovering: Bool = false
    
    var body: some View {
        ZStack {
            thumbnailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 280)
        .frame(height: 186)
        .background(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .fill(CSTheme.surface.opacity(0.5))
        )
        .clipShape(RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous))
        // Overlays MUST be applied after sizing + clipping.
        .overlay {
            LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            hoverInfoSection
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            likeButton
                .padding(10)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(isHovering)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.Radius.large, style: .continuous)
                .stroke(
                    isHovering ? screensaver.category.tintColor.opacity(0.35) : Color.white.opacity(0.06),
                    lineWidth: isHovering ? 1.0 : 0.5
                )
        )
        .scaleEffect(isHovering ? 1.015 : 1.0)
        .shadow(
            color: isHovering ? screensaver.category.tintColor.opacity(0.15) : Color.black.opacity(0.2),
            radius: isHovering ? 24 : 12,
            y: isHovering ? 10 : 4
        )
        .animation(CSTheme.Animation.spring, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            withAnimation(CSTheme.Animation.standard) {
                apiManager.detailedScreensaver = screensaver
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
    }
    
    // MARK: - Thumbnail (16pt radius enforced)
    
    private var thumbnailView: some View {
        ZStack(alignment: .topLeading) {
            // Live Preview Simulation (Animates on hover)
            if isHovering, let urlStr = screensaver.previewURL, let url = URL(string: urlStr) {
                VideoPlayer(player: AVPlayer(url: url))
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .onAppear {
                        // Silent autoplay
                    }
            } else if screensaver.thumbnailURL != "placeholder" {
                Group {
                    let resourceName = (screensaver.thumbnailURL as NSString).deletingPathExtension
                    let ext = (screensaver.thumbnailURL as NSString).pathExtension
                    
                    if let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: ext, subdirectory: "Thumbnails"),
                       let nsImage = NSImage(contentsOf: bundleURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else if let nsImage = NSImage(named: screensaver.thumbnailURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else if let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: ext, subdirectory: "Categories"),
                              let nsImage = NSImage(contentsOf: bundleURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        fallbackThumbnail
                    }
                }
            } else {
                fallbackThumbnail
            }
            // "NEW" Badge
            if screensaver.isNew {
                Text("NEW")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue))
                    .padding(CSTheme.Spacing.sm)
                    .offset(y: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: CSTheme.Radius.large,
                bottomLeadingRadius: CSTheme.Radius.large,
                bottomTrailingRadius: CSTheme.Radius.large,
                topTrailingRadius: CSTheme.Radius.large
            )
        )
    }
    
    
    // MARK: - Info Section
    
    private var hoverInfoSection: some View {
        VStack(alignment: .leading, spacing: CSTheme.Spacing.sm) {
            Text(screensaver.name)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            Text("by \(screensaver.author)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 44) // keep clear of like button
    }
    
    private var likeButton: some View {
        Button(action: {
            apiManager.toggleLiked(screensaver)
        }) {
            Image(systemName: apiManager.isLiked(screensaver) ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(apiManager.isLiked(screensaver) ? .red : .white)
                .padding(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Gradient Generator
    
    private func gradient(for saver: Screensaver) -> LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(colors: [Color(hex: 0x0F172A), Color(hex: 0x1E3A5F), Color(hex: 0x0F766E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [Color(hex: 0x2D1B69), Color(hex: 0x11998E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: 0x1F1C2C), Color(hex: 0x928DAB)], startPoint: .bottom, endPoint: .top),
            LinearGradient(colors: [Color(hex: 0x0D324D), Color(hex: 0x7F5A83)], startPoint: .topLeading, endPoint: .bottomTrailing),
        ]
        let index = abs(saver.name.hashValue) % gradients.count
        return gradients[index]
    }
    
    private var fallbackThumbnail: some View {
        ZStack {
            gradient(for: screensaver)
            VStack(spacing: 8) {
                Image(systemName: screensaver.category.iconName)
                    .font(.system(size: 32))
                Text(screensaver.category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
            }
            .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
