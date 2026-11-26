import Foundation

@MainActor private final class PendingSearch {
    var requests: [CheckedContinuation<[PlaceSearchResult], Never>] = []
    func fetch() async -> [PlaceSearchResult] { await withCheckedContinuation { requests.append($0) } }
}
@main struct RestaurantDiscoveryTests {
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Search never started")
    }
    @MainActor static func main() async {
        let circle = UUID(), otherCircle = UUID()
        let place = PlaceSearchResult(id: "google-one", provider: .google, name: "Café Hagen", address: "123 Main St",
            latitude: 47.61, longitude: -122.33, googlePlaceId: "google-one", primaryType: "cafe",
            establishmentType: .cafe, cuisine: nil, priceTier: .two, vibeHints: ["Casual"])
        let saved = Restaurant(circleId: circle, name: "An edited name", googlePlaceId: "google-one")
        precondition(SavedPlaceMatch.restaurant(for: place, in: [saved], circleId: circle)?.id == saved.id)
        precondition(SavedPlaceMatch.restaurant(for: place, in: [saved], circleId: otherCircle) == nil)
        precondition(SavedPlaceMatch.restaurant(for: place, in: [saved], circleId: nil) == nil)
        var manual = saved; manual.googlePlaceId = nil; manual.name = "Cafe Hagen"; manual.address = "123 MAIN ST."
        precondition(SavedPlaceMatch.restaurant(for: place, in: [manual], circleId: circle)?.id == manual.id)
        manual.address = nil
        precondition(SavedPlaceMatch.restaurant(for: place, in: [manual], circleId: circle) == nil)
        manual.latitude = 47.61; manual.longitude = -122.33
        precondition(SavedPlaceMatch.restaurant(for: place, in: [manual], circleId: circle)?.id == manual.id)
        manual.latitude = 48.0
        precondition(SavedPlaceMatch.restaurant(for: place, in: [manual], circleId: circle) == nil)
        manual.googlePlaceId = "different-google-id"; manual.latitude = 47.61; manual.address = "123 Main St"
        precondition(SavedPlaceMatch.restaurant(for: place, in: [manual], circleId: circle) == nil)
        print("PASS saved-result routing by Place ID, exact name/address or nearby coordinates, chain-location separation, unknown manual locations and circle isolation")
        let state = RestaurantDiscoveryState(), pending = PendingSearch()
        await state.load(query: "x", delay: .zero) { _ in preconditionFailure("Short query fetched") }
        precondition(!state.isLoading && state.results.isEmpty && !state.didSearch)
        let old = Task { await state.load(query: "old", delay: .zero) { _ in await pending.fetch() } }
        await wait { pending.requests.count == 1 }
        let latest = Task { await state.load(query: "new", delay: .zero) { _ in await pending.fetch() } }
        await wait { pending.requests.count == 2 }
        pending.requests[0].resume(returning: [place]); await old.value
        precondition(state.results.isEmpty && state.isLoading)
        pending.requests[1].resume(returning: [place,place]); await latest.value
        precondition(state.results.count == 1 && state.didSearch && !state.isLoading)
        let abandoned = Task { await state.load(query: "abandoned", delay: .zero) { _ in preconditionFailure("Pre-canceled search ran") } }
        abandoned.cancel(); await abandoned.value
        precondition(state.results.count == 1 && state.didSearch && !state.isLoading)
        let revoked = Task { await state.load(query: "query", delay: .zero) { _ in await pending.fetch() } }
        await wait { pending.requests.count == 3 }
        await state.load(query: "", delay: .zero) { _ in preconditionFailure() }
        pending.requests[2].resume(returning: [place]); await revoked.value
        precondition(state.results.isEmpty && !state.isLoading)
        let canceled = Task { await state.load(query: "query", delay: .zero) { _ in await pending.fetch() } }
        await wait { pending.requests.count == 4 }
        canceled.cancel(); pending.requests[3].resume(returning: [place]); await canceled.value
        precondition(state.results.isEmpty && !state.isLoading)
        let debounce = Task { await state.load(query: "rapid typing", delay: .seconds(10)) { _ in preconditionFailure("Canceled debounce fetched") } }
        await wait { state.isLoading }
        debounce.cancel(); await debounce.value
        await state.load(query: "offline or unknown", delay: .zero) { _ in [] }
        precondition(state.results.isEmpty && state.didSearch && !state.isLoading)
        print("PASS minimum query length, debounce cancellation, duplicate result IDs, latest-only publication, clearing scope/query, canceled responses and empty/offline fallback")
    }
}
