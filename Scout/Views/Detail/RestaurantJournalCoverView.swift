import SwiftUI
import Supabase

struct RestaurantJournalCoverView: View {
    let restaurant: Restaurant
    let openJournal: () -> Void
    @Environment(AppState.self) private var appState
    @State private var state = RestaurantCoverLoadState()
    @State private var retryId = 0
    @State private var loadingRequest: Request?

    private var candidates: [Media] {
        guard appState.isAuthenticated, appState.currentUser != nil,
              appState.activeCircle?.id == restaurant.circleId else { return [] }
        return RestaurantJournalCover.candidates(restaurantId: restaurant.id,
            circleId: restaurant.circleId, media: appState.media)
    }

    private struct Request: Hashable {
        let userId: UUID?
        let circleId: UUID?
        let restaurantId: UUID
        let photos: [RestaurantJournalCover.PhotoKey]
        let retryId: Int
    }

    private var request: Request {
        Request(userId: appState.isAuthenticated ? appState.currentUser?.id : nil,
                circleId: appState.activeCircle?.id, restaurantId: restaurant.id,
                photos: candidates.map(RestaurantJournalCover.PhotoKey.init), retryId: retryId)
    }

    var body: some View {
        let scope = request
        let photos = candidates
        let current = loadingRequest == scope
        return RestaurantCoverImage(image: current ? state.image(matching: photos) : nil, restaurantName: restaurant.name,
            isLoading: (current && state.isLoading) || (!current && !photos.isEmpty) || appState.isLoadingJournal,
            failed: current && state.failed,
            retry: { retryId += 1 }, openJournal: openJournal)
            .task(id: scope) {
                guard !Task.isCancelled else { return }
                loadingRequest = scope
                await state.load(candidates: photos) { media in
                    await appState.mediaService.coverImage(for: media, supabase: appState.supabase)
                }
            }
    }
}
