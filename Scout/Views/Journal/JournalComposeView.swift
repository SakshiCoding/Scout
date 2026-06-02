import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import AVFoundation

struct JournalComposeView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    let restaurant: Restaurant

    @State private var visitedAt = Date()
    @State private var occasion = ""
    @State private var visitNote = ""
    @State private var selectedVibes: Set<String> = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var attachments: [JournalComposeAttachment] = []
    @State private var showCamera = false
    @State private var isLoadingMedia = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let vibes = ["Date night", "Group", "Solo", "Brunch", "Patio", "Bar seat", "Loud", "Quiet"]
    private let maxAttachmentCount = 8

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    locationCard
                    dateAndOccasion
                    mediaSection
                    noteSection
                    vibeSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                            .padding(.top, 18)
                    }

                    Spacer().frame(height: 36)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Atlas.paper.ignoresSafeArea())
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await loadAttachments(from: items) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                guard attachments.count < maxAttachmentCount,
                      let attachment = JournalComposeAttachment.load(from: image) else { return }
                attachments.append(attachment)
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Cancel") { isPresented = false }
                .font(Atlas.Font.sans(14))
                .foregroundColor(Atlas.ink2)

            Spacer()

            Text("NEW ENTRY")
                .font(Atlas.Font.sans(11, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)

            Spacer()

            Button {
                Task { await saveEntry() }
            } label: {
                if isSaving {
                    ProgressView().tint(Atlas.burnt)
                } else {
                    Text("Save")
                        .font(Atlas.Font.sans(14, weight: .semibold))
                        .foregroundColor(Atlas.burnt)
                }
            }
            .buttonStyle(.plain)
            .disabled(isSaving || isLoadingMedia)
        }
        .frame(height: 44)
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private var locationCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Atlas.paper)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Atlas.ink3)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(Atlas.Font.serif(18))
                    .foregroundColor(Atlas.ink)
                    .lineLimit(1)

                Text(locationMetadata)
                    .font(Atlas.Font.sans(11.5))
                    .foregroundColor(Atlas.ink3)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 76)
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.top, 4)
    }

    private var dateAndOccasion: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("DATE")
                DatePicker("", selection: $visitedAt, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Atlas.burnt)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Atlas.rule, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("OCCASION")
                TextField("e.g. Birthday dinner", text: $occasion)
                    .font(Atlas.Font.serif(16, italic: true))
                    .foregroundColor(Atlas.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Atlas.rule, lineWidth: 1)
            )
        }
        .padding(.top, 18)
    }

    private func sectionLabel(_ label: String) -> some View {
        Text(label)
            .font(Atlas.Font.sans(10, weight: .medium))
            .foregroundColor(Atlas.ink3)
            .kerning(1.4)
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Photos & video")
                    .font(Atlas.Font.serif(18))
                    .foregroundColor(Atlas.ink)

                Spacer()

                Text("\(attachments.count) ADDED")
                    .font(Atlas.Font.sans(10.5, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(1.2)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(attachments) { attachment in
                    attachmentTile(attachment)
                }

                if attachments.count < maxAttachmentCount {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: maxAttachmentCount - attachments.count,
                        matching: .any(of: [.images, .videos])
                    ) {
                        addMediaTile
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { showCamera = true } label: {
                            cameraTile
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 22)
    }

    private func attachmentTile(_ attachment: JournalComposeAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: attachment.thumbnail)
                .resizable()
                .scaledToFill()
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomLeading) {
                    if attachment.upload.mediaType == .video {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Atlas.paper)
                            .padding(6)
                            .background(Atlas.ink.opacity(0.68))
                            .clipShape(Circle())
                            .padding(5)
                    }
                }

            Button {
                attachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Atlas.paper)
                    .frame(width: 18, height: 18)
                    .background(Atlas.ink.opacity(0.72))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }

    private var addMediaTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Atlas.rule, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 80)

            if isLoadingMedia {
                ProgressView().tint(Atlas.ink3)
            } else {
                VStack(spacing: 3) {
                    Text("+")
                        .font(Atlas.Font.serif(22))
                        .foregroundColor(Atlas.burnt)
                    Text("ADD")
                        .font(Atlas.Font.sans(8.5, weight: .medium))
                        .foregroundColor(Atlas.ink3)
                        .kerning(0.6)
                }
            }
        }
    }

    private var cameraTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Atlas.paper2)
                .frame(height: 80)

            VStack(spacing: 5) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Atlas.ink3)
                Text("CAMERA")
                    .font(Atlas.Font.sans(8.5, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(0.6)
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How was it?")
                .font(Atlas.Font.serif(18))
                .foregroundColor(Atlas.ink)

            ZStack(alignment: .topLeading) {
                if visitNote.isEmpty {
                    Text("What made the night worth remembering?")
                        .font(Atlas.Font.serif(15.5, italic: true))
                        .foregroundColor(Atlas.ink3)
                        .padding(.top, 16)
                        .padding(.leading, 16)
                }

                TextEditor(text: $visitNote)
                    .font(Atlas.Font.serif(15.5, italic: true))
                    .foregroundColor(Atlas.ink)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .padding(10)
            }
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 24)
    }

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TAG THE VIBE")

            FlowLayout(spacing: 6) {
                ForEach(vibes, id: \.self) { vibe in
                    FilterChip(label: vibe, isActive: selectedVibes.contains(vibe)) {
                        if selectedVibes.contains(vibe) {
                            selectedVibes.remove(vibe)
                        } else {
                            selectedVibes.insert(vibe)
                        }
                    }
                }
            }
        }
        .padding(.top, 18)
    }

    private var locationMetadata: String {
        restaurant.cuisine ?? restaurant.establishmentType.displayName
    }

    private func loadAttachments(from items: [PhotosPickerItem]) async {
        isLoadingMedia = true
        defer {
            pickerItems = []
            isLoadingMedia = false
        }

        for item in items where attachments.count < maxAttachmentCount {
            guard let attachment = await JournalComposeAttachment.load(from: item) else { continue }
            attachments.append(attachment)
        }
    }

    private func saveEntry() async {
        isSaving = true
        errorMessage = nil

        let note = visitNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let occasionValue = occasion.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await appState.addJournalEntry(
                restaurantId: restaurant.id,
                visitedAt: visitedAt,
                occasion: occasionValue.isEmpty ? nil : occasionValue,
                visitNote: note.isEmpty ? nil : note,
                vibeTags: selectedVibes.sorted(),
                mediaUploads: attachments.map(\.upload)
            )
            isPresented = false
        } catch {
            errorMessage = "Couldn't save this entry: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

private struct JournalComposeAttachment: Identifiable {
    let id = UUID()
    let thumbnail: UIImage
    let upload: VisitMediaUpload

    static func load(from image: UIImage) -> JournalComposeAttachment? {
        guard let jpegData = image.jpegData(compressionQuality: 0.82) else { return nil }
        return JournalComposeAttachment(thumbnail: image, upload: .photo(jpegData))
    }

    static func load(from item: PhotosPickerItem) async -> JournalComposeAttachment? {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }

        if isVideo {
            let contentType = item.supportedContentTypes.first(where: { $0.conforms(to: .movie) })
            let fileExtension = contentType?.preferredFilenameExtension ?? "mov"
            let mimeType = contentType?.preferredMIMEType ?? "video/quicktime"
            guard let thumbnail = await videoThumbnail(data: data, fileExtension: fileExtension) else { return nil }
            return JournalComposeAttachment(
                thumbnail: thumbnail,
                upload: .video(data, fileExtension: fileExtension, contentType: mimeType)
            )
        }

        guard let image = UIImage(data: data) else { return nil }
        return load(from: image)
    }

    private static func videoThumbnail(data: Data, fileExtension: String) async -> UIImage? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            try data.write(to: url, options: .atomic)
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            return await withCheckedContinuation { continuation in
                generator.generateCGImageAsynchronously(for: CMTime.zero) { image, _, _ in
                    continuation.resume(returning: image.map(UIImage.init(cgImage:)))
                }
            }
        } catch {
            return nil
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, point) in arrangement.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight), points)
    }
}

#Preview {
    JournalComposeView(
        isPresented: .constant(true),
        restaurant: Restaurant.mockList[0]
    )
    .environment(AppState.preview)
}
