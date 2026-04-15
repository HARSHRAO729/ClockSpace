import SwiftUI

struct CategoryScreensView: View {
    let category: Category
    let onBack: () -> Void
    
    @EnvironmentObject var apiManager: APIManager
    
    private var items: [Screensaver] {
        apiManager.screensavers.filter { $0.category == category }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    )
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(CSTheme.Font.sectionTitle)
                        .foregroundColor(.white)
                    Text("\(items.count) screensavers")
                        .font(CSTheme.Font.caption)
                        .foregroundColor(CSTheme.textTertiary)
                }
                
                Spacer()
            }
            
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(CSTheme.textTertiary)
                    Text("No screensavers in this category yet")
                        .font(CSTheme.Font.body)
                        .foregroundColor(CSTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(items) { saver in
                        ScreensaverCard(screensaver: saver)
                            .frame(maxWidth: .infinity)
                            .frame(height: 186)
                    }
                }
            }
        }
    }
}
