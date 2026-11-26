import Supabase
import SwiftUI

struct WishlistRestaurantRow: View {
    let restaurant: Restaurant
    var refreshId = 0
    let open: () -> Void
    @Environment(AppState.self) private var appState
    @State private var photoState = WishlistPhotoLoadState()
    @State private var loadedRequest: Request?

    private struct Request: Hashable {
        let refreshId: Int
        let user: UUID?
        let circle: UUID?
        let restaurant: UUID
        let photos: [RestaurantJournalCover.PhotoKey]
        let placeId: String?
        let legacyURL: String?
        let loadingJournal: Bool
    }
    private var candidates: [Media] {
        guard appState.isAuthenticated, appState.currentUser != nil,
            appState.activeCircle?.id == restaurant.circleId
        else { return [] }
        return RestaurantJournalCover.candidates(
            restaurantId: restaurant.id,
            circleId: restaurant.circleId, media: appState.media)
    }
    private var request: Request {
        Request(
            refreshId: refreshId, user: appState.isAuthenticated ? appState.currentUser?.id : nil,
            circle: appState.activeCircle?.id, restaurant: restaurant.id,
            photos: candidates.map { RestaurantJournalCover.PhotoKey($0) },
            placeId: restaurant.googlePlaceId, legacyURL: restaurant.photoUrl,
            loadingJournal: appState.isLoadingJournal)
    }

    var body: some View {
        let scope = request
        let current = loadedRequest == scope
        VStack(alignment: .leading, spacing: 0) {
            RestaurantRowView(
                restaurant: restaurant, image: current ? photoState.image : nil,
                isLoading: !current || photoState.isLoading,
                legacyImageURL: current && !photoState.isLoading && scope.user != nil
                    && scope.circle == restaurant.circleId
                    ? restaurant.photoUrl.flatMap { URL(string: $0) }.flatMap { $0.scheme == "https" ? $0 : nil } : nil,
                googlePhoto: current ? photoState.googlePhoto : nil, open: open)
            Rectangle().fill(Atlas.rule).frame(height: 1)
        }
        .onDisappear {
            photoState.clear()
            loadedRequest = nil
        }
        .task(id: scope) {
            guard !Task.isCancelled else { return }
            loadedRequest = scope
            let allowed = scope.user != nil && scope.circle == restaurant.circleId
            await photoState.load(
                candidates: allowed ? candidates : [],
                placeId: allowed && !scope.loadingJournal ? scope.placeId : nil,
                journal: {
                    await appState.mediaService.thumbnail(for: $0, supabase: appState.supabase)?.cgImage
                },
                google: { await PlacesService.shared.photo(placeId: $0, pixelSize: 512) })
        }
    }
}
