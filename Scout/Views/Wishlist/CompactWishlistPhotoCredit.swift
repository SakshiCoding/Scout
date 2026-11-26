import SwiftUI

/// Required source/author/provider credits are an inline caption, not a second card footer.
struct CompactWishlistPhotoCredit: View {
    let photo: PlacePhoto
    private var credit: AttributedString {
        var text = AttributedString("Google Maps")
        let duplicateProvider =
            photo.authors.count == 1
            && photo.attribution.map {
                String($0.characters) == photo.authors[0].name
                && ($0.link == photo.authors[0].url || $0.runs.allSatisfy { $0.link == nil } || photo.authors[0].url == nil)
            } == true
        for author in photo.authors {
            text += AttributedString(" · ")
            var name = AttributedString(author.name)
            if duplicateProvider, let provider = photo.attribution { name = provider }
            if !duplicateProvider || photo.attribution?.runs.allSatisfy({ $0.link == nil }) == true {
                name.link = author.url
            }
            text += name
        }
        if let provider = photo.attribution, !duplicateProvider {
            if !provider.characters.isEmpty {
                text += AttributedString(" · ")
                text += provider
            }
        }
        return text
    }
    var body: some View {
        Text(credit)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255))
            .tint(Atlas.burnt)
            .fixedSize(horizontal: false, vertical: true)
            .contextMenu {
                if let url = photo.googleMapsURL { Link("View on Google Maps", destination: url) }
                if let url = photo.reportURL { Link("Report photo", destination: url) }
            }
    }
}
