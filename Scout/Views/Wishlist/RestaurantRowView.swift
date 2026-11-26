import SwiftUI

/// Presentational row shared with native layout tests. Distance never competes with the title.
struct RestaurantRowView: View {
    let restaurant: Restaurant
    var image: CGImage?
    var isLoading = false
    var legacyImageURL: URL?
    var googlePhoto: PlacePhoto?
    var open: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout =
            typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
        return layout {
            if let open {
                Button(action: open) { thumbnail }.buttonStyle(.plain)
                    .accessibilityLabel("Open \(restaurant.name)")
            } else {
                thumbnail
            }
            VStack(alignment: .leading, spacing: 6) {
                if let open {
                    Button(action: open) { details }.buttonStyle(.plain)
                        .accessibilityHint("Opens restaurant details")
                } else {
                    details
                }
                if let googlePhoto { CompactWishlistPhotoCredit(photo: googlePhoto) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(restaurant.name)
                .font(Atlas.Font.serif(21))
                .foregroundStyle(Atlas.ink)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            if !metadata.isEmpty {
                Text(metadata)
                    .font(Atlas.Font.sans(12.5))
                    .foregroundStyle(Atlas.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let distance = restaurant.formattedDistance {
                Label("\(distance) mi", systemImage: "mappin")
                    .font(Atlas.Font.sans(12, weight: .medium))
                    .foregroundStyle(Atlas.ink2)
            }
            if !restaurant.vibeTags.isEmpty {
                Text(restaurant.vibeTags.prefix(2).joined(separator: " · "))
                    .font(Atlas.Font.sans(11.5))
                    .foregroundStyle(Atlas.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !isLoading, image == nil, legacyImageURL == nil, restaurant.googlePlaceId == nil {
                Text("Link a place in Edit for photos")
                    .font(Atlas.Font.sans(11)).foregroundStyle(Atlas.burnt)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadata: String {
        [
            restaurant.cuisine, restaurant.priceTier?.rawValue,
            restaurant.rating.map { String(format: "%.1f ★", $0) },
        ].compactMap { $0 }.joined(separator: " · ")
    }

    private var thumbnail: some View {
        ZStack {
            Atlas.paper2
            if let image {
                Image(image, scale: 1, label: Text("Photo of \(restaurant.name)"))
                    .resizable().scaledToFill()
            } else if let legacyImageURL {
                AsyncImage(url: legacyImageURL) { phase in
                    if case .success(let image) = phase { image.resizable().scaledToFill() } else { fallback }
                }
            } else {
                fallback
            }
        }
        .frame(width: typeSize.isAccessibilitySize ? 60 : 80, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var fallback: some View {
        VStack(spacing: 6) {
            Text(
                restaurant.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init)
                    .joined()
            )
            .font(Atlas.Font.serif(23)).foregroundStyle(Atlas.burnt)
            if isLoading {
                Image(systemName: "ellipsis").foregroundStyle(Atlas.ink3)
            } else {
                Image(systemName: "photo").foregroundStyle(Atlas.ink3)
            }
        }
        .accessibilityLabel(isLoading ? "Loading photo" : "No photo available")
    }
}
