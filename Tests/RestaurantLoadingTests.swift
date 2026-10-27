import Foundation

// Service-free host for the production AppState loading extension. Deferred responses
// make fetch/enrichment races deterministic without credentials or timing assumptions.
@MainActor final class AppState {
    struct User { let id: UUID }
    struct Circle { let id: UUID; var restaurantCount = 0; var visitedCount = 0 }
    var isAuthenticated = true
    var currentUser: User? = User(id: UUID())
    var activeCircle: Circle?
    var circles: [Circle] = []
    var restaurants: [Restaurant] = [] { didSet { restaurantsRevision += 1 } }
    var restaurantsRevision: UInt64 = 0
    var restaurantLoadRequestId = UUID()
    var isLoadingRestaurants = false
    let supabase = DeferredDatabase()
    let places = DeferredPlaces()
    init() { activeCircle = Circle(id: UUID()); circles = [activeCircle!] }
}

@MainActor final class DeferredDatabase {
    var requests: [CheckedContinuation<[Restaurant], Error>] = []
    func fetchRestaurants(circleId: UUID) async throws -> [Restaurant] {
        try await withCheckedThrowingContinuation { requests.append($0) }
    }
    func finish(_ index: Int, _ value: [Restaurant]) { requests[index].resume(returning: value) }
    func fail(_ index: Int) { requests[index].resume(throwing: URLError(.notConnectedToInternet)) }
}

@MainActor final class DeferredPlaces {
    var pending: [UUID: CheckedContinuation<Restaurant?, Never>] = [:]
    var started: [UUID] = []
    var active = 0
    var peak = 0
    func enrichGoogleRestaurants(_ restaurants: [Restaurant], shouldContinue: @escaping @MainActor () -> Bool) async -> [Restaurant] {
        await RestaurantEnrichment.refresh(restaurants, shouldContinue: shouldContinue) { row in
            self.active += 1
            self.peak = max(self.peak, self.active)
            self.started.append(row.id)
            let result: Restaurant? = await withCheckedContinuation { self.pending[row.id] = $0 }
            self.active -= 1
            return result
        }
    }
    func finish(_ row: Restaurant, succeeds: Bool = true) {
        var enriched = row
        enriched.address = "Refreshed address"
        enriched.latitude = 40
        enriched.longitude = -74
        pending.removeValue(forKey: row.id)!.resume(returning: succeeds ? enriched : nil)
    }
}

@main struct RestaurantLoadingTests {
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10_000 {
            if condition() { return }
            await Task.yield()
        }
        preconditionFailure("Deferred operation did not reach expected state")
    }
    @MainActor static func row(_ state: AppState, google: Bool = true) -> Restaurant {
        Restaurant(circleId: state.activeCircle!.id, name: UUID().uuidString,
                   address: "Saved address", googlePlaceId: google ? UUID().uuidString : nil)
    }
    @MainActor static func main() async {
        // Saved rows become usable before ANY Places response, then a sliding window of
        // three requests completes out of order without reordering or dropping failures.
        let state = AppState()
        var rows = (0..<8).map { _ in row(state) }
        rows.insert(row(state, google: false), at: 2)
        rows[8].status = .visited
        let task = Task { await state.loadRestaurants() }
        await wait { state.supabase.requests.count == 1 }
        precondition(state.isLoadingRestaurants)
        state.supabase.finish(0, rows)
        await wait { state.places.started.count == 3 }
        precondition(state.restaurants == rows && !state.isLoadingRestaurants)
        precondition(state.circles[0].restaurantCount == 8 && state.circles[0].visitedCount == 1)
        let googleRows = rows.filter { $0.googlePlaceId != nil }
        // Complete newest pending first to force out-of-order completion.
        for _ in googleRows.indices {
            await wait { !state.places.pending.isEmpty }
            let candidate = googleRows.last { state.places.pending[$0.id] != nil }!
            state.places.finish(candidate, succeeds: candidate.id != googleRows[0].id)
            await Task.yield()
        }
        await task.value
        precondition(state.places.peak == 3 && state.places.started.count == 8)
        precondition(state.restaurants.map(\.id) == rows.map(\.id))
        precondition(state.restaurants[0].address == "Saved address")
        precondition(state.restaurants[2] == rows[2])
        precondition(state.restaurants[1].address == "Refreshed address")
        print("PASS saved data before Places, bounded parallelism, out-of-order completion, stable ordering, non-Google skip, failure fallback, counts")

        // Confirmed changes made while details refresh must survive its eventual result.
        let edited = AppState()
        let originals = (0..<3).map { _ in row(edited) }
        let adding = row(edited, google: false)
        let refresh = Task { await edited.loadRestaurants() }
        await wait { edited.supabase.requests.count == 1 }
        edited.supabase.finish(0, originals)
        await wait { edited.places.started.count == 3 }
        edited.restaurants[0].name = "User edit"
        edited.restaurants[0].status = .visited
        edited.restaurants[0].notes = "Keep my note"
        edited.restaurants.remove(at: 1)
        edited.restaurants.insert(adding, at: 0)
        for original in originals { edited.places.finish(original) }
        await refresh.value
        precondition(edited.restaurants.map(\.id) == [adding.id, originals[0].id, originals[2].id])
        precondition(edited.restaurants[1].name == "User edit" && edited.restaurants[1].status == .visited)
        precondition(edited.restaurants[1].notes == "Keep my note" && edited.restaurants[1].address == "Saved address")
        precondition(edited.restaurants[2].address == "Refreshed address")
        print("PASS edits, visited status, notes, additions and deletions survive delayed enrichment")

        // A local write that completes during the database read wins over that old snapshot.
        let changed = AppState()
        let local = row(changed, google: false)
        let reading = Task { await changed.loadRestaurants() }
        await wait { changed.supabase.requests.count == 1 }
        changed.restaurants = [local]
        changed.supabase.finish(0, [])
        await reading.value
        precondition(changed.restaurants == [local] && !changed.isLoadingRestaurants)

        // Latest request owns results AND loading state, even when the old one finishes first.
        let overlap = AppState()
        let first = Task { await overlap.loadRestaurants() }
        await wait { overlap.supabase.requests.count == 1 }
        let second = Task { await overlap.loadRestaurants() }
        await wait { overlap.supabase.requests.count == 2 }
        overlap.supabase.finish(0, [row(overlap, google: false)])
        await first.value
        precondition(overlap.restaurants.isEmpty && overlap.isLoadingRestaurants)
        let latest = row(overlap, google: false)
        overlap.supabase.finish(1, [latest])
        await second.value
        precondition(overlap.restaurants == [latest] && !overlap.isLoadingRestaurants)

        // A temporary refresh failure preserves already loaded data.
        let offline = Task { await overlap.loadRestaurants() }
        await wait { overlap.supabase.requests.count == 3 }
        overlap.supabase.fail(2)
        await offline.value
        precondition(overlap.restaurants == [latest] && !overlap.isLoadingRestaurants)
        print("PASS writes during fetch, overlapping refreshes/loading ownership, offline refresh preservation")

        for mode in ["circle", "signout", "user", "cancel", "roundtrip"] {
            let scoped = AppState()
            let originals = (0..<9).map { _ in row(scoped) }
            let loading = Task { await scoped.loadRestaurants() }
            await wait { scoped.supabase.requests.count == 1 }
            scoped.supabase.finish(0, originals)
            await wait { scoped.places.started.count == 3 }
            switch mode {
            case "circle": scoped.activeCircle = .init(id: UUID())
            case "signout": scoped.isAuthenticated = false
            case "user": scoped.currentUser = .init(id: UUID())
            case "roundtrip": scoped.invalidateRestaurantLoads()
            default: loading.cancel()
            }
            scoped.restaurants = [] // lifecycle clears the old circle in the real AppState
            for original in originals.prefix(3) { scoped.places.finish(original) }
            await loading.value
            precondition(scoped.restaurants.isEmpty && scoped.places.started.count == 3)
        }
        let invalidated = AppState()
        let invalidatedTask = Task { await invalidated.loadRestaurants() }
        await wait { invalidated.supabase.requests.count == 1 }
        invalidated.invalidateRestaurantLoads() // circle A -> B -> A still invalidates A's old read
        invalidated.supabase.finish(0, [row(invalidated, google: false)])
        await invalidatedTask.value
        precondition(invalidated.restaurants.isEmpty && !invalidated.isLoadingRestaurants)

        for mode in ["circle", "signout", "user", "cancel"] {
            let scoped = AppState()
            let reading = Task { await scoped.loadRestaurants() }
            await wait { scoped.supabase.requests.count == 1 }
            switch mode {
            case "circle": scoped.activeCircle = .init(id: UUID())
            case "signout": scoped.isAuthenticated = false
            case "user": scoped.currentUser = .init(id: UUID())
            default: reading.cancel()
            }
            scoped.supabase.finish(0, [row(scoped)])
            await reading.value
            precondition(scoped.restaurants.isEmpty && scoped.places.started.isEmpty)
        }
        let cancelled = AppState()
        let many = (0..<9).map { _ in row(cancelled) }
        let cancelling = Task { await cancelled.loadRestaurants() }
        await wait { cancelled.supabase.requests.count == 1 }
        cancelled.supabase.finish(0, many)
        await wait { cancelled.places.started.count == 3 }
        cancelling.cancel()
        for original in many.prefix(3) { cancelled.places.finish(original) }
        await cancelling.value
        precondition(cancelled.places.started.count == 3 && cancelled.restaurants == many)
        print("PASS circle/auth/user isolation, cancellation, and no new Places requests after cancellation")
    }
}
