import Foundation

enum TabItem: String, CaseIterable {
    case list, map, pick, journal
}

/// Read-only entry points shared by Siri, Shortcuts, and app links.
enum ScoutDestination: String, CaseIterable {
    case wishlist, pick, journal

    init?(url: URL) {
        guard url.scheme?.lowercased() == "scout",
              let host = url.host?.lowercased(),
              let destination = Self(rawValue: host) else { return nil }
        self = destination
    }

    var tab: TabItem {
        switch self {
        case .wishlist: .list
        case .pick: .pick
        case .journal: .journal
        }
    }
}
