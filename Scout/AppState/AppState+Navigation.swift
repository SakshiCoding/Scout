import Foundation

extension AppState {
    /// Navigation survives the auth gate; it never creates data, votes, or a match.
    func navigate(to destination: ScoutDestination) {
        if destination == .wishlist {
            activeTab = .wantToTry
            filterState.reset()
        }
        requestedTab = destination.tab
    }
}
