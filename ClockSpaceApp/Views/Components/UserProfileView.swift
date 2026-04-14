//
//  UserProfileView.swift
//  ClockSpace
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Logo Image
            Image("ClockSpace")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
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
