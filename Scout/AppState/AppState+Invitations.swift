import Foundation
import Supabase

extension AppState {
    func joinCircle(using code: CircleInviteCode) async throws {
        guard let userId = currentUser?.id, isAuthenticated else { throw CancellationError() }
        let initials = currentUser?.email.map { String($0.prefix(2).uppercased()) } ?? "?"
        let result = try await supabase.acceptInvitation(code, initials: initials)
        guard !Task.isCancelled, isAuthenticated, currentUser?.id == userId else { throw CancellationError() }
        invalidateCircleLoads()
        let fetched = try await supabase.fetchCircles(for: userId)
        guard !Task.isCancelled, isAuthenticated, currentUser?.id == userId else { throw CancellationError() }
        guard let circle = fetched.first(where: { $0.id == result.circleId }) else {
            throw URLError(.badServerResponse)
        }
        // Keep existing counts while refreshing authoritative member lists.
        circles = fetched.map { circle in
            var updated = circle
            if let old = circles.first(where: { $0.id == circle.id }) {
                updated.restaurantCount = old.restaurantCount
                updated.visitedCount = old.visitedCount
                updated.photoCount = old.photoCount
            }
            return updated
        }
        switchCircle(to: circle)
        navigate(to: .wishlist)
        if pendingCircleInvite?.value == code.value { pendingCircleInvite = nil }
    }
}
