//
//  AddScreensaverView.swift
//  ClockSpace
//

import SwiftUI

struct AddScreensaverView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apiManager: APIManager
    @State private var isHoveringDropZone = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 40) {
                    // ── Header Section ──
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share with the Community")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("Upload your favorite wallpapers.")
                                .font(.system(size: 14))
                                .foregroundColor(CSTheme.textTertiary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            HStack {
                                Text("Personal Use")
                                Image(systemName: "plus")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // ── Drop Zone ──
                    VStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundColor(isHoveringDropZone ? .white : Color.white.opacity(0.1))
                            .frame(height: 300)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.02))
                            )
                            .overlay(
                                VStack(spacing: 16) {
                                    Button(action: {
                                        // Open File Picker
                                    }) {
                                        HStack {
                                            Text("Select")
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 10))
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("MP4 • 3840x2160 min (4K) • Under 60s • Max 200MB")
                                        .font(.system(size: 11))
                                        .foregroundColor(CSTheme.textTertiary)
                                }
                            )
                    }
                    
                    // ── My Uploads Section ──
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My uploads")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Your uploaded wallpapers")
                                    .font(.system(size: 12))
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
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(apiManager.screensavers.prefix(3)) { saver in
                                uploadItemCard(saver)
                            }
                        }
                    }
                }
                .padding(40)
            }
            
            // Close Action
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(CSTheme.textTertiary)
                    .padding(40)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 900, height: 700)
        .background(CSTheme.backgroundPrimary)
        .preferredColorScheme(.dark)
    }
    
    private func uploadItemCard(_ saver: Screensaver) -> some View {
        ZStack(alignment: .topTrailing) {
            ScreensaverCard(screensaver: saver)
            
            // Approved Badge
            Text("Approved")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.8))
                .cornerRadius(6)
                .padding(8)
        }
    }
}
