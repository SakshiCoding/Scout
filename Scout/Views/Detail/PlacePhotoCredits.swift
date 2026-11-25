import SwiftUI

struct PlacePhotoCredits: View {
    let photo: PlacePhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Google Maps")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255))
            ForEach(Array(photo.authors.enumerated()), id: \.offset) { _, author in
                if let url = author.url {
                    Link("Photo: \(author.name)", destination: url)
                } else {
                    Text("Photo: \(author.name)")
                }
            }
            if let attribution = photo.attribution, !attribution.characters.isEmpty {
                Text(attribution)
            }
            HStack(spacing: 20) {
                if let url = photo.googleMapsURL { Link("View on Google Maps", destination: url) }
                if let url = photo.reportURL { Link("Report photo", destination: url) }
            }
        }
        .font(Atlas.Font.sans(12))
        .foregroundStyle(Atlas.ink2)
        .tint(Atlas.burnt)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Atlas.paper)
    }
}
