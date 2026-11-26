import Foundation
import Observation

@MainActor @Observable
final class PlacePhotoLoadState {
    private(set) var photo: PlacePhoto?
    private(set) var isLoading = false
    private(set) var failed = false
    private var requestId = UUID()

    func load(placeId: String?, fetch: (String) async -> PlacePhoto?) async {
        let id = UUID()
        requestId = id
        photo = nil
        failed = false
        isLoading = false
        guard let placeId, !placeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !Task.isCancelled else { return }
        isLoading = true
        defer { if requestId == id { isLoading = false } }
        let result = await fetch(placeId)
        guard !Task.isCancelled, requestId == id else { return }
        photo = result
        failed = result == nil
    }
}
