import CoreGraphics
import Foundation

/// Google photo and required credits held only for the current detail screen.
struct PlacePhoto {
    struct Author {
        let name: String
        let url: URL?
    }
    let image: CGImage
    let attribution: AttributedString?
    let authors: [Author]
    let googleMapsURL: URL?
    let reportURL: URL?
}
