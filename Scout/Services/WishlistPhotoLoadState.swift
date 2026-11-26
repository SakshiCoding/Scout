import CoreGraphics
import Foundation
import Observation

@MainActor @Observable final class WishlistPhotoLoadState {
    private(set) var image: CGImage?
    private(set) var googlePhoto: PlacePhoto?
    private(set) var isLoading = false
    private var requestId = UUID()

    func clear() {
        requestId = UUID()
        image = nil
        googlePhoto = nil
        isLoading = false
    }

    func load(
        candidates: [Media], placeId: String?,
        journal: (Media) async -> CGImage?, google: (String) async -> PlacePhoto?
    ) async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        requestId = id
        image = nil
        googlePhoto = nil
        isLoading = true
        defer { if requestId == id { isLoading = false } }
        guard !Task.isCancelled else { return }
        for candidate in candidates.prefix(3) {
            let result = await journal(candidate)
            guard !Task.isCancelled, requestId == id else { return }
            if let result {
                image = result
                return
            }
        }
        guard let placeId, !placeId.isEmpty else { return }
        let result = await google(placeId)
        guard !Task.isCancelled, requestId == id else { return }
        googlePhoto = result
        image = result?.image
    }
}
