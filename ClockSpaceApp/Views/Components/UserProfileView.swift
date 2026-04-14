//
//  UserProfileView.swift
//  ClockSpace
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar Background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [CSTheme.accent, CSTheme.civicEase],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // User Icon
            Image(systemName: "person.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            // Online Status Dot
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(CSTheme.backgroundPrimary, lineWidth: 2)
                )
                .offset(x: 2, y: 2)
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            UserProfileView()
        }
    }
}
