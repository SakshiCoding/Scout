import Foundation

/// Keep Places traffic bounded while preserving the saved wishlist order and fallback data.
@MainActor
enum RestaurantEnrichment {
    static func refresh(
        _ restaurants: [Restaurant],
        shouldContinue: @escaping @MainActor () -> Bool = { true },
        fetch: @escaping @MainActor (Restaurant) async -> Restaurant?
    ) async -> [Restaurant] {
        let indices = restaurants.indices.filter { restaurants[$0].googlePlaceId != nil }
        guard !indices.isEmpty, !Task.isCancelled, shouldContinue() else { return restaurants }
        return await withTaskGroup(of: (Int, Restaurant?).self) { group in
            var result = restaurants
            var next = indices.makeIterator()
            func enqueue(_ index: Int) {
                group.addTask { @MainActor in
                    guard !Task.isCancelled, shouldContinue() else { return (index, nil) }
                    return (index, await fetch(restaurants[index]))
                }
            }
            for _ in 0..<3 {
                if let index = next.next() { enqueue(index) }
            }
            while let (index, enriched) = await group.next() {
                guard !Task.isCancelled, shouldContinue() else { group.cancelAll(); break }
                if let enriched { result[index] = enriched }
                if let index = next.next() { enqueue(index) }
            }
            return result
        }
    }
}
