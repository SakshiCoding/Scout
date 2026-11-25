import SwiftUI
import Supabase

struct RestaurantJournalCoverView: View {
    let restaurant: Restaurant
    let openJournal: () -> Void
    @Environment(AppState.self) private var appState
    @State private var state = RestaurantCoverLoadState()
    @State private var googleState = PlacePhotoLoadState()
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
        let placeId: String?
        let journalLoading: Bool
        let retryId: Int
    }

    private var request: Request {
        Request(userId: appState.isAuthenticated ? appState.currentUser?.id : nil,
                circleId: appState.activeCircle?.id, restaurantId: restaurant.id,
                photos: candidates.map { RestaurantJournalCover.PhotoKey($0) },
                placeId: restaurant.googlePlaceId, journalLoading: appState.isLoadingJournal, retryId: retryId)
    }

    var body: some View {
        let scope = request
        let photos = candidates
        let current = loadingRequest == scope
        let journalImage = current ? state.image(matching: photos) : nil
        let googlePhoto = current && journalImage == nil ? googleState.photo : nil
        return VStack(spacing: 0) {
            RestaurantCoverImage(image: journalImage ?? googlePhoto?.image, restaurantName: restaurant.name,
                isLoading: (current && (state.isLoading || googleState.isLoading)) || !current || scope.journalLoading,
                failed: current && (state.failed || googleState.failed),
                retry: { retryId += 1 }, openJournal: journalImage == nil ? nil : openJournal,
                imageDescription: googlePhoto == nil ? nil : "Google photo of \(restaurant.name)")
            if let googlePhoto { PlacePhotoCredits(photo: googlePhoto) }
        }
        .task(id: scope) {
            guard !Task.isCancelled else { return }
            loadingRequest = scope
            await googleState.load(placeId: nil) { _ in nil }
            guard scope.userId != nil, scope.circleId == restaurant.circleId else { return }
            await state.load(candidates: photos) { media in
                await appState.mediaService.coverImage(for: media, supabase: appState.supabase)
            }
            guard !Task.isCancelled, loadingRequest == scope,
                  state.image(matching: photos) == nil, !scope.journalLoading else { return }
            await googleState.load(placeId: scope.placeId) { await PlacesService.shared.photo(placeId: $0) }
        }
    }
}
