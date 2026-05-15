import Foundation

struct Media: Identifiable, Codable {
    let id: UUID
    var restaurantId: UUID?
    var visitId: UUID?
    var circleId: UUID
    var userId: UUID
    var storagePath: String
    var mediaType: MediaType
    let createdAt: Date

    enum MediaType: String, Codable {
        case photo, video
    }

    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case visitId      = "visit_id"
        case circleId     = "circle_id"
        case userId       = "user_id"
        case storagePath  = "storage_path"
        case mediaType    = "media_type"
        case createdAt    = "created_at"
    }
}
