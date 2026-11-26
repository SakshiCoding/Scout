import CoreLocation
import Foundation
import GooglePlaces
import MapKit
import UIKit

@MainActor
final class PlacesService {
    static let shared = PlacesService()

    private let photoQueue = PlacePhotoRequestQueue()
    private let googleEnabled: Bool
    private let googleAPIKey: String?

    private init(bundle: Bundle = .main) {
        let configuredKey = (bundle.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = configuredKey?.hasPrefix("$(") == true ? nil : configuredKey?.nonEmpty
        self.googleAPIKey = apiKey
        self.googleEnabled = apiKey.map(GMSPlacesClient.provideAPIKey) ?? false
    }

    func search(query: String, near location: CLLocation? = nil) async -> [PlaceSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        // This SDK requires a location bias/restriction; HTTP Text Search also supports location-free queries.
        if googleEnabled, location != nil {
            do {
                let results = try await searchGoogle(query: trimmed, near: location)
                if !results.isEmpty { return results }
            } catch {
                // Fall back to Apple search if Google is temporarily unavailable.
            }
        }

        guard !Task.isCancelled else { return [] }
        if let googleAPIKey {
            let fallback = PlacesTextSearchFallback(apiKey: googleAPIKey, bundleId: Bundle.main.bundleIdentifier)
            if let results = try? await fallback.search(query: trimmed, near: location), !results.isEmpty {
                return results
            }
        }
        guard !Task.isCancelled else { return [] }
        return await searchApple(query: trimmed, near: location)
    }

    func enrichGoogleRestaurants(
        _ restaurants: [Restaurant],
        shouldContinue: @escaping @MainActor () -> Bool = { true }
    ) async -> [Restaurant] {
        await RestaurantEnrichment.refresh(restaurants, shouldContinue: shouldContinue) { [self] in
            await enrichGoogleRestaurant($0)
        }
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

    func contactDetails(placeId: String) async -> PlaceContactDetails? {
        return try? await fetchGoogleContactDetails(placeId: placeId)
    }

    /// Fetch on demand; photo bytes and references are never persisted by Scout.
    func photo(placeId: String, pixelSize: Int = 1024) async -> PlacePhoto? {
        await photoQueue.run { await self.fetchPhoto(placeId: placeId, pixelSize: pixelSize) }
    }

    private func fetchPhoto(placeId: String, pixelSize: Int) async -> PlacePhoto? {
        guard googleEnabled, !Task.isCancelled else { return nil }
        let request = GMSFetchPlaceRequest(placeID: placeId,
            placeProperties: [GMSPlaceProperty.photos.rawValue], sessionToken: nil)
        let place: GMSPlace? = await withCheckedContinuation { continuation in
            GMSPlacesClient.shared().fetchPlace(with: request) { place, _ in
                continuation.resume(returning: place)
            }
        }
        guard !Task.isCancelled else { return nil }
        for metadata in (place?.photos ?? []).prefix(3) {
            let request = GMSFetchPhotoRequest(photoMetadata: metadata,
                maxSize: CGSize(width: max(64, min(pixelSize, 1024)), height: max(64, min(pixelSize, 1024))))
            let image: UIImage? = await withCheckedContinuation { continuation in
                GMSPlacesClient.shared().fetchPhoto(with: request) { image, _ in
                    continuation.resume(returning: image)
                }
            }
            guard !Task.isCancelled else { return nil }
            if let image = image?.cgImage {
                return PlacePhoto(image: image,
                    attribution: metadata.attributions.flatMap { try? AttributedString($0, including: \.foundation) },
                    authors: (metadata.authorAttributions ?? []).map { .init(name: $0.name, url: $0.uri) },
                    googleMapsURL: metadata.googleMapsURL, reportURL: metadata.flagContentURL)
            }
        }
        return nil
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
            GMSPlaceProperty.placeID, .website, .phoneNumber, .openingHours,
            .currentOpeningHours, .secondaryOpeningHours, .utcOffsetMinutes, .businessStatus
        ].map(\.rawValue)
        let request = GMSFetchPlaceRequest(placeID: placeId, placeProperties: properties, sessionToken: nil)
        let place: GMSPlace = try await withCheckedThrowingContinuation { continuation in
            GMSPlacesClient.shared().fetchPlace(with: request) { place, error in
                if let error { continuation.resume(throwing: error); return }
                guard let place else {
                    continuation.resume(throwing: PlacesServiceError.missingGooglePlace)
                    return
                }
                continuation.resume(returning: place)
            }
        }
        try Task.checkCancellation()
        let checkedAt = Date()
        let status: PlaceContactDetails.OpenStatus
        switch place.businessStatus {
        case .closedTemporarily: status = .temporarilyClosed
        case .closedPermanently: status = .permanentlyClosed
        default:
            // Missing hours can cause the SDK to refetch them. Keep unknown rather than
            // triggering another billable lookup for a place without usable hours.
            if place.openingHours != nil, place.currentOpeningHours != nil,
               place.utcOffsetMinutes != nil, place.placeID != nil {
                status = await withCheckedContinuation { continuation in
                    let openRequest = GMSPlaceIsOpenRequest(place: place, date: checkedAt)
                    GMSPlacesClient.shared().isOpen(with: openRequest) { response, error in
                        guard error == nil else {
                            continuation.resume(returning: .unknown); return
                        }
                        switch response.status {
                        case .open: continuation.resume(returning: .open)
                        case .closed: continuation.resume(returning: .closed)
                        default: continuation.resume(returning: .unknown)
                        }
                    }
                }
            } else { status = .unknown }
        }
        return PlaceContactDetails(
            websiteURL: place.website, phoneNumber: place.phoneNumber?.nonEmpty,
            weekdayText: place.openingHours?.weekdayText ?? [], openStatus: status,
            checkedAt: checkedAt,
            providerAttribution: place.attributions.flatMap { try? AttributedString($0, including: \.foundation) }
        )
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
            vibeHints: allTypes.vibeHints,
            attribution: attributions.flatMap { try? AttributedString($0, including: \.foundation) }
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
