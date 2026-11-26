import Foundation
import Observation

@MainActor @Observable final class RestaurantDiscoveryState {
    private(set) var results: [PlaceSearchResult] = []
    private(set) var isLoading = false
    private(set) var didSearch = false
    private var requestId = UUID()

    func load(
        query: String, delay: Duration = .milliseconds(300),
        fetch: (String) async -> [PlaceSearchResult]
    ) async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        requestId = id
        results = []
        didSearch = false
        isLoading = false
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2, !Task.isCancelled else { return }
        isLoading = true
        defer { if requestId == id { isLoading = false } }
        do { try await Task.sleep(for: delay) } catch { return }
        guard !Task.isCancelled, requestId == id else { return }
        let fetched = await fetch(query)
        guard !Task.isCancelled, requestId == id else { return }
        var seen = Set<String>()
        results = fetched.filter { seen.insert("\($0.provider)-\($0.id)").inserted }
        didSearch = true
    }
}
