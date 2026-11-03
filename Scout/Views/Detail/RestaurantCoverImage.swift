import CoreGraphics
import SwiftUI

struct RestaurantCoverImage: View {
    let image: CGImage?
    let restaurantName: String
    let isLoading: Bool
    let failed: Bool
    let retry: () -> Void
    let openJournal: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Atlas.paper2
                if let image {
                    Image(image, scale: 1, label: Text("Journal photo of \(restaurantName)"))
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    Button(action: openJournal) {
                        Label("View journal", systemImage: "book.closed")
                            .font(Atlas.Font.sans(12, weight: .semibold))
                            .foregroundStyle(Atlas.ink)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(Atlas.paper.opacity(0.94))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(restaurantName) journal")
                    .padding(16)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32, weight: .ultraLight))
                            .accessibilityHidden(true)
                        Text(isLoading ? "Loading journal photo…" : failed ? "Photo unavailable" : "No journal photo yet")
                            .font(Atlas.Font.sans(12))
                        if failed && !isLoading {
                            Button("Retry photo", action: retry)
                                .font(Atlas.Font.sans(13, weight: .semibold))
                                .foregroundStyle(Atlas.burnt)
                                .frame(minHeight: 44)
                                .buttonStyle(.plain)
                        }
                    }
                    .foregroundStyle(Atlas.ink3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .frame(height: 300)
    }
}
