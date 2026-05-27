import Foundation
import MapKit
import CoreLocation

@MainActor
final class PlacesService {
    static let shared = PlacesService()
    private init() {}

    func search(query: String, near location: CLLocation? = nil) async -> [MKMapItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = .pointOfInterest

        if let location {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
            )
        }

        do {
            return try await Array(MKLocalSearch(request: request).start().mapItems.prefix(5))
        } catch {
            return []
        }
    }
}

extension MKMapItem {
    var displayAddress: String {
        let p = placemark
        return [p.subThoroughfare, p.thoroughfare, p.locality]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

extension MKPointOfInterestCategory {
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
