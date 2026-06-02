import SwiftUI

struct JournalIndexView: View {
    @Environment(AppState.self) private var appState
    @State private var showCirclePicker = false

    var onBrowseWishlist: () -> Void = {}

    private var locations: [JournalLocationSummary] {
        appState.journalLocations
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Atlas.paper.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if let circle = appState.activeCircle {
                            CircleSwitcherPill(
                                circle: circle,
                                onTap: { showCirclePicker = true },
                                onOverflow: { }
                            )
                            .padding(.top, 46)

                            masthead(circle)
                                .padding(.horizontal, Atlas.screenHPad)
                                .padding(.top, 14)
                        }

                        if appState.isLoadingJournal {
                            ProgressView()
                                .tint(Atlas.burnt)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 72)
                        } else if locations.isEmpty {
                            JournalIndexEmptyState(onBrowseWishlist: onBrowseWishlist)
                                .padding(.top, 52)
                        } else {
                            index
                                .padding(.horizontal, Atlas.screenHPad)
                                .padding(.top, 28)
                        }

                        Spacer().frame(height: Atlas.listBottomPad)
                    }
                }
            }
            .task {
                await appState.loadJournal()
            }
            .sheet(isPresented: $showCirclePicker) {
                CirclePickerSheet(isPresented: $showCirclePicker)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
    }

    private func masthead(_ circle: ScoutCircle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleAccentRule(
                    circle: circle,
                    label: "\(circle.displayShortName.uppercased()) · VOLUME 1"
                )
                Spacer()
                Text(journalYear)
                    .font(Atlas.Font.serif(13))
                    .foregroundColor(Atlas.ink2)
            }

            (
                Text("Where ")
                    .foregroundColor(Atlas.ink)
                + Text("we've")
                    .foregroundColor(Atlas.burnt)
                + Text("\nbeen")
                    .foregroundColor(Atlas.ink)
            )
            .font(Atlas.Font.serif(56))
            .lineSpacing(-7)
            .padding(.top, 14)

            HStack(spacing: 22) {
                JournalStat(value: locations.count, label: "PLACES")
                JournalStat(value: photoCount, label: "PHOTOS")
                JournalStat(value: videoCount, label: "VIDEOS")
                JournalStat(value: appState.visits.count, label: "VISITS")
            }
            .padding(.top, 18)
        }
    }

    private var index: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("THE INDEX")
                Spacer()
                Text("MOST RECENT ↓")
            }
            .font(Atlas.Font.sans(11, weight: .medium))
            .foregroundColor(Atlas.ink3)
            .kerning(1.4)
            .padding(.bottom, 12)

            ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                NavigationLink {
                    JournalLocationView(restaurantId: location.restaurant.id)
                } label: {
                    JournalIndexRow(index: index + 1, location: location)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var journalYear: String {
        let date = appState.visits.first?.visitedAt ?? Date()
        return String(Calendar.current.component(.year, from: date))
    }

    private var photoCount: Int {
        appState.media.filter { $0.mediaType == .photo }.count
    }

    private var videoCount: Int {
        appState.media.filter { $0.mediaType == .video }.count
    }
}

private struct JournalStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: "%02d", value))
                .font(Atlas.Font.serif(22))
                .foregroundColor(Atlas.ink)
            Text(label)
                .font(Atlas.Font.sans(9.5))
                .foregroundColor(Atlas.ink3)
                .kerning(1.2)
        }
    }
}

private struct JournalIndexRow: View {
    let index: Int
    let location: JournalLocationSummary

    var body: some View {
        HStack(spacing: 14) {
            Text(String(format: "%02d", index))
                .font(Atlas.Font.serif(22))
                .foregroundColor(Atlas.burnt)
                .frame(width: 32, alignment: .leading)

            JournalMediaThumbnail(media: location.media.first, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(location.restaurant.name)
                    .font(Atlas.Font.serif(18))
                    .foregroundColor(Atlas.ink)
                    .lineLimit(2)

                Text(metadata)
                    .font(Atlas.Font.sans(11))
                    .foregroundColor(Atlas.ink3)
                    .kerning(0.4)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                Text(location.lastVisitedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Atlas.Font.serif(14))
                    .foregroundColor(Atlas.ink)
                Text(location.visits.isEmpty ? "MARKED VISITED" : "LAST ENTRY")
                    .font(Atlas.Font.sans(10))
                    .foregroundColor(Atlas.ink3)
                    .kerning(1.2)
            }
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Atlas.rule.frame(height: 1)
        }
    }

    private var metadata: String {
        let cuisine = location.restaurant.cuisine?.uppercased() ?? "RESTAURANT"
        let count = location.visits.count
        return "\(cuisine) · \(count) VISIT\(count == 1 ? "" : "S")"
    }
}

private struct JournalIndexEmptyState: View {
    let onBrowseWishlist: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: -4) {
                BlankPolaroid(rotation: -5, tapeRotation: -6)
                BlankPolaroid(rotation: 2, tapeRotation: 4, tapeColor: Atlas.ink.opacity(0.16))
                BlankPolaroid(rotation: -1, tapeRotation: -2)
            }

            (
                Text("Your ")
                    .foregroundColor(Atlas.ink)
                + Text("atlas")
                    .foregroundColor(Atlas.burnt)
                + Text(" starts here.")
                    .foregroundColor(Atlas.ink)
            )
            .font(Atlas.Font.serif(24, italic: true))
            .padding(.top, 36)

            Text("Mark a place visited and we'll open its journal automatically. Add photos and a note to remember the night by.")
                .font(Atlas.Font.sans(13.5))
                .foregroundColor(Atlas.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 34)
                .padding(.top, 12)

            Button(action: onBrowseWishlist) {
                Label("Browse your wishlist", systemImage: "plus")
                    .font(Atlas.Font.sans(13.5, weight: .semibold))
                    .foregroundColor(Atlas.paper)
                    .padding(.horizontal, 22)
                    .frame(height: 50)
                    .background(Atlas.ink)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
        }
    }
}

private struct BlankPolaroid: View {
    let rotation: Double
    let tapeRotation: Double
    var tapeColor: Color = Atlas.burnt.opacity(0.20)

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Atlas.paper)
                .frame(width: 116, height: 170)
                .overlay(alignment: .top) {
                    Atlas.paper2
                        .frame(width: 96, height: 132)
                        .padding(.top, 10)
                }
                .cardShadow()
                .rotationEffect(.degrees(rotation))

            Rectangle()
                .fill(tapeColor)
                .frame(width: 54, height: 18)
                .rotationEffect(.degrees(tapeRotation))
                .offset(y: -8)
        }
    }
}

#Preview {
    JournalIndexView()
        .environment(AppState.preview)
}
