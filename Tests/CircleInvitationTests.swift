import Foundation

@main private struct CircleInvitationTests {
    static func main() throws {
        let raw = "0123456789abcdef0123456789abcdef"
        let code = CircleInviteCode(raw)!
        precondition(CircleInviteCode(code.url.absoluteString)?.value == raw)
        precondition(CircleInviteCode(" \n\(raw.uppercased())\n")?.value == raw)
        for bad in ["", String(raw.dropLast()), raw+"0", String(repeating:"z",count:32),
                    "https://join?code=\(raw)", "scout://join?code=\(raw)&code=\(raw)",
                    "scout://join/path?code=\(raw)", "scout://user@join?code=\(raw)",
                    "scout://join:80?code=\(raw)", "scout://join?code=\(raw)#fragment",
                    "scout://password-reset?code=\(raw)", "scout://join?other=\(raw)"] {
            precondition(CircleInviteCode(bad) == nil, "Invalid invitation accepted")
        }
        let data = try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1]))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime,.withFractionalSeconds]
            guard let date = formatter.date(from:value) ?? ISO8601DateFormatter().date(from:value) else {
                throw DecodingError.dataCorrupted(.init(codingPath:decoder.codingPath,debugDescription:"Invalid date"))
            }
            return date
        }
        struct Fixture: Decodable {let invite:CircleInvitation;let preview:CircleInvitePreview;let joined:CircleInvitePreview;let circles:[ScoutCircle];let inactive:CircleInvitation?}
        let fixture = try decoder.decode(Fixture.self,from:data)
        precondition(fixture.invite.isActive && fixture.invite.code != nil && fixture.invite.id != nil)
        if let inactive = fixture.inactive {
            precondition(!inactive.isActive && inactive.id == nil && inactive.code == nil && inactive.expiresAt == nil)
        }
        precondition(!fixture.preview.isMember && fixture.joined.isMember)
        precondition(fixture.circles[0].members.count == 2)
        precondition(fixture.circles[0].id == fixture.joined.circleId)
        let legacyMember = try JSONSerialization.data(withJSONObject: ["circle_id":fixture.joined.circleId.uuidString,
            "user_id":UUID().uuidString,"initials":NSNull()])
        let legacy = try decoder.decode(CircleMember.self, from:legacyMember)
        precondition(legacy.initials == "?")
        print("PASS production invite link validation, malformed/foreign/auth-link rejection, real SQL response decoding, and joined-circle member models")
    }
}
