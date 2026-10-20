import SwiftUI
import WidgetKit

struct ScoutWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: ScoutWidgetSnapshot
}

struct ScoutWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScoutWidgetEntry

    var body: some View {
        ScoutWidgetContent(entry: entry, family: family)
    }
}

struct ScoutWidgetContent: View {
    let entry: ScoutWidgetEntry
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bookmark")
                Text("SCOUT")
                    .tracking(1.5)
                Spacer(minLength: 0)
                if entry.snapshot.displayState(at: entry.date) == .ready {
                    Text("\(entry.snapshot.wishlistCount)")
                }
            }
            .font(Atlas.Font.sans(11, weight: .semibold))
            .foregroundStyle(Atlas.burnt)
            .lineLimit(1)
            .frame(height: 16)

            switch entry.snapshot.displayState(at: entry.date) {
            case .ready:
                Text(entry.snapshot.circleName ?? "Your atlas")
                    .font(Atlas.Font.sans(11, weight: .medium))
                    .foregroundStyle(Atlas.ink2)
                    .lineLimit(1)
                ForEach(Array(entry.snapshot.places.prefix(family == .systemSmall ? 1 : 3))) { place in
                    if family == .systemSmall {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name).font(Atlas.Font.serif(20)).lineLimit(2)
                            subtitle(place.subtitle)
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(place.name)
                                .font(Atlas.Font.serif(18))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            subtitle(place.subtitle).fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
            case .signedOut:
                message("Your next good meal.", detail: "Sign in to Scout to see your wishlist.")
            case .noCircle:
                message("Make it a circle.", detail: "Open Scout to create or choose a circle.")
            case .empty:
                message("Room for a new favorite.", detail: "Add a place to \(entry.snapshot.circleName ?? "your circle").")
            case .stale:
                message("What's on your list?", detail: "Open Scout to refresh your wishlist.")
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Atlas.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Atlas.paper, for: .widget)
        .widgetURL(ScoutWidgetSnapshot.wishlistURL)
        .privacySensitive()
    }

    @ViewBuilder
    private func subtitle(_ text: String) -> some View {
        if !text.isEmpty {
            Text(text).font(Atlas.Font.sans(11)).foregroundStyle(Atlas.ink2).lineLimit(1)
        }
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Atlas.Font.serif(23)).lineLimit(2)
            Text(detail).font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink2).lineLimit(3)
        }
    }
}
