import CoreLocation
import Foundation

/// Recognize existing entries in the active circle without guessing between chain locations.
enum SavedPlaceMatch {
    static func restaurant(for place: PlaceSearchResult, in restaurants: [Restaurant], circleId: UUID?) -> Restaurant? {
        guard let circleId else { return nil }
        return restaurants.first { restaurant in
            guard restaurant.circleId == circleId else { return false }
            if let id = place.googlePlaceId, let savedId = restaurant.googlePlaceId {
                return id == savedId
            }
            guard normalized(place.name) == normalized(restaurant.name) else { return false }
            if let address = place.address, let savedAddress = restaurant.address,
                !normalized(address).isEmpty, normalized(address) == normalized(savedAddress)
            {
                return true
            }
            guard let lat = restaurant.latitude, let lon = restaurant.longitude else { return false }
            return CLLocation(latitude: lat, longitude: lon)
                .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude)) < 75
        }
    }
    private static func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
}
