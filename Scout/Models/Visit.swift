import Foundation

struct Visit: Identifiable, Codable {
    let id: UUID
    var restaurantId: UUID
    var circleId: UUID
    var userId: UUID
    var visitedAt: Date
    var notes: String?
    var rating: Double?
    var occasion: String?
    var vibeTags: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, notes, rating, occasion
        case restaurantId = "restaurant_id"
        case circleId     = "circle_id"
        case userId       = "user_id"
        case visitedAt    = "visited_at"
        case vibeTags     = "vibe_tags"
        case createdAt    = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self, forKey: .id)
        restaurantId = try c.decode(UUID.self, forKey: .restaurantId)
        circleId     = try c.decode(UUID.self, forKey: .circleId)
        userId       = try c.decode(UUID.self, forKey: .userId)
        visitedAt    = try c.decode(Date.self, forKey: .visitedAt)
        notes        = try c.decodeIfPresent(String.self, forKey: .notes)
        rating       = try c.decodeIfPresent(Double.self, forKey: .rating)
        occasion     = try c.decodeIfPresent(String.self, forKey: .occasion)
        vibeTags     = try c.decodeIfPresent([String].self, forKey: .vibeTags) ?? []
        createdAt    = try c.decode(Date.self, forKey: .createdAt)
    }

    init(id: UUID = UUID(),
         restaurantId: UUID,
         circleId: UUID,
         userId: UUID,
         visitedAt: Date = Date(),
         notes: String? = nil,
         rating: Double? = nil,
         occasion: String? = nil,
         vibeTags: [String] = [],
         createdAt: Date = Date()) {
        self.id           = id
        self.restaurantId = restaurantId
        self.circleId     = circleId
        self.userId       = userId
        self.visitedAt    = visitedAt
        self.notes        = notes
        self.rating       = rating
        self.occasion     = occasion
        self.vibeTags     = vibeTags
        self.createdAt    = createdAt
    }
}
