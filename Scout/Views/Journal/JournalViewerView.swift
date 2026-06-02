import SwiftUI
import AVKit
import UIKit

struct JournalViewerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    let visit: Visit
    let initialMediaId: UUID

    @State private var viewerMedia: [Media]
    @State private var selectedIndex: Int
    @State private var showCrossPost = false
    @State private var showActions = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    init(restaurant: Restaurant, visit: Visit, media: [Media], initialMediaId: UUID) {
        self.restaurant = restaurant
        self.visit = visit
        self.initialMediaId = initialMediaId
        self._viewerMedia = State(initialValue: media)
        self._selectedIndex = State(initialValue: media.firstIndex { $0.id == initialMediaId } ?? 0)
    }

    var body: some View {
        ZStack {
            Color(hex: "#0E0905").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 12)

                TabView(selection: $selectedIndex) {
                    ForEach(Array(viewerMedia.enumerated()), id: \.element.id) { index, item in
                        JournalViewerMediaPage(
                            media: item,
                            isActive: index == selectedIndex
                        )
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 480)
                .padding(.top, 22)

                pageDots
                    .padding(.top, 20)

                captionBlock
                    .padding(.top, 26)

                Spacer(minLength: 18)

                thumbnailStrip
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showCrossPost) {
            if let selectedMedia {
                CrossPostSheet(
                    isPresented: $showCrossPost,
                    media: selectedMedia,
                    restaurant: restaurant,
                    visit: visit
                )
                .environment(appState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
        .confirmationDialog("Memory options", isPresented: $showActions) {
            Button("Share") { showCrossPost = true }
            Button("Delete", role: .destructive) { showDeleteConfirm = true }
        }
        .alert("Delete this memory?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteSelectedMedia() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The photo or video will be removed from this journal.")
        }
        .alert("Couldn't update journal", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            viewerButton(systemName: "xmark") {
                dismiss()
            }

            Spacer()

            VStack(spacing: 3) {
                Text(restaurant.name)
                    .font(Atlas.Font.serif(16))
                    .foregroundColor(Atlas.paper)
                    .lineLimit(1)

                Text("\(visit.visitedAt.formatted(.dateTime.month(.abbreviated).day())) · \(selectedIndex + 1) of \(viewerMedia.count)")
                    .font(Atlas.Font.sans(11))
                    .foregroundColor(Atlas.paper.opacity(0.60))
                    .kerning(0.4)
            }

            Spacer()

            HStack(spacing: 8) {
                viewerButton(systemName: "square.and.arrow.up") {
                    showCrossPost = true
                }

                viewerButton(systemName: "ellipsis") {
                    showActions = true
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func viewerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Atlas.paper)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial.opacity(0.45))
                .clipShape(Circle())
                .overlay(Circle().stroke(Atlas.paper.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(viewerMedia.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? Atlas.burnt : Atlas.paper.opacity(0.25))
                    .frame(width: index == selectedIndex ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.18), value: selectedIndex)
            }
        }
    }

    private var captionBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(day)
                    .font(Atlas.Font.serif(28))
                    .foregroundColor(Atlas.burnt)

                Text(monthAndYear)
                    .font(Atlas.Font.sans(10.5, weight: .medium))
                    .foregroundColor(Atlas.paper.opacity(0.55))
                    .kerning(1.6)

                Atlas.paper.opacity(0.12).frame(height: 1)

                if let occasion = visit.occasion, !occasion.isEmpty {
                    Text(occasion)
                        .font(Atlas.Font.serif(13, italic: true))
                        .foregroundColor(Atlas.paper.opacity(0.72))
                        .lineLimit(1)
                }
            }

            if let notes = visit.notes, !notes.isEmpty {
                Text("\"\(notes)\"")
                    .font(Atlas.Font.serif(16, italic: true))
                    .foregroundColor(Atlas.paper.opacity(0.92))
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, Atlas.screenHPad)
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewerMedia.enumerated()), id: \.element.id) { index, item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedIndex = index
                        }
                    } label: {
                        JournalViewerThumbnail(media: item, isActive: index == selectedIndex)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Atlas.screenHPad)
        }
    }

    private var day: String {
        visit.visitedAt.formatted(.dateTime.day(.twoDigits))
    }

    private var monthAndYear: String {
        visit.visitedAt.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    }

    private var selectedMedia: Media? {
        guard viewerMedia.indices.contains(selectedIndex) else { return nil }
        return viewerMedia[selectedIndex]
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func deleteSelectedMedia() async {
        guard let selectedMedia, !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await appState.deleteMedia(selectedMedia)
            viewerMedia.removeAll { $0.id == selectedMedia.id }
            if viewerMedia.isEmpty {
                dismiss()
            } else {
                selectedIndex = min(selectedIndex, viewerMedia.count - 1)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct JournalViewerMediaPage: View {
    @Environment(AppState.self) private var appState
    @State private var image: UIImage?
    @State private var player: AVPlayer?
    @State private var temporaryVideoURL: URL?
    @State private var isLoading = true

    let media: Media
    let isActive: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)

            if media.mediaType == .video, let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView().tint(Atlas.paper)
            } else {
                Image(systemName: media.mediaType == .video ? "play.slash" : "photo")
                    .font(.system(size: 34, weight: .ultraLight))
                    .foregroundColor(Atlas.paper.opacity(0.45))
            }
        }
        .task(id: isActive) {
            guard isActive else {
                clearMedia()
                return
            }
            await loadMedia()
        }
        .onDisappear {
            clearMedia()
        }
    }

    private func loadMedia() async {
        isLoading = true
        image = nil
        player = nil
        removeTemporaryVideo()

        guard let data = try? await appState.supabase.downloadMedia(path: media.storagePath) else {
            isLoading = false
            return
        }

        if media.mediaType == .photo {
            image = UIImage(data: data)
        } else {
            let fileExtension = (media.storagePath as NSString).pathExtension.isEmpty
                ? "mov"
                : (media.storagePath as NSString).pathExtension
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(media.id.uuidString)
                .appendingPathExtension(fileExtension)
            do {
                try data.write(to: url, options: .atomic)
                temporaryVideoURL = url
                player = AVPlayer(url: url)
            } catch {
                removeTemporaryVideo()
            }
        }

        isLoading = false
    }

    private func clearMedia() {
        player?.pause()
        image = nil
        player = nil
        isLoading = true
        removeTemporaryVideo()
    }

    private func removeTemporaryVideo() {
        guard let temporaryVideoURL else { return }
        try? FileManager.default.removeItem(at: temporaryVideoURL)
        self.temporaryVideoURL = nil
    }
}

private struct JournalViewerThumbnail: View {
    let media: Media
    let isActive: Bool

    var body: some View {
        JournalMediaThumbnail(media: media, size: 76, height: 58)
            .overlay {
                if media.mediaType == .video {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Atlas.paper)
                        .shadow(radius: 2)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? Atlas.burnt : Atlas.paper.opacity(0.18), lineWidth: isActive ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .opacity(isActive ? 1 : 0.70)
    }
}

#Preview {
    Color(hex: "#0E0905")
        .ignoresSafeArea()
}
