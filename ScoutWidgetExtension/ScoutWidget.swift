import SwiftUI
import WidgetKit


struct ScoutWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScoutWidgetEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (ScoutWidgetEntry) -> Void) {
        completion(context.isPreview ? Self.sample : ScoutWidgetEntry(date: Date(), snapshot: ScoutWidgetStore().load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScoutWidgetEntry>) -> Void) {
        let date = Date()
        let snapshot = ScoutWidgetStore().load()
        var entries = [ScoutWidgetEntry(date: date, snapshot: snapshot)]
        if snapshot.isSignedIn, snapshot.expiresAt > date {
            entries.append(ScoutWidgetEntry(date: snapshot.expiresAt, snapshot: snapshot))
        }
        // Read the shared cache only; the app publishes changes and requests reloads.
        completion(Timeline(entries: entries, policy: .after(date.addingTimeInterval(60 * 60))))
    }

    static var sample: ScoutWidgetEntry {
        let circleId = UUID()
        return ScoutWidgetEntry(date: Date(), snapshot: ScoutWidgetSnapshot(
            isSignedIn: true, circleId: circleId, circleName: "Date nights",
            restaurants: [
                Restaurant(circleId: circleId, name: "Kismet", cuisine: "Mediterranean", priceTier: .two),
                Restaurant(circleId: circleId, name: "Lilia", cuisine: "Italian", priceTier: .three),
                Restaurant(circleId: circleId, name: "The neighborhood cafe", cuisine: "Cafe", priceTier: .one)
            ]
        ))
    }
}


@main
struct ScoutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ScoutWidgetSnapshot.kind, provider: ScoutWidgetProvider()) { entry in
            ScoutWidgetView(entry: entry)
        }
        .configurationDisplayName("Scout Wishlist")
        .description("Keep your circle's next good meals close. Tap to open your wishlist.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ScoutWidget()
} timeline: {
    ScoutWidgetProvider.sample
    ScoutWidgetEntry(date: Date(), snapshot: .signedOut)
}

#Preview(as: .systemMedium) {
    ScoutWidget()
} timeline: {
    ScoutWidgetProvider.sample
}
