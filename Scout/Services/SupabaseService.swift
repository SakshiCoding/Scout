import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        // Read from Info.plist (populated via Config.xcconfig at build time).
        // If missing, fall back to compile-time constants so the app never crashes on launch.
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
                        ?? SupabaseService.supabaseURL
        let anonKey   = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
                        ?? SupabaseService.supabaseAnonKey
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            fatalError("SUPABASE_URL is missing or invalid. Check Config.xcconfig and Info.plist.")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // Fallback constants — safe to keep here since the Supabase anon key is a public client key
    private static let supabaseURL      = "https://vdhhsxgirkjalysejycw.supabase.co"
    private static let supabaseAnonKey  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkaGhzeGdpcmtqYWx5c2VqeWN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4MDMyOTcsImV4cCI6MjA5NDM3OTI5N30.VPUzxIE4ztbLteAVHnifybOWmd5KXudF9yjJ6hc4z8M"

    // MARK: - Date decoder shared across all fetches
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // PostgREST returns ISO 8601 with timezone, sometimes with fractional seconds.
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]

            if let date = formatter.date(from: str) { return date }
            if let date = fallback.date(from: str)  { return date }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Cannot decode date: \(str)"
            )
        }
        return d
    }()

    // MARK: - Insert-only structs (exclude server-generated fields)

    private struct CreateCircleParams: Encodable {
        let circleName: String
        let circleShortName: String?
        let circleAccentColor: String
        let memberInitials: String
        enum CodingKeys: String, CodingKey {
            case circleName        = "circle_name"
            case circleShortName   = "circle_short_name"
            case circleAccentColor = "circle_accent_color"
            case memberInitials    = "member_initials"
        }
    }

    private struct AddRestaurantParams: Encodable {
        let restaurantCircleId: UUID
        let restaurantName: String
        let restaurantCuisine: String?
        let restaurantPriceTier: String?
        let restaurantAddress: String?
        let restaurantLatitude: Double?
        let restaurantLongitude: Double?
        let restaurantNotes: String?
        let restaurantVibeTags: [String]
        let restaurantRating: Double?
        let restaurantPhotoUrl: String?
        let restaurantEstablishmentType: String

        enum CodingKeys: String, CodingKey {
            case restaurantCircleId          = "restaurant_circle_id"
            case restaurantName              = "restaurant_name"
            case restaurantCuisine           = "restaurant_cuisine"
            case restaurantPriceTier         = "restaurant_price_tier"
            case restaurantAddress           = "restaurant_address"
            case restaurantLatitude          = "restaurant_latitude"
            case restaurantLongitude         = "restaurant_longitude"
            case restaurantNotes             = "restaurant_notes"
            case restaurantVibeTags          = "restaurant_vibe_tags"
            case restaurantRating            = "restaurant_rating"
            case restaurantPhotoUrl          = "restaurant_photo_url"
            case restaurantEstablishmentType = "restaurant_establishment_type"
        }
    }

    private struct GetCircleRestaurantsParams: Encodable {
        let targetCircleId: UUID

        enum CodingKeys: String, CodingKey {
            case targetCircleId = "target_circle_id"
        }
    }

    private struct AddVisitParams: Encodable {
        struct VisitPayload: Encodable {
            let visitedAt: Date
            let notes: String?
            let rating: Double?

            enum CodingKeys: String, CodingKey {
                case visitedAt = "visited_at"
                case notes
                case rating
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(visitedAt, forKey: .visitedAt)
                try container.encodeNullable(notes, forKey: .notes)
                try container.encodeNullable(rating, forKey: .rating)
            }
        }

        let targetRestaurantId: UUID
        let visitCircleId: UUID
        let visitPayload: VisitPayload

        enum CodingKeys: String, CodingKey {
            case targetRestaurantId = "target_restaurant_id"
            case visitCircleId      = "visit_circle_id"
            case visitPayload       = "visit_payload"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(targetRestaurantId, forKey: .targetRestaurantId)
            try container.encode(visitCircleId, forKey: .visitCircleId)
            try container.encode(visitPayload, forKey: .visitPayload)
        }
    }

    // MARK: - Circles

    func createCircle(name: String, shortName: String? = nil, accentColor: String = "#CC5500", userId: UUID, userInitials: String) async throws -> ScoutCircle {
        let circle: ScoutCircle = try await client
            .rpc(
                "create_circle",
                params: CreateCircleParams(
                    circleName: name,
                    circleShortName: shortName,
                    circleAccentColor: accentColor,
                    memberInitials: userInitials
                )
            )
            .execute()
            .value
        let all = try await fetchCircles(for: userId)
        return all.first { $0.id == circle.id } ?? circle
    }

    func fetchCircles(for userId: UUID) async throws -> [ScoutCircle] {
        _ = userId

        let response: [ScoutCircle] = try await client
            .rpc("get_my_circles")
            .execute()
            .value
        return response
    }

    // MARK: - Restaurants

    func fetchRestaurants(circleId: UUID) async throws -> [Restaurant] {
        try await client
            .rpc(
                "get_circle_restaurants",
                params: GetCircleRestaurantsParams(targetCircleId: circleId)
            )
            .execute()
            .value
    }

    func addRestaurant(_ restaurant: Restaurant) async throws -> Restaurant {
        try await client
            .rpc(
                "add_restaurant",
                params: AddRestaurantParams(
                    restaurantCircleId: restaurant.circleId,
                    restaurantName: restaurant.name,
                    restaurantCuisine: restaurant.cuisine,
                    restaurantPriceTier: restaurant.priceTier?.rawValue,
                    restaurantAddress: restaurant.address,
                    restaurantLatitude: restaurant.latitude,
                    restaurantLongitude: restaurant.longitude,
                    restaurantNotes: restaurant.notes,
                    restaurantVibeTags: restaurant.vibeTags,
                    restaurantRating: restaurant.rating,
                    restaurantPhotoUrl: restaurant.photoUrl,
                    restaurantEstablishmentType: restaurant.establishmentType.rawValue
                )
            )
            .execute()
            .value
    }

    func bulkAddRestaurants(_ names: [String], circleId: UUID, addedBy: UUID) async throws -> [Restaurant] {
        var savedRestaurants: [Restaurant] = []
        for name in names {
            let saved = try await addRestaurant(
                Restaurant(
                    circleId: circleId,
                    name: name,
                    addedBy: addedBy
                )
            )
            savedRestaurants.append(saved)
        }
        return savedRestaurants
    }

    func updateRestaurant(_ restaurant: Restaurant) async throws {
        struct Payload: Encodable {
            let name: String
            let cuisine: String?
            let priceTier: String?
            let address: String?
            let latitude: Double?
            let longitude: Double?
            let notes: String?
            let vibeTags: [String]
            let establishmentType: String
            enum CodingKeys: String, CodingKey {
                case name, cuisine, address, latitude, longitude, notes
                case priceTier        = "price_tier"
                case vibeTags         = "vibe_tags"
                case establishmentType = "establishment_type"
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .name)
                try container.encodeNullable(cuisine, forKey: .cuisine)
                try container.encodeNullable(priceTier, forKey: .priceTier)
                try container.encodeNullable(address, forKey: .address)
                try container.encodeNullable(latitude, forKey: .latitude)
                try container.encodeNullable(longitude, forKey: .longitude)
                try container.encodeNullable(notes, forKey: .notes)
                try container.encode(vibeTags, forKey: .vibeTags)
                try container.encode(establishmentType, forKey: .establishmentType)
            }
        }

        try await client
            .from("restaurants")
            .update(Payload(
                name: restaurant.name,
                cuisine: restaurant.cuisine,
                priceTier: restaurant.priceTier?.rawValue,
                address: restaurant.address,
                latitude: restaurant.latitude,
                longitude: restaurant.longitude,
                notes: restaurant.notes,
                vibeTags: restaurant.vibeTags,
                establishmentType: restaurant.establishmentType.rawValue
            ))
            .eq("id", value: restaurant.id)
            .execute()
    }

    func deleteRestaurant(_ id: UUID) async throws {
        struct Params: Encodable {
            let restaurantId: UUID
            enum CodingKeys: String, CodingKey {
                case restaurantId = "restaurant_id"
            }
        }
        try await client
            .rpc("delete_restaurant", params: Params(restaurantId: id))
            .execute()
    }

    func markVisited(_ restaurantId: UUID) async throws {
        struct Params: Encodable {
            let restaurantId: UUID
            enum CodingKeys: String, CodingKey {
                case restaurantId = "restaurant_id"
            }
        }
        try await client
            .rpc("mark_visited", params: Params(restaurantId: restaurantId))
            .execute()
    }

    func updateRestaurantRating(_ restaurantId: UUID, rating: Double) async throws {
        try await client
            .from("restaurants")
            .update(["rating": rating])
            .eq("id", value: restaurantId)
            .execute()
    }

    // MARK: - Picks

    func savePick(circleId: UUID, restaurantId: UUID, userId: UUID) async throws {
        struct PickRow: Encodable {
            let circleId: UUID
            let restaurantId: UUID
            let createdBy: UUID
            enum CodingKeys: String, CodingKey {
                case circleId = "circle_id"
                case restaurantId = "restaurant_id"
                case createdBy = "created_by"
            }
        }
        try await client
            .from("picks")
            .upsert(
                PickRow(circleId: circleId, restaurantId: restaurantId, createdBy: userId),
                onConflict: "circle_id,picked_date"
            )
            .execute()
    }

    func fetchTodayPick(circleId: UUID) async throws -> UUID? {
        struct PickRow: Decodable {
            let restaurantId: UUID
            enum CodingKeys: String, CodingKey {
                case restaurantId = "restaurant_id"
            }
        }
        let today = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        let rows: [PickRow] = try await client
            .from("picks")
            .select("restaurant_id")
            .eq("circle_id", value: circleId)
            .eq("picked_date", value: today)
            .limit(1)
            .execute()
            .value
        return rows.first?.restaurantId
    }

    // MARK: - Visits

    func addVisit(_ visit: Visit) async throws -> Visit {
        return try await client
            .rpc(
                "add_visit",
                params: AddVisitParams(
                    targetRestaurantId: visit.restaurantId,
                    visitCircleId: visit.circleId,
                    visitPayload: AddVisitParams.VisitPayload(
                        visitedAt: visit.visitedAt,
                        notes: visit.notes,
                        rating: visit.rating
                    )
                )
            )
            .execute()
            .value
    }

    // MARK: - Media

    func uploadVisitPhotos(
        _ photos: [Data],
        visitId: UUID,
        restaurantId: UUID,
        circleId: UUID,
        userId: UUID
    ) async throws {
        let bucket = client.storage.from("scout-media")

        for photoData in photos {
            let photoId = UUID().uuidString
            let path = "circles/\(circleId)/visits/\(visitId)/\(photoId).jpg"

            _ = try await bucket.upload(
                path,
                data: photoData,
                options: FileOptions(contentType: "image/jpeg")
            )

            struct MediaInsert: Encodable {
                let restaurantId: UUID
                let visitId: UUID
                let circleId: UUID
                let userId: UUID
                let storagePath: String
                let mediaType: String
                enum CodingKeys: String, CodingKey {
                    case restaurantId = "restaurant_id"
                    case visitId      = "visit_id"
                    case circleId     = "circle_id"
                    case userId       = "user_id"
                    case storagePath  = "storage_path"
                    case mediaType    = "media_type"
                }
            }

            try await client
                .from("media")
                .insert(MediaInsert(
                    restaurantId: restaurantId,
                    visitId: visitId,
                    circleId: circleId,
                    userId: userId,
                    storagePath: path,
                    mediaType: "photo"
                ))
                .execute()
        }
    }

    // MARK: - Profiles

    func fetchOrCreateProfile(userId: UUID, displayName: String?, initials: String) async throws {
        // Upsert — creates on first sign-in, no-ops on subsequent
        let payload: [String: String] = [
            "id":           userId.uuidString,
            "initials":     initials,
            "display_name": displayName ?? initials,
        ]
        try await client
            .from("profiles")
            .upsert(payload)
            .execute()
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeNullable<T: Encodable>(_ value: T?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }
}
