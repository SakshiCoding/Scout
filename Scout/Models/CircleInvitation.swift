import Foundation

struct CircleInviteCode: Identifiable, Equatable {
    let id = UUID()
    let value: String

    init?(_ text: String) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate: String
        if let url = URLComponents(string: input), url.scheme != nil {
            guard url.scheme?.lowercased() == "scout", url.host?.lowercased() == "join",
                  url.user == nil, url.password == nil, url.port == nil,
                  url.path.isEmpty, url.fragment == nil,
                  let items = url.queryItems, items.count == 1,
                  items[0].name == "code", let code = items[0].value else { return nil }
            candidate = code
        } else { candidate = input }
        guard candidate.count == 32, candidate.utf8.allSatisfy({
            (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
        }) else { return nil }
        value = candidate.lowercased()
    }

    var url: URL { URL(string: "scout://join?code=\(value)")! }
}

struct CircleInvitation: Decodable {
    let id: UUID?
    let circleId: UUID
    let circleName: String
    let isActive: Bool
    let expiresAt: Date?
    let code: String?
    enum CodingKeys: String, CodingKey {
        case id, code
        case circleId = "circle_id", circleName = "circle_name"
        case isActive = "is_active", expiresAt = "expires_at"
    }
}

struct CircleInvitePreview: Decodable {
    let circleId: UUID
    let circleName: String
    let expiresAt: Date
    let isMember: Bool
    enum CodingKeys: String, CodingKey {
        case circleId = "circle_id", circleName = "circle_name"
        case expiresAt = "expires_at", isMember = "is_member"
    }
}
