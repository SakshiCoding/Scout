import Foundation

/// A bounded, credential-free projection shared by the app and WidgetKit extension.
struct ScoutWidgetSnapshot: Codable, Equatable {
    static let kind = "ScoutWishlistWidget"
    static let appGroupIdentifier = "group.com.sakshisangani.Scout"
    static let wishlistURL = URL(string: "scout://wishlist")!

    struct Place: Codable, Equatable, Identifiable {
        let id: UUID
        let name: String
        let subtitle: String
    }

    let version: Int
    let updatedAt: Date
    let isSignedIn: Bool
    let circleName: String?
    let wishlistCount: Int
    let places: [Place]

    init(isSignedIn: Bool, circleId: UUID?, circleName: String?, restaurants: [Restaurant], date: Date = Date()) {
        version = 1
        updatedAt = date
        self.isSignedIn = isSignedIn
        self.circleName = isSignedIn && circleId != nil ? circleName : nil
        let wishlist = isSignedIn && circleId != nil ? restaurants.filter {
            $0.circleId == circleId && $0.status == .wantToTry
        }.sorted {
            $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt > $1.createdAt
        } : []
        wishlistCount = wishlist.count
        places = wishlist.prefix(3).map {
            Place(id: $0.id, name: $0.name, subtitle: [$0.cuisine, $0.priceTier?.rawValue]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }.joined(separator: " · "))
        }
    }

    static var signedOut: Self {
        Self(isSignedIn: false, circleId: nil, circleName: nil, restaurants: [])
    }

    enum DisplayState: Equatable {
        case signedOut, noCircle, empty, ready, stale
    }

    func displayState(at date: Date) -> DisplayState {
        guard isSignedIn else { return .signedOut }
        // Do not keep presenting a saved wishlist as current indefinitely while the app is unused.
        guard date.timeIntervalSince(updatedAt) < 24 * 60 * 60 else { return .stale }
        guard circleName != nil else { return .noCircle }
        return places.isEmpty ? .empty : .ready
    }

    var expiresAt: Date { updatedAt.addingTimeInterval(24 * 60 * 60) }
}

struct ScoutWidgetStore {
    private let fileURL: URL?

    init(directoryURL: URL? = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: ScoutWidgetSnapshot.appGroupIdentifier
    )) {
        fileURL = directoryURL?.appendingPathComponent("scout-widget.json")
    }

    func load() -> ScoutWidgetSnapshot {
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(ScoutWidgetSnapshot.self, from: data),
              snapshot.version == 1 else { return .signedOut }
        return snapshot
    }

    @discardableResult
    func save(_ snapshot: ScoutWidgetSnapshot) -> Bool {
        guard let fileURL else { return false }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func clear() -> Bool {
        guard let fileURL else { return false }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return true }
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            // Overwrite with a signed-out projection if deletion could not complete.
            return save(.signedOut)
        }
    }
}
