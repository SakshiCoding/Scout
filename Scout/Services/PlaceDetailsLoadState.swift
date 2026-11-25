import Foundation
import Observation

@MainActor @Observable
final class PlaceDetailsLoadState {
    private(set) var details: PlaceContactDetails?
    private(set) var isLoading = false
    private(set) var failed = false
    private var requestId = UUID()

    func load(placeId: String?, fetch: (String) async -> PlaceContactDetails?) async {
        let id = UUID()
        requestId = id
        details = nil
        failed = false
        isLoading = false
        guard let placeId, !placeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !Task.isCancelled else { return }
        isLoading = true
        defer { if requestId == id { isLoading = false } }
        let result = await fetch(placeId)
        guard !Task.isCancelled, requestId == id else { return }
        details = result
        failed = result == nil
    }
}
