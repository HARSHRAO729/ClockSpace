//
//  ScreensaverDetailView.swift
//  ClockSpace
//
//  Immersive detail view for a screensaver.
//  Floating translucent pill nav bar, Wallspace-style.
//

import SwiftUI
import AVKit

struct ScreensaverDetailView: View {
    let screensaver: Screensaver
    @EnvironmentObject var apiManager: APIManager
    @StateObject private var manager = ScreensaverManager.shared
    
    @State private var isAnimating = false
    @State private var player = AVPlayer()
    
    /// Derived install state
    private var installState: InstallState {
        if manager.activeID == screensaver.id {
            return .active
        } else if manager.isInstalling(screensaver) {
            return .installing
        } else if manager.isInstalled(screensaver) {
            return .installed
        } else {
            return .ready
        }
    }
    
        ZStack {
            // ── Background Media ──
            livePreviewBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()
            
            // ── Floating Controls ──
            VStack {
                Spacer()
                
                floatingPillBar
                    .padding(.horizontal, 40)
                    .padding(.bottom, 36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Installation Error", isPresented: Binding(
            get: { manager.lastError != nil },
            set: { if !$0 { manager.lastError = nil } }
        )) {
            Button("OK") { manager.lastError = nil }
        } message: {
            Text(manager.lastError?.localizedDescription ?? "An unexpected error occurred.")
        }
    }
    
    // MARK: - Floating Pill Bar (Wallspace Style)
    
    private var floatingPillBar: some View {
        HStack(spacing: 16) {
            // Back Button
            Button(action: {
                withAnimation(CSTheme.Animation.standard) {
                    apiManager.detailedScreensaver = nil
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
            
            // Title & Author
            VStack(alignment: .leading, spacing: 1) {
                Text(screensaver.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("by \(screensaver.author)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(screensaver.category.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Action Icons
            HStack(spacing: 10) {
                // Share
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
                // Heart/Like
                Button(action: {
                    withAnimation(.spring()) {
                        apiManager.toggleLiked(screensaver)
                    }
                }) {
                    Image(systemName: apiManager.isLiked(screensaver) ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(apiManager.isLiked(screensaver) ? .red : .white.opacity(0.8))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 28)
            
            // Install / Apply CTA
            installButton
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .background(
            Capsule()
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
    
    // MARK: - Install Button CTA
    
    @ViewBuilder
    private var installButton: some View {
        switch installState {
        case .ready:
            Button(action: {
                Task {
                await manager.installFromMarketplace(screensaver)
            }
        }) {
            Text("Apply")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(screensaver.isPremium ? .black : .white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(CSTheme.accent)
                    )
            }
            .buttonStyle(.plain)
            
        case .installing:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                
                Text("Installing...")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.2)))
            
        case .installed:
            Button(action: {
                let fileName: String
                if screensaver.downloadURL.hasPrefix("local://") {
                    fileName = String(screensaver.downloadURL.dropFirst(8))
                } else {
                    let nameSlug = screensaver.name.replacingOccurrences(of: " ", with: "-").lowercased()
                    fileName = "\(nameSlug).saver"
                }
                
                let saverPath = manager.screenSaversDirectory.appendingPathComponent(fileName).path
                let success = manager.applyScreensaver(name: screensaver.name, path: saverPath)
                if !success {
                    manager.lastError = ScreensaverInstallError.unknown("Failed to open System Settings.")
                }
            }) {
                Text("Open in Settings")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(CSTheme.surfaceElevated)
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            
        case .active:
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                Text("Active")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(CSTheme.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(CSTheme.accent.opacity(0.12)))
            .overlay(Capsule().stroke(CSTheme.accent.opacity(0.3), lineWidth: 1))
        }
    }
    
    // MARK: - Live Preview Background
    
    private var livePreviewBackground: some View {
        Group {
            if let urlStr = screensaver.previewURL, let url = URL(string: urlStr) {
                VideoPlayer(player: player)
                    .onAppear {
                        let item = AVPlayerItem(url: url)
                        player.replaceCurrentItem(with: item)
                        player.isMuted = true
                        player.play()
                        
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: item,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            } else {
                ZStack {
                    if screensaver.thumbnailURL != "placeholder" {
                        let resourceName = (screensaver.thumbnailURL as NSString).deletingPathExtension
                        let ext = (screensaver.thumbnailURL as NSString).pathExtension
                        
                        if let bundleURL = Bundle.main.url(forResource: resourceName, withExtension: ext, subdirectory: "Thumbnails"),
                           let nsImage = NSImage(contentsOf: bundleURL) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let nsImage = NSImage(named: screensaver.thumbnailURL) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            fallbackBackground
                        }
                    } else {
                        fallbackBackground
                    }
                }
            }
        }
    }
    
    private var fallbackBackground: some View {
        ZStack {
            gradient(for: screensaver)
            
            MeshGradientView(tintColor: screensaver.category.tintColor)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)
                .offset(y: isAnimating ? 400 : -400)
        }
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Gradient Helper
    
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
}

// MARK: - Mesh Gradient Extracted Component

struct MeshGradientView: View {
    let tintColor: Color
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.black.opacity(0.1)))
                
                let baseColor = tintColor.opacity(0.15)
                let gradient = Gradient(colors: [baseColor, Color.clear])
                
                for i in 0..<3 {
                    let offset = Double(i)
                    let w = Double(size.width)
                    let h = Double(size.height)
                    
                    let x = w / 2.0 + cos(time * 0.5 + offset) * (w / 3.0)
                    let y = h / 2.0 + sin(time * 0.4 + offset) * (h / 3.0)
                    
                    let rect = CGRect(x: x - 200.0, y: y - 200.0, width: 400.0, height: 400.0)
                    let centerPoint = CGPoint(x: x, y: y)
                    
                    context.fill(Path(ellipseIn: rect), with: .radialGradient(
                        gradient,
                        center: centerPoint,
                        startRadius: 0,
                        endRadius: 200.0
                    ))
                }
            }
        }
    }
}
