import Foundation
import Supabase

extension SupabaseService {
    private struct InviteParams: Encodable {
        let p_action: String
        var p_circle_id: UUID?
        var p_code: String?
        var p_invite_id: UUID?
        var p_initials: String?
    }

    func circleInvitation(action: String, circleId: UUID, inviteId: UUID? = nil) async throws -> CircleInvitation {
        let response = try await client.rpc("scout_circle_invite", params:
            InviteParams(p_action: action, p_circle_id: circleId, p_invite_id: inviteId)).execute()
        return try Self.decoder.decode(CircleInvitation.self, from: response.data)
    }

    func previewInvitation(_ code: CircleInviteCode) async throws -> CircleInvitePreview {
        let response = try await client.rpc("scout_circle_invite", params:
            InviteParams(p_action: "preview", p_code: code.value)).execute()
        return try Self.decoder.decode(CircleInvitePreview.self, from: response.data)
    }

    func acceptInvitation(_ code: CircleInviteCode, initials: String) async throws -> CircleInvitePreview {
        let response = try await client.rpc("scout_circle_invite", params:
            InviteParams(p_action: "join", p_code: code.value, p_initials: initials)).execute()
        return try Self.decoder.decode(CircleInvitePreview.self, from: response.data)
    }
}
