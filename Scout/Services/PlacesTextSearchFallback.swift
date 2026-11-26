import CoreLocation
import Foundation

/// Same Google provider and field-limited API, used only when the native SDK gives no usable results.
struct PlacesTextSearchFallback {
    private static let liveSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()
    private let apiKey: String
    private let bundleId: String?
    private let session: URLSession
    init(apiKey: String, bundleId: String?, session: URLSession? = nil) {
        self.apiKey = apiKey
        self.bundleId = bundleId
        self.session = session ?? Self.liveSession
    }
    func search(query: String, near location: CLLocation?) async throws -> [PlaceSearchResult] {
        try Task.checkCancellation()
        var request = URLRequest(url: URL(string: "https://places.googleapis.com/v1/places:searchText")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        if let bundleId { request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier") }
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.types,places.primaryType,places.priceLevel,places.attributions",
            forHTTPHeaderField: "X-Goog-FieldMask")
        var body: [String: Any] = ["textQuery": query, "pageSize": 5]
        if let location {
            body["locationBias"] = [
                "circle": [
                    "center": [
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude,
                    ], "radius": 25_000,
                ]
            ]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Response.self, from: data).places?.prefix(5).compactMap(\.result) ?? []
    }
    private struct Response: Decodable { let places: [Place]? }
    private struct Place: Decodable {
        struct Name: Decodable { let text: String }
        struct Location: Decodable {
            let latitude: Double
            let longitude: Double
        }
        struct Attribution: Decodable {
            let provider: String?
            let providerUri: String?
        }
        let id: String?
        let displayName: Name?
        let formattedAddress: String?
        let location: Location?
        let types: [String]?
        let primaryType: String?
        let priceLevel: String?
        let attributions: [Attribution]?
        var result: PlaceSearchResult? {
            guard let id, !id.isEmpty, let name = displayName?.text, !name.isEmpty, let location,
                location.latitude.isFinite, location.longitude.isFinite,
                (-90...90).contains(location.latitude), (-180...180).contains(location.longitude)
            else { return nil }
            let types = Set(types ?? [])
            let price: Restaurant.PriceTier?
            switch priceLevel {
            case "PRICE_LEVEL_INEXPENSIVE": price = .one
            case "PRICE_LEVEL_MODERATE": price = .two
            case "PRICE_LEVEL_EXPENSIVE": price = .three
            case "PRICE_LEVEL_VERY_EXPENSIVE": price = .four
            default: price = nil
            }
            var attribution = AttributedString()
            for item in attributions ?? [] {
                guard let provider = item.provider, !provider.isEmpty else { continue }
                if !attribution.characters.isEmpty { attribution += AttributedString(" · ") }
                var text = AttributedString(provider)
                text.link = item.providerUri.flatMap(URL.init(string:))
                attribution += text
            }
            return PlaceSearchResult(
                id: "google:\(id)", provider: .google, name: name, address: formattedAddress,
                latitude: location.latitude, longitude: location.longitude, googlePlaceId: id,
                primaryType: primaryType, establishmentType: types.establishmentTypeHint, cuisine: types.cuisineHint,
                priceTier: price, vibeHints: types.vibeHints,
                attribution: attribution.characters.isEmpty ? nil : attribution)
        }
    }
}
