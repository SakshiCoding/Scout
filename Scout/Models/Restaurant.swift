import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable, Hashable {
    let id: UUID
    var circleId: UUID
    var name: String
    var cuisine: String?
    var establishmentType: EstablishmentType
    var priceTier: PriceTier?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var status: RestaurantStatus
    var notes: String?
    var vibeTags: [String]
    var rating: Double?
    var photoUrl: String?
    var googlePlaceId: String?
    var addedBy: UUID?
    let createdAt: Date

    // Not persisted — set by LocationService after fetch
    var distanceMiles: Double?

    enum EstablishmentType: String, Codable, CaseIterable, Hashable {
        case restaurant = "restaurant"
        case cafe       = "cafe"
        case bar        = "bar"
        case bakery     = "bakery"
        case brewery    = "brewery"
        case winery     = "winery"
        case other      = "other"

        var displayName: String {
            switch self {
            case .restaurant: return "Restaurant"
            case .cafe:       return "Cafe"
            case .bar:        return "Bar"
            case .bakery:     return "Bakery"
            case .brewery:    return "Brewery"
            case .winery:     return "Winery"
            case .other:      return "Other"
            }
        }
    }

    enum PriceTier: String, Codable, CaseIterable, Hashable {
        case one   = "$"
        case two   = "$$"
        case three = "$$$"
        case four  = "$$$$"
    }

    enum RestaurantStatus: String, Codable, Hashable {
        case wantToTry = "want_to_try"
        case visited
    }

    var formattedDistance: String? {
        distanceMiles.map { String(format: "%.1f", $0) }
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, cuisine, address, latitude, longitude, status, notes, rating
        case circleId         = "circle_id"
        case establishmentType = "establishment_type"
        case priceTier        = "price_tier"
        case vibeTags         = "vibe_tags"
        case photoUrl         = "photo_url"
        case googlePlaceId    = "google_place_id"
        case addedBy          = "added_by"
        case createdAt        = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c      = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(UUID.self,   forKey: .id)
        circleId   = try c.decode(UUID.self,   forKey: .circleId)
        name       = try c.decode(String.self, forKey: .name)
        cuisine    = try c.decodeIfPresent(String.self,   forKey: .cuisine)
        let typeRaw = try c.decodeIfPresent(String.self, forKey: .establishmentType) ?? "restaurant"
        establishmentType = EstablishmentType(rawValue: typeRaw) ?? .restaurant
        priceTier  = try c.decodeIfPresent(PriceTier.self, forKey: .priceTier)
        address    = try c.decodeIfPresent(String.self,   forKey: .address)
        latitude   = try c.decodeIfPresent(Double.self,   forKey: .latitude)
        longitude  = try c.decodeIfPresent(Double.self,   forKey: .longitude)
        status     = try c.decodeIfPresent(RestaurantStatus.self, forKey: .status) ?? .wantToTry
        notes      = try c.decodeIfPresent(String.self,   forKey: .notes)
        vibeTags   = try c.decodeIfPresent([String].self, forKey: .vibeTags) ?? []
        rating     = try c.decodeIfPresent(Double.self,   forKey: .rating)
        photoUrl   = try c.decodeIfPresent(String.self,   forKey: .photoUrl)
        googlePlaceId = try c.decodeIfPresent(String.self, forKey: .googlePlaceId)
        addedBy    = try c.decodeIfPresent(UUID.self,     forKey: .addedBy)
        createdAt  = try c.decode(Date.self,              forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,               forKey: .id)
        try c.encode(circleId,         forKey: .circleId)
        try c.encode(name,             forKey: .name)
        try c.encodeIfPresent(cuisine, forKey: .cuisine)
        try c.encode(establishmentType.rawValue, forKey: .establishmentType)
        try c.encodeIfPresent(priceTier, forKey: .priceTier)
        try c.encodeIfPresent(address,   forKey: .address)
        try c.encodeIfPresent(latitude,  forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encode(status,    forKey: .status)
        try c.encodeIfPresent(notes,     forKey: .notes)
        try c.encode(vibeTags,           forKey: .vibeTags)
        try c.encodeIfPresent(rating,    forKey: .rating)
        try c.encodeIfPresent(photoUrl,  forKey: .photoUrl)
        try c.encodeIfPresent(googlePlaceId, forKey: .googlePlaceId)
        try c.encodeIfPresent(addedBy,   forKey: .addedBy)
        try c.encode(createdAt,          forKey: .createdAt)
    }

    init(id: UUID = UUID(),
         circleId: UUID,
         name: String,
         cuisine: String? = nil,
         establishmentType: EstablishmentType = .restaurant,
         priceTier: PriceTier? = nil,
         address: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         status: RestaurantStatus = .wantToTry,
         notes: String? = nil,
         vibeTags: [String] = [],
         rating: Double? = nil,
         photoUrl: String? = nil,
         googlePlaceId: String? = nil,
         addedBy: UUID? = nil,
         createdAt: Date = Date(),
         distanceMiles: Double? = nil) {
        self.id                = id
        self.circleId          = circleId
        self.name              = name
        self.cuisine           = cuisine
        self.establishmentType = establishmentType
        self.priceTier         = priceTier
        self.address           = address
        self.latitude          = latitude
        self.longitude         = longitude
        self.status            = status
        self.notes             = notes
        self.vibeTags          = vibeTags
        self.rating            = rating
        self.photoUrl          = photoUrl
        self.googlePlaceId     = googlePlaceId
        self.addedBy           = addedBy
        self.createdAt         = createdAt
        self.distanceMiles     = distanceMiles
    }
}
