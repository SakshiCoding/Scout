import Foundation

/// Bounds live photo lookups across visible wishlist rows and detail screens.
@MainActor final class PlacePhotoRequestQueue {
    private var active = 0
    private var waiting: [CheckedContinuation<Void, Never>] = []
    private let limit: Int
    init(limit: Int = 2) { self.limit = max(1, limit) }

    func run(_ work: () async -> PlacePhoto?) async -> PlacePhoto? {
        guard !Task.isCancelled else { return nil }
        if active < limit { active += 1 } else { await withCheckedContinuation { waiting.append($0) } }
        defer {
            if waiting.isEmpty { active -= 1 } else { waiting.removeFirst().resume() }
        }
        guard !Task.isCancelled else { return nil }
        return await work()
    }
}
