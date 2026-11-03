import CoreGraphics
import Foundation
import Observation

@MainActor @Observable
final class RestaurantCoverLoadState {
    private(set) var image: CGImage?
    private(set) var selectedMedia: Media?
    private(set) var isLoading = false
    private(set) var failed = false
    private var requestId = UUID()

    func load(candidates: [Media], fetch: (Media) async -> CGImage?) async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        requestId = id
        image = nil
        selectedMedia = nil
        failed = false
        isLoading = !candidates.isEmpty
        defer { if requestId == id { isLoading = false } }
        for candidate in candidates.prefix(3) {
            let fetched = await fetch(candidate)
            guard !Task.isCancelled, requestId == id else { return }
            if let fetched {
                image = fetched
                selectedMedia = candidate
                return
            }
        }
        failed = !candidates.isEmpty
    }

    // Hide a removed/replaced/out-of-scope photo immediately, before the new task starts.
    func image(matching candidates: [Media]) -> CGImage? {
        guard let selectedMedia, candidates.contains(where: {
            $0.id == selectedMedia.id && $0.storagePath == selectedMedia.storagePath
                && $0.circleId == selectedMedia.circleId && $0.restaurantId == selectedMedia.restaurantId
                && $0.mediaType == .photo
        }) else { return nil }
        return image
    }
}
