import AppIntents

struct OpenScoutWishlistIntent: AppIntent {
    static let title: LocalizedStringResource = "Open my wishlist"
    static let description = IntentDescription("Open your active circle's saved restaurants in Scout.")
    static let openAppWhenRun = true

    @AppDependency var appState: AppState

    @MainActor
    func perform() async throws -> some IntentResult {
        appState.navigate(to: .wishlist)
        return .result()
    }
}

struct OpenScoutPickerIntent: AppIntent {
    static let title: LocalizedStringResource = "Pick a restaurant"
    static let description = IntentDescription("Open your circle's shared picker. Everyone still casts their own votes.")
    static let openAppWhenRun = true

    @AppDependency var appState: AppState

    @MainActor
    func perform() async throws -> some IntentResult {
        appState.navigate(to: .pick)
        return .result()
    }
}

struct OpenScoutJournalIntent: AppIntent {
    static let title: LocalizedStringResource = "Open my journal"
    static let description = IntentDescription("Browse the restaurant visits in your active circle's journal.")
    static let openAppWhenRun = true

    @AppDependency var appState: AppState

    @MainActor
    func perform() async throws -> some IntentResult {
        appState.navigate(to: .journal)
        return .result()
    }
}

struct ScoutShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenScoutWishlistIntent(),
                    phrases: ["Open my wishlist in \(.applicationName)", "Show my wishlist in \(.applicationName)"],
                    shortTitle: "Open wishlist", systemImageName: "list.bullet")
        AppShortcut(intent: OpenScoutPickerIntent(),
                    phrases: ["Pick a restaurant in \(.applicationName)", "Help me pick in \(.applicationName)"],
                    shortTitle: "Pick a restaurant", systemImageName: "rectangle.stack")
        AppShortcut(intent: OpenScoutJournalIntent(),
                    phrases: ["Open my journal in \(.applicationName)", "Show my journal in \(.applicationName)"],
                    shortTitle: "Open journal", systemImageName: "book")
    }
}
