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
        // PostgREST returns ISO 8601 with timezone, sometimes with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
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

        enum CodingKeys: String, CodingKey {
            case restaurantCircleId  = "restaurant_circle_id"
            case restaurantName      = "restaurant_name"
            case restaurantCuisine   = "restaurant_cuisine"
            case restaurantPriceTier = "restaurant_price_tier"
            case restaurantAddress   = "restaurant_address"
            case restaurantLatitude  = "restaurant_latitude"
            case restaurantLongitude = "restaurant_longitude"
            case restaurantNotes     = "restaurant_notes"
            case restaurantVibeTags  = "restaurant_vibe_tags"
            case restaurantRating    = "restaurant_rating"
            case restaurantPhotoUrl  = "restaurant_photo_url"
        }
    }

    private struct GetCircleRestaurantsParams: Encodable {
        let targetCircleId: UUID

        enum CodingKeys: String, CodingKey {
            case targetCircleId = "target_circle_id"
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
                    restaurantPhotoUrl: restaurant.photoUrl
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
        try await client
            .from("restaurants")
            .update(restaurant)
            .eq("id", value: restaurant.id)
            .execute()
    }

    func markVisited(_ restaurantId: UUID) async throws {
        try await client
            .from("restaurants")
            .update(["status": "visited"])
            .eq("id", value: restaurantId)
            .execute()
    }

    // MARK: - Visits

    func addVisit(_ visit: Visit) async throws -> Visit {
        try await client
            .from("visits")
            .insert(visit)
            .select()
            .single()
            .execute()
            .value
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
