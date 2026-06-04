import SwiftUI
import UIKit

struct JournalLocationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showCirclePicker = false
    @State private var showAddEntry = false
    @State private var showLocationActions = false
    @State private var showMoveBackConfirm = false
    @State private var isMovingBack = false
    @State private var errorMessage: String?

    let restaurantId: UUID

    private var restaurant: Restaurant? {
        appState.restaurants.first { $0.id == restaurantId }
    }

    private var visits: [Visit] {
        appState.visits
            .filter { $0.restaurantId == restaurantId }
            .sorted { $0.visitedAt > $1.visitedAt }
    }

    private var media: [Media] {
        appState.media.filter { $0.restaurantId == restaurantId }
    }

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()

            if let restaurant {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if let circle = appState.activeCircle {
                            CircleSwitcherPill(
                                circle: circle,
                                onTap: { showCirclePicker = true },
                                onOverflow: { }
                            )
                            .padding(.top, 46)
                        }

                        locationHeader(restaurant)

                        if appState.isLoadingJournal && visits.isEmpty {
                            ProgressView()
                                .tint(Atlas.burnt)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 72)
                        } else if visits.isEmpty {
                            JournalLocationEmptyState(restaurant: restaurant) {
                                showAddEntry = true
                            }
                                .padding(.top, 58)
                        } else {
                            entries(restaurant)
                                .padding(.top, 36)
                        }

                        Spacer().frame(height: Atlas.listBottomPad)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await appState.loadJournal()
        }
        .onChange(of: appState.activeCircle?.id) { _, circleId in
            if circleId != restaurant?.circleId {
                dismiss()
            }
        }
        .sheet(isPresented: $showCirclePicker) {
            CirclePickerSheet(isPresented: $showCirclePicker)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .fullScreenCover(isPresented: $showAddEntry) {
            if let restaurant {
                JournalComposeView(isPresented: $showAddEntry, restaurant: restaurant)
                    .environment(appState)
            }
        }
        .confirmationDialog("Journal options", isPresented: $showLocationActions) {
            Button("Move back to wishlist", role: .destructive) {
                showMoveBackConfirm = true
            }
        }
        .alert("Move back to wishlist?", isPresented: $showMoveBackConfirm) {
            Button("Move back", role: .destructive) {
                Task { await moveBackToWishlist() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the place from the journal and permanently deletes its entries, notes, photos, and videos.")
        }
        .alert("Couldn't move place", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func locationHeader(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    ChevronLeft(color: Atlas.ink)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Atlas.rule, lineWidth: 1))
                }
                .buttonStyle(.plain)

                if let circle = appState.activeCircle {
                    CircleAccentRule(circle: circle, label: "JOURNAL")
                }

                Spacer()

                Button { showLocationActions = true } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Atlas.ink2)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Atlas.rule, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isMovingBack)
            }

            Text(restaurant.name)
                .font(Atlas.Font.serif(40))
                .foregroundColor(Atlas.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .padding(.top, 18)

            Text(statsText)
                .font(Atlas.Font.sans(13))
                .foregroundColor(Atlas.ink2)
                .padding(.top, 8)
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.top, 8)
    }

    private func entries(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visits.enumerated()), id: \.element.id) { index, visit in
                JournalVisitEntry(
                    restaurant: restaurant,
                    visit: visit,
                    media: media.filter { $0.visitId == visit.id }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .overlay(alignment: .top) {
                    if index > 0 {
                        DashedDivider()
                    }
                }
            }

            Button { showAddEntry = true } label: {
                HStack(spacing: 12) {
                    Text("+")
                        .font(Atlas.Font.serif(20))
                        .foregroundColor(Atlas.paper)
                        .frame(width: 32, height: 32)
                        .background(Atlas.burnt)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("New entry")
                            .font(Atlas.Font.serif(16))
                            .foregroundColor(Atlas.ink)
                        Text("Drop photos, videos & a note")
                            .font(Atlas.Font.sans(11.5))
                            .foregroundColor(Atlas.ink3)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 66)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Atlas.rule, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 8)
        }
    }

    private var statsText: String {
        let visitCount = visits.count
        let photoCount = media.filter { $0.mediaType == .photo }.count
        let videoCount = media.filter { $0.mediaType == .video }.count
        return "\(visitCount) visit\(visitCount == 1 ? "" : "s") · \(photoCount) photo\(photoCount == 1 ? "" : "s") · \(videoCount) video\(videoCount == 1 ? "" : "s")"
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func moveBackToWishlist() async {
        guard !isMovingBack else { return }
        isMovingBack = true
        defer { isMovingBack = false }

        do {
            try await appState.moveRestaurantBackToWishlist(restaurantId: restaurantId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct JournalVisitEntry: View {
    @Environment(AppState.self) private var appState
    @State private var selectedMedia: Media?
    @State private var showActions = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    let restaurant: Restaurant
    let visit: Visit
    let media: [Media]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(day)
                    .font(Atlas.Font.serif(28))
                    .foregroundColor(Atlas.burnt)

                Text(monthAndYear)
                    .font(Atlas.Font.sans(10.5, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(1.8)

                Atlas.rule.frame(height: 1)

                if let occasion = visit.occasion, !occasion.isEmpty {
                    Text(occasion)
                        .font(Atlas.Font.serif(14, italic: true))
                        .foregroundColor(Atlas.ink2)
                        .lineLimit(1)
                }

                Button { showActions = true } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Atlas.ink3)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Atlas.rule, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
            }

            if !media.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(Array(media.prefix(3).enumerated()), id: \.element.id) { index, item in
                        Button {
                            selectedMedia = item
                        } label: {
                            JournalPolaroid(media: item, index: index, itemCount: min(media.count, 3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 20)
            }

            if let notes = visit.notes, !notes.isEmpty {
                Text("\"\(notes)\"")
                    .font(Atlas.Font.serif(15.5, italic: true))
                    .foregroundColor(Atlas.ink)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)
                    .padding(.top, media.isEmpty ? 16 : 0)
            }
        }
        .fullScreenCover(item: $selectedMedia) { item in
            JournalViewerView(
                restaurant: restaurant,
                visit: visit,
                media: media,
                initialMediaId: item.id
            )
            .environment(appState)
        }
        .confirmationDialog("Entry options", isPresented: $showActions) {
            Button("Delete entry", role: .destructive) {
                showDeleteConfirm = true
            }
        }
        .alert("Delete this journal entry?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteEntry() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Its note and attached photos or videos will be permanently removed.")
        }
        .alert("Couldn't delete entry", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var day: String {
        visit.visitedAt.formatted(.dateTime.day(.twoDigits))
    }

    private var monthAndYear: String {
        visit.visitedAt.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func deleteEntry() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await appState.deleteJournalEntry(visit)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct JournalPolaroid: View {
    let media: Media
    let index: Int
    let itemCount: Int

    private var width: CGFloat { itemCount == 3 ? 108 : 138 }
    private var rotation: Double { [-3, 1.5, -1][index] }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                JournalMediaThumbnail(
                    media: media,
                    size: width - 20,
                    height: itemCount == 3 ? 124 : 150
                )
                Atlas.paper.frame(height: 28)
            }
            .padding(.top, 10)
            .padding(.horizontal, 10)
            .background(Atlas.paper)
            .cardShadow()
            .rotationEffect(.degrees(rotation))

            Rectangle()
                .fill(index == 1 ? Atlas.ink.opacity(0.16) : Atlas.burnt.opacity(0.20))
                .frame(width: index == 1 ? 48 : 54, height: 18)
                .rotationEffect(.degrees(index == 1 ? 4 : -5))
                .offset(y: -2)
        }
    }
}

private struct DashedDivider: View {
    var body: some View {
        Rectangle()
            .stroke(Atlas.rule, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .frame(height: 1)
    }
}

private struct JournalLocationEmptyState: View {
    let restaurant: Restaurant
    let onAddEntry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Atlas.paper)
                    .frame(width: 220, height: 290)
                    .overlay {
                        VStack(spacing: 12) {
                            Text("+")
                                .font(Atlas.Font.serif(26))
                                .foregroundColor(Atlas.paper)
                                .frame(width: 44, height: 44)
                                .background(Atlas.burnt)
                                .clipShape(Circle())
                            Text("ADD FIRST PHOTO")
                                .font(Atlas.Font.sans(10.5, weight: .medium))
                                .foregroundColor(Atlas.ink3)
                                .kerning(0.8)
                        }
                        .frame(width: 192, height: 240)
                        .background(Atlas.paper2)
                        .overlay(
                            Rectangle()
                                .stroke(Atlas.rule, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        )
                        .padding(.bottom, 22)
                    }
                    .cardShadow()
                    .rotationEffect(.degrees(-2))

                Rectangle()
                    .fill(Atlas.burnt.opacity(0.20))
                    .frame(width: 70, height: 18)
                    .rotationEffect(.degrees(-5))
                    .offset(y: -8)
            }

            (
                Text("Your first night at ")
                    .foregroundColor(Atlas.ink)
                + Text(restaurant.name)
                    .foregroundColor(Atlas.burnt)
                + Text(".")
                    .foregroundColor(Atlas.ink)
            )
            .font(Atlas.Font.serif(22, italic: true))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.top, 44)

            Text("Drop in a few photos and how the meal was. We'll keep the rest tidy.")
                .font(Atlas.Font.sans(13))
                .foregroundColor(Atlas.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 38)
                .padding(.top, 12)

            Button(action: onAddEntry) {
                Text("Add your first entry")
                    .font(Atlas.Font.sans(14.5, weight: .semibold))
                    .foregroundColor(Atlas.paper)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Atlas.ink)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 26)
        }
    }
}

struct JournalMediaThumbnail: View {
    @Environment(AppState.self) private var appState
    @State private var image: UIImage?

    let media: Media?
    let size: CGFloat
    var height: CGFloat? = nil

    var body: some View {
        ZStack {
            Atlas.paper2

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: media?.mediaType == .video ? "play.fill" : "photo")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Atlas.ink3)
            }
        }
        .frame(width: size, height: height ?? size)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .task(id: media?.id) {
            image = nil
            guard let media else { return }
            image = await appState.mediaService.thumbnail(for: media, supabase: appState.supabase)
        }
    }
}

#Preview {
    NavigationStack {
        JournalLocationView(restaurantId: Restaurant.mockList[0].id)
            .environment(AppState.preview)
    }
}
