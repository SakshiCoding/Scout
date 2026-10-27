import Foundation
import AppIntents

// Service-free dependency for the production intents and navigation extension.
// Auth/network lifecycle is exercised by the app build and manual walkthrough.
@MainActor final class AppState {
    var requestedTab: TabItem?
    var activeTab: WishlistTab = .visited
    var filterState = FilterState(cuisine: "Italian", priceTiers: [.two], vibeTags: ["Date night"], maxDistanceMiles: 5)
}

@main private struct ShortcutTests {
    @MainActor static func main() async throws {
        for destination in ScoutDestination.allCases {
            precondition(ScoutDestination(url: URL(string: "scout://\(destination.rawValue)")!) == destination)
        }
        precondition(ScoutDestination(url: URL(string: "SCOUT://WISHLIST")!) == .wishlist)
        for url in ["https://wishlist", "scout://unknown", "scout://password-reset", "scout://import-pending", "scout:"] {
            precondition(ScoutDestination(url: URL(string: url)!) == nil)
        }
        precondition(ScoutDestination.wishlist.tab == .list)
        precondition(ScoutDestination.pick.tab == .pick)
        precondition(ScoutDestination.journal.tab == .journal)

        let state = AppState()
        // Direct perform() calls do not run Apple's dependency injection flow.
        // Supply the same dependency explicitly, as App Intents does at runtime.
        let wishlist = OpenScoutWishlistIntent()
        wishlist.appState = state
        let picker = OpenScoutPickerIntent()
        picker.appState = state
        let journal = OpenScoutJournalIntent()
        journal.appState = state
        precondition(ScoutShortcuts.appShortcuts.count == 3)
        precondition(OpenScoutWishlistIntent.openAppWhenRun && OpenScoutPickerIntent.openAppWhenRun && OpenScoutJournalIntent.openAppWhenRun)

        _ = try await wishlist.perform()
        precondition(state.requestedTab == .list)
        precondition(state.activeTab == .wantToTry && !state.filterState.isActive)
        state.requestedTab = nil // the existing RootView consumes each request
        state.activeTab = .visited
        state.filterState.cuisine = "Japanese"
        _ = try await picker.perform()
        precondition(state.requestedTab == .pick && state.activeTab == .visited)
        precondition(state.filterState.cuisine == "Japanese")
        _ = try await journal.perform()
        precondition(state.requestedTab == .journal && state.filterState.cuisine == "Japanese")
        state.requestedTab = nil
        _ = try await journal.perform()
        precondition(state.requestedTab == .journal) // repeated invocation is another request
        _ = try await wishlist.perform()
        precondition(state.requestedTab == .list && !state.filterState.isActive)
        print("PASS production App Intents with injected state, three foreground shortcuts, destinations, repeated requests, wishlist reset, and picker/journal filter preservation")
        print("PASS widget URL compatibility, case-insensitive navigation links, unknown links and auth/import route isolation")
        if CommandLine.arguments.count > 1 {
            let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
            let metadata = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let actions = metadata["actions"] as! [String: [String: Any]]
            precondition(Set(actions.keys) == ["OpenScoutWishlistIntent", "OpenScoutPickerIntent", "OpenScoutJournalIntent"])
            precondition(actions.values.allSatisfy { $0["openAppWhenRun"] as? Bool == true && $0["isDiscoverable"] as? Bool == true })
            precondition((metadata["autoShortcuts"] as? [Any])?.count == 3)
            precondition(metadata["autoShortcutProviderMangledName"] != nil)
            print("PASS built app metadata: three discoverable foreground actions and App Shortcuts provider/tiles")
        }
    }
}
