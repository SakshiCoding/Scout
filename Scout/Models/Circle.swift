import Foundation
import SwiftUI

struct ScoutCircle: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var shortName: String?
    var accentColor: String
    let createdAt: Date
    var members: [CircleMember]

    // Populated after fetching restaurants — not DB columns
    var restaurantCount: Int = 0
    var visitedCount: Int = 0
    var photoCount: Int = 0

    var accentSwiftUIColor: Color { Color(hex: accentColor) }
    var displayShortName: String { shortName ?? name }

    enum CodingKeys: String, CodingKey {
        case id, name
        case shortName   = "short_name"
        case accentColor = "accent_color"
        case createdAt   = "created_at"
        case members     = "circle_members"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        name        = try c.decode(String.self, forKey: .name)
        shortName   = try c.decodeIfPresent(String.self, forKey: .shortName)
        accentColor = try c.decodeIfPresent(String.self, forKey: .accentColor) ?? "#CC5500"
        createdAt   = try c.decode(Date.self,   forKey: .createdAt)
        members     = (try? c.decodeIfPresent([CircleMember].self, forKey: .members)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,          forKey: .id)
        try c.encode(name,        forKey: .name)
        try c.encodeIfPresent(shortName,   forKey: .shortName)
        try c.encode(accentColor, forKey: .accentColor)
        try c.encode(createdAt,   forKey: .createdAt)
    }

    // Direct initializer for mock data and local creation
    init(id: UUID = UUID(),
         name: String,
         shortName: String? = nil,
         accentColor: String = "#CC5500",
         createdAt: Date = Date(),
         members: [CircleMember] = [],
         restaurantCount: Int = 0,
         visitedCount: Int = 0,
         photoCount: Int = 0) {
        self.id              = id
        self.name            = name
        self.shortName       = shortName
        self.accentColor     = accentColor
        self.createdAt       = createdAt
        self.members         = members
        self.restaurantCount = restaurantCount
        self.visitedCount    = visitedCount
        self.photoCount      = photoCount
    }
}

struct CircleMember: Codable, Hashable {
    let circleId: UUID
    let userId: UUID
    var initials: String

    enum CodingKeys: String, CodingKey {
        case circleId = "circle_id"
        case userId   = "user_id"
        case initials
    }
}
