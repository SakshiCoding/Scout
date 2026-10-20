import Foundation

@main
private struct WidgetSnapshotTests {
    static func main() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let circle = UUID()
        let otherCircle = UUID()
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        var restaurants = [
            Restaurant(id: secondID, circleId: circle, name: "Second", cuisine: " Italian ", priceTier: .two, createdAt: now),
            Restaurant(id: firstID, circleId: circle, name: "First", createdAt: now),
            Restaurant(circleId: circle, name: "Older", cuisine: " ", createdAt: now.addingTimeInterval(-1)),
            Restaurant(circleId: circle, name: "Oldest", createdAt: now.addingTimeInterval(-2)),
            Restaurant(circleId: circle, name: "Visited", status: .visited, createdAt: now),
            Restaurant(circleId: otherCircle, name: "Private to another circle", createdAt: now)
        ]
        func snapshot(_ items: [Restaurant]) -> ScoutWidgetSnapshot {
            ScoutWidgetSnapshot(isSignedIn: true, circleId: circle, circleName: "Friends", restaurants: items, date: now)
        }
        if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--fixture" {
            let store = ScoutWidgetStore(directoryURL: URL(fileURLWithPath: CommandLine.arguments[2]))
            precondition(store.save(ScoutWidgetSnapshot(
                isSignedIn: true, circleId: circle, circleName: "Friends", restaurants: restaurants
            )))
            print("Wrote synthetic widget preview data; relaunch Scout to clear it.")
            return
        }
        let ready = snapshot(restaurants)
        precondition(ready.wishlistCount == 4)
        precondition(ready.places.map(\.name) == ["First", "Second", "Older"])
        precondition(ready.places[1].subtitle == "Italian · $$")
        precondition(ready.places[2].subtitle.isEmpty)
        precondition(ready == snapshot(restaurants.reversed()))
        precondition(ready.displayState(at: now) == .ready)
        print("PASS: active circle isolation, visited exclusion, accurate count, bounded stable ordering, metadata")

        let signedOut = ScoutWidgetSnapshot(isSignedIn: false, circleId: circle, circleName: "Friends", restaurants: restaurants, date: now)
        precondition(signedOut.circleName == nil && signedOut.places.isEmpty && signedOut.wishlistCount == 0)
        precondition(signedOut.displayState(at: now) == .signedOut)
        let noCircle = ScoutWidgetSnapshot(isSignedIn: true, circleId: nil, circleName: nil, restaurants: restaurants, date: now)
        precondition(noCircle.displayState(at: now) == .noCircle && noCircle.places.isEmpty)
        precondition(snapshot([]).displayState(at: now) == .empty)
        precondition(ready.displayState(at: now.addingTimeInterval(86_399)) == .ready)
        precondition(ready.displayState(at: ready.expiresAt) == .stale)
        precondition(ready.displayState(at: now.addingTimeInterval(100_000)) == .stale)
        print("PASS: signed-out data removal, no-circle/empty states, and 24-hour expiry boundary")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ScoutWidgetStore(directoryURL: directory)
        precondition(!store.load().isSignedIn)
        precondition(store.save(ready))
        precondition(store.load() == ready)
        let secondReader = ScoutWidgetStore(directoryURL: directory)
        precondition(secondReader.load() == ready)
        restaurants[0].status = .visited
        precondition(store.save(snapshot(restaurants)))
        precondition(secondReader.load().wishlistCount == 3)
        let switched = ScoutWidgetSnapshot(isSignedIn: true, circleId: otherCircle, circleName: "Another circle", restaurants: restaurants, date: now)
        precondition(store.save(switched))
        precondition(secondReader.load().places.map(\.name) == ["Private to another circle"])
        precondition(store.clear())
        precondition(!secondReader.load().isSignedIn && secondReader.load().places.isEmpty)
        precondition(store.clear())
        print("PASS: shared cache round trip, updates, circle switching, sign-out deletion, idempotent cleanup")

        let file = directory.appendingPathComponent("scout-widget.json")
        try Data("invalid JSON".utf8).write(to: file)
        precondition(!store.load().isSignedIn)
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ready)) as! [String: Any]
        json["version"] = 999
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        precondition(!store.load().isSignedIn)
        let unavailable = ScoutWidgetStore(directoryURL: nil)
        precondition(!unavailable.save(ready) && !unavailable.load().isSignedIn)
        precondition(ScoutWidgetSnapshot.wishlistURL.scheme == "scout" && ScoutWidgetSnapshot.wishlistURL.host == "wishlist")
        print("PASS: corrupt/unsupported cache and unavailable App Group fail closed; wishlist link contract")
    }
}
