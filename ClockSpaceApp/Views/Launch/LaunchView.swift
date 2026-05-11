//
//  LaunchView.swift
//  ClockSpace
//
//  A premium, high-fidelity launch screen for the ClockSpace app.
//  Shown while the app connects to Firebase and loads initial resources.
//

import SwiftUI

struct LaunchView: View {
    @State private var isAnimating = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingStatus = "Initializing..."
    
    let statuses = [
        "Connecting to the universe of time...",
        "Syncing cosmic marketplace...",
        "Loading premium clock previews...",
        "Preparing your workspace...",
        "Finalizing connection..."
    ]
    
    var body: some View {
        ZStack {
            // Immersive Background
            MeshGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo with Glassmorphism
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    if let image = NSImage(named: "ClockSpace") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .scaleEffect(isAnimating ? 1.05 : 0.95)
                    } else {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .scaleEffect(isAnimating ? 1.05 : 0.95)
                    }
                }
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                
                VStack(spacing: 12) {
                    Text("ClockSpace")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text(loadingStatus)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(loadingStatus)
                }
                
                // Progress Bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * loadingProgress, height: 6)
                                .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 0)
                        }
                    }
                    .frame(width: 200, height: 6)
                }
                .padding(.top, 20)
                
                Spacer()
                
                Text("Version 0.50 Beta")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
            // Simulated smooth progress while waiting for real data
            simulateProgress()
        }
    }
    
    private func simulateProgress() {
        var statusIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if loadingProgress < 1.0 {
                withAnimation(.linear(duration: 0.1)) {
                    loadingProgress += 0.005 // Slower, more deliberate progress
                }
                
                // Update status text every ~15% progress
                let newIndex = Int(loadingProgress * Double(statuses.count))
                if newIndex != statusIndex && newIndex < statuses.count {
                    statusIndex = newIndex
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        loadingStatus = statuses[statusIndex]
                    }
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// Reuse the Mesh Gradient for consistency
struct MeshGradientBackground: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0B0B1E) // Deep space blue
            
            RadialGradient(
                colors: [Color.blue.opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 600
            )
            
            RadialGradient(
                colors: [Color.purple.opacity(0.15), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 600
            )
        }
    }
}

#Preview {
    LaunchView()
        .frame(width: 800, height: 600)
}
