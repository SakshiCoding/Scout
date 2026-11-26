import Foundation

struct PlaceSearchResult: Identifiable, Hashable {
    enum Provider: Hashable {
        case google
        case apple
    }

    let id: String
    let provider: Provider
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let googlePlaceId: String?
    let primaryType: String?
    let establishmentType: Restaurant.EstablishmentType?
    let cuisine: String?
    let priceTier: Restaurant.PriceTier?
    let vibeHints: Set<String>
    var attribution: AttributedString? = nil
}
