import CoreLocation
import Foundation
import GooglePlaces
import MapKit

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
}

struct PlaceContactDetails: Hashable {
    let websiteURL: URL?
    let phoneNumber: String?

    var hasDirectContact: Bool {
        websiteURL != nil || phoneNumber?.nonEmpty != nil
    }
}

@MainActor
final class PlacesService {
    static let shared = PlacesService()

    private let googleEnabled: Bool

    private init(bundle: Bundle = .main) {
        let configuredKey = (bundle.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = configuredKey?.hasPrefix("$(") == true ? nil : configuredKey?.nonEmpty
        self.googleEnabled = apiKey.map(GMSPlacesClient.provideAPIKey) ?? false
    }

    func search(query: String, near location: CLLocation? = nil) async -> [PlaceSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        if googleEnabled {
            do {
                let results = try await searchGoogle(query: trimmed, near: location)
                if !results.isEmpty { return results }
            } catch {
                // Keep manual add and place selection available if Google is temporarily unavailable.
            }
        }

        return await searchApple(query: trimmed, near: location)
    }

    func enrichGoogleRestaurants(_ restaurants: [Restaurant]) async -> [Restaurant] {
        var enriched: [Restaurant] = []
        enriched.reserveCapacity(restaurants.count)
        for restaurant in restaurants {
            enriched.append(await enrichGoogleRestaurant(restaurant) ?? restaurant)
        }
        return enriched
    }

    func enrichGoogleRestaurant(_ restaurant: Restaurant) async -> Restaurant? {
        guard let placeId = restaurant.googlePlaceId,
              let place = try? await fetchGooglePlace(placeId: placeId) else {
            return nil
        }

        var enriched = restaurant
        enriched.address = place.address
        enriched.latitude = place.latitude
        enriched.longitude = place.longitude
        if enriched.cuisine == nil { enriched.cuisine = place.cuisine }
        if enriched.priceTier == nil { enriched.priceTier = place.priceTier }
        if let detectedType = place.establishmentType,
           enriched.establishmentType == .restaurant {
            enriched.establishmentType = detectedType
        }
        return enriched
    }

    func contactDetails(for restaurant: Restaurant) async -> PlaceContactDetails? {
        guard let placeId = restaurant.googlePlaceId else { return nil }
        return try? await fetchGoogleContactDetails(placeId: placeId)
    }

    private func searchGoogle(
        query: String,
        near location: CLLocation?
    ) async throws -> [PlaceSearchResult] {
        let properties = [
            GMSPlaceProperty.name,
            GMSPlaceProperty.placeID,
            GMSPlaceProperty.formattedAddress,
            GMSPlaceProperty.coordinate,
            GMSPlaceProperty.types,
            GMSPlaceProperty.priceLevel
        ].map(\.rawValue)
        let request = GMSPlaceSearchByTextRequest(textQuery: query, placeProperties: properties)
        request.maxResultCount = 5
        if let location {
            request.locationBias = GMSPlaceCircularLocationOption(location.coordinate, 25_000)
        }

        return try await withCheckedThrowingContinuation { continuation in
            GMSPlacesClient.shared().searchByText(with: request) { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let places = response?.places else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: places.compactMap(\.searchResult))
            }
        }
    }

    private func fetchGooglePlace(placeId: String) async throws -> PlaceSearchResult {
        guard googleEnabled else { throw PlacesServiceError.googleNotConfigured }

        let properties = [
            GMSPlaceProperty.name,
            GMSPlaceProperty.placeID,
            GMSPlaceProperty.formattedAddress,
            GMSPlaceProperty.coordinate,
            GMSPlaceProperty.types,
            GMSPlaceProperty.priceLevel
        ].map(\.rawValue)
        let request = GMSFetchPlaceRequest(
            placeID: placeId,
            placeProperties: properties,
            sessionToken: nil
        )

        return try await withCheckedThrowingContinuation { continuation in
            GMSPlacesClient.shared().fetchPlace(with: request) { place, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = place?.searchResult else {
                    continuation.resume(throwing: PlacesServiceError.missingGooglePlace)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }

    private func fetchGoogleContactDetails(placeId: String) async throws -> PlaceContactDetails {
        guard googleEnabled else { throw PlacesServiceError.googleNotConfigured }

        let properties = [
            GMSPlaceProperty.website,
            GMSPlaceProperty.phoneNumber
        ].map(\.rawValue)
        let request = GMSFetchPlaceRequest(
            placeID: placeId,
            placeProperties: properties,
            sessionToken: nil
        )

        return try await withCheckedThrowingContinuation { continuation in
            GMSPlacesClient.shared().fetchPlace(with: request) { place, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let place else {
                    continuation.resume(throwing: PlacesServiceError.missingGooglePlace)
                    return
                }
                continuation.resume(returning: PlaceContactDetails(
                    websiteURL: place.website,
                    phoneNumber: place.phoneNumber?.nonEmpty
                ))
            }
        }
    }

    private func searchApple(query: String, near location: CLLocation?) async -> [PlaceSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        if let location {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
            )
        }

        do {
            return try await MKLocalSearch(request: request)
                .start()
                .mapItems
                .prefix(5)
                .map(\.searchResult)
        } catch {
            return []
        }
    }
}

private enum PlacesServiceError: Error {
    case googleNotConfigured
    case missingGooglePlace
}

private extension GMSPlace {
    var searchResult: PlaceSearchResult? {
        guard let placeID, let name else { return nil }
        let allTypes = Set(types ?? [])
        let primaryType = allTypes.first { $0.hasSuffix("_restaurant") }
            ?? allTypes.first { ["restaurant", "cafe", "bar", "bakery", "brewery", "winery"].contains($0) }
        return PlaceSearchResult(
            id: "google:\(placeID)",
            provider: .google,
            name: name,
            address: formattedAddress?.nonEmpty,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            googlePlaceId: placeID,
            primaryType: primaryType,
            establishmentType: allTypes.establishmentTypeHint,
            cuisine: allTypes.cuisineHint,
            priceTier: priceLevel.restaurantPriceTier,
            vibeHints: allTypes.vibeHints
        )
    }
}

private extension MKMapItem {
    var searchResult: PlaceSearchResult {
        let address = [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality]
            .compactMap { $0 }
            .joined(separator: " ")
            .nonEmpty
        let category = pointOfInterestCategory
        return PlaceSearchResult(
            id: "apple:\(name ?? ""):\(placemark.coordinate.latitude):\(placemark.coordinate.longitude)",
            provider: .apple,
            name: name ?? "",
            address: address,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            googlePlaceId: nil,
            primaryType: nil,
            establishmentType: category?.establishmentTypeHint,
            cuisine: nil,
            priceTier: nil,
            vibeHints: category?.vibeHints ?? []
        )
    }
}

private extension MKPointOfInterestCategory {
    var establishmentTypeHint: Restaurant.EstablishmentType? {
        switch self {
        case .cafe:       return .cafe
        case .brewery:    return .brewery
        case .winery:     return .winery
        case .nightlife:  return .bar
        case .bakery:     return .bakery
        case .restaurant: return .restaurant
        default:          return nil
        }
    }

    var vibeHints: Set<String> {
        switch self {
        case .cafe:      return ["Casual", "Quick bite"]
        case .brewery:   return ["Casual", "Lively"]
        case .nightlife: return ["Late night", "Lively"]
        case .bakery:    return ["Casual", "Quick bite"]
        case .winery:    return ["Date night", "Special occasion"]
        default:         return []
        }
    }
}

private extension Set where Element == String {
    var establishmentTypeHint: Restaurant.EstablishmentType? {
        if contains("cafe") || contains("coffee_shop") { return .cafe }
        if contains("bakery") { return .bakery }
        if contains("brewery") { return .brewery }
        if contains("winery") { return .winery }
        if contains("bar") || contains("night_club") { return .bar }
        if contains("restaurant") || contains(where: { $0.hasSuffix("_restaurant") }) {
            return .restaurant
        }
        return nil
    }

    var cuisineHint: String? {
        let cuisines: [(String, String)] = [
            ("american_restaurant", "American"),
            ("chinese_restaurant", "Chinese"),
            ("french_restaurant", "French"),
            ("greek_restaurant", "Greek"),
            ("indian_restaurant", "Indian"),
            ("italian_restaurant", "Italian"),
            ("japanese_restaurant", "Japanese"),
            ("korean_restaurant", "Korean"),
            ("mediterranean_restaurant", "Mediterranean"),
            ("mexican_restaurant", "Mexican"),
            ("thai_restaurant", "Thai"),
            ("vietnamese_restaurant", "Vietnamese")
        ]
        return cuisines.first { contains($0.0) }?.1
    }

    var vibeHints: Set<String> {
        var hints: Set<String> = []
        if contains("cafe") || contains("coffee_shop") || contains("bakery") {
            hints.formUnion(["Casual", "Quick bite"])
        }
        if contains("bar") || contains("night_club") {
            hints.formUnion(["Late night", "Lively"])
        }
        if contains("brewery") {
            hints.formUnion(["Casual", "Lively"])
        }
        if contains("winery") {
            hints.formUnion(["Date night", "Special occasion"])
        }
        return hints
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

}

private extension GMSPlacesPriceLevel {
    var restaurantPriceTier: Restaurant.PriceTier? {
        switch self {
        case .cheap:     return .one
        case .medium:    return .two
        case .high:      return .three
        case .expensive: return .four
        default:         return nil
        }
    }
}
