import Foundation

struct Visit: Identifiable, Codable {
    let id: UUID
    var restaurantId: UUID
    var circleId: UUID
    var userId: UUID
    var visitedAt: Date
    var notes: String?
    var rating: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, notes, rating
        case restaurantId = "restaurant_id"
        case circleId     = "circle_id"
        case userId       = "user_id"
        case visitedAt    = "visited_at"
        case createdAt    = "created_at"
    }

    init(id: UUID = UUID(),
         restaurantId: UUID,
         circleId: UUID,
         userId: UUID,
         visitedAt: Date = Date(),
         notes: String? = nil,
         rating: Double? = nil,
         createdAt: Date = Date()) {
        self.id           = id
        self.restaurantId = restaurantId
        self.circleId     = circleId
        self.userId       = userId
        self.visitedAt    = visitedAt
        self.notes        = notes
        self.rating       = rating
        self.createdAt    = createdAt
    }
}
