import Foundation
#if canImport(Supabase)
import Supabase
#endif

extension AppState {
    func invalidateRestaurantLoads() {
        restaurantLoadRequestId = UUID()
        restaurants = []
        isLoadingRestaurants = false
    }

    func loadRestaurants() async {
        guard isAuthenticated, let userId = currentUser?.id,
              let circleId = activeCircle?.id, !Task.isCancelled else { return }
        let requestId = UUID()
        restaurantLoadRequestId = requestId
        let initialRevision = restaurantsRevision
        func isCurrent() -> Bool {
            !Task.isCancelled && isAuthenticated && currentUser?.id == userId
                && activeCircle?.id == circleId && restaurantLoadRequestId == requestId
        }
        isLoadingRestaurants = true
        defer {
            if restaurantLoadRequestId == requestId { isLoadingRestaurants = false }
        }
        do {
            let fetched = try await supabase.fetchRestaurants(circleId: circleId)
            // A confirmed add/edit/delete during this request takes precedence over its snapshot.
            guard isCurrent(), restaurantsRevision == initialRevision else { return }
            restaurants = fetched
            isLoadingRestaurants = false
            if let index = circles.firstIndex(where: { $0.id == circleId }) {
                circles[index].restaurantCount = fetched.filter { $0.status == .wantToTry }.count
                circles[index].visitedCount = fetched.filter { $0.status == .visited }.count
            }

            // Show saved places before optional Google details finish. Merge only unchanged rows:
            // enrichment must never resurrect a deletion or overwrite an edit/visit/new addition.
            let enriched = await places.enrichGoogleRestaurants(fetched, shouldContinue: isCurrent)
            guard isCurrent() else { return }
            let originals = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            let updates = Dictionary(uniqueKeysWithValues: enriched.map { ($0.id, $0) })
            restaurants = restaurants.map { current in
                guard current == originals[current.id] else { return current }
                return updates[current.id] ?? current
            }
        } catch {
            // Keep already loaded places usable through a temporary refresh failure.
        }
    }
}
