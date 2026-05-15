import SwiftUI

struct RestaurantRowView: View {
    let restaurant: Restaurant
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Index numeral — serif 22, burnt orange, always 2 digits
            Text(String(format: "%02d", index))
                .font(Atlas.Font.serif(22))
                .foregroundColor(Atlas.burnt)
                .frame(width: 30, alignment: .leading)
                .padding(.top, 4)

            // Body
            VStack(alignment: .leading, spacing: 4) {
                // Name + distance
                HStack(alignment: .firstTextBaseline) {
                    Text(restaurant.name)
                        .font(Atlas.Font.serif(20))
                        .foregroundColor(Atlas.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 8)
                    if let dist = restaurant.formattedDistance {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(dist)
                                .font(Atlas.Font.serif(18))
                                .foregroundColor(Atlas.ink)
                            Text("MI")
                                .font(Atlas.Font.sans(10))
                                .foregroundColor(Atlas.ink3)
                                .kerning(0.5)
                        }
                    }
                }

                // Cuisine · Price · Rating
                HStack(spacing: 5) {
                    if let cuisine = restaurant.cuisine {
                        Text(cuisine)
                    }
                    if restaurant.cuisine != nil && restaurant.priceTier != nil {
                        Text("·").foregroundColor(Atlas.ink3)
                    }
                    if let price = restaurant.priceTier {
                        Text(price.rawValue)
                    }
                    if restaurant.rating != nil {
                        Text("·").foregroundColor(Atlas.ink3)
                        Text(String(format: "%.1f", restaurant.rating!))
                            .font(Atlas.Font.serif(12.5))
                            .foregroundColor(Atlas.ink)
                    }
                }
                .font(Atlas.Font.sans(12.5))
                .foregroundColor(Atlas.ink2)

                // Status dot + vibe tags
                HStack(spacing: 0) {
                    StatusDot(status: .open)  // Phase 2 will wire real hours data
                    Spacer()
                    HStack(spacing: 0) {
                        ForEach(restaurant.vibeTags.prefix(2), id: \.self) { tag in
                            VibeTagLabel(tag: tag)
                        }
                    }
                }
                .padding(.top, 4)
            }

            // Thumbnail
            RestaurantThumbnail(url: restaurant.photoUrl)
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Divider()
                .background(Atlas.rule)
        }
    }
}

struct RestaurantThumbnail: View {
    let url: String?

    var body: some View {
        Group {
            if let urlStr = url, let imageUrl = URL(string: urlStr) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Atlas.paper2
                    }
                }
                .clipped()
            } else {
                Atlas.paper2
            }
        }
        .frame(width: 64, height: 76)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(Array(Restaurant.mockList.prefix(3).enumerated()), id: \.element.id) { i, r in
            RestaurantRowView(restaurant: r, index: i + 1)
        }
    }
    .padding(.horizontal, Atlas.screenHPad)
    .background(Atlas.paper)
}
