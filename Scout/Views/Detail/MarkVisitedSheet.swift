import SwiftUI
import PhotosUI
import UIKit

struct MarkVisitedSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    let restaurant: Restaurant

    @State private var selectedRating: Int = 0
    @State private var visitNote: String = ""
    @State private var isSaving = false
    @State private var isSkipping = false
    @State private var errorMessage: String?

    // Photos
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isLoadingPhotos = false

    private var tileSide: CGFloat {
        (UIScreen.main.bounds.width - 2 * Atlas.screenHPad - 3 * 8) / 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    kicker
                    heading
                    subtitle
                    ratingSection
                    photoTraySection
                    noteSection
                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, Atlas.screenHPad)
            }

            ctaButtons
                .padding(.horizontal, Atlas.screenHPad)
                .padding(.bottom, 40)
        }
        .background(Atlas.paper.ignoresSafeArea())
        .onChange(of: isPresented) { _, newValue in
            if newValue { errorMessage = nil }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            isLoadingPhotos = true
            Task {
                var loaded = [UIImage?](repeating: nil, count: items.count)
                await withTaskGroup(of: (Int, UIImage?).self) { group in
                    for (i, item) in items.enumerated() {
                        group.addTask {
                            let data = try? await item.loadTransferable(type: Data.self)
                            return (i, data.flatMap { UIImage(data: $0) })
                        }
                    }
                    for await (i, img) in group { loaded[i] = img }
                }
                selectedImages = loaded.compactMap { $0 }
                isLoadingPhotos = false
            }
        }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Atlas.ink3)
                .frame(width: 36, height: 4)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Kicker

    private var kicker: some View {
        HStack(spacing: 7) {
            if let circle = appState.activeCircle {
                Circle()
                    .fill(circle.accentSwiftUIColor)
                    .frame(width: 7, height: 7)
                Text("Logged for \(circle.name)")
                    .font(Atlas.Font.sans(11, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(0.5)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Heading

    private var heading: some View {
        (
            Text("You went to ")
                .font(Atlas.Font.serif(28))
                .foregroundColor(Atlas.ink)
            + Text(restaurant.name)
                .font(Atlas.Font.serif(28, italic: true))
                .foregroundColor(Atlas.burnt)
            + Text(".")
                .font(Atlas.Font.serif(28))
                .foregroundColor(Atlas.ink)
        )
        .lineLimit(4)
        .minimumScaleFactor(0.8)
        .padding(.top, 10)
    }

    // MARK: - Subtitle

    private var subtitle: some View {
        Text("While it's fresh — how was it?")
            .font(Atlas.Font.sans(14))
            .foregroundColor(Atlas.ink2)
            .padding(.top, 8)
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RATING")
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        selectedRating = selectedRating == star ? 0 : star
                    } label: {
                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 26, weight: .ultraLight))
                            .foregroundColor(star <= selectedRating ? Atlas.burnt : Atlas.ink3)
                    }
                    .buttonStyle(.plain)
                }

                if selectedRating > 0 {
                    Text(ratingLabel)
                        .font(Atlas.Font.sans(12))
                        .foregroundColor(Atlas.ink2)
                        .padding(.leading, 2)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedRating)
        }
        .padding(.top, 30)
    }

    private var ratingLabel: String {
        switch selectedRating {
        case 1: return "Not for us"
        case 2: return "It was okay"
        case 3: return "Pretty good"
        case 4: return "Really good"
        case 5: return "Obsessed"
        default: return ""
        }
    }

    // MARK: - Photo tray

    private var photoTraySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTOS")
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)

            HStack(alignment: .top, spacing: 8) {
                // Loaded thumbnails
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: tileSide, height: tileSide)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button {
                            selectedImages.remove(at: idx)
                            if idx < pickerItems.count { pickerItems.remove(at: idx) }
                        } label: {
                            ZStack {
                                Circle().fill(Atlas.ink).frame(width: 20, height: 20)
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Atlas.paper)
                            }
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: -6)
                    }
                }

                // Add tile — hidden when at max 3
                if selectedImages.count < 3 {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: 3,
                        matching: .images
                    ) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Atlas.paper2)
                                .frame(width: tileSide, height: tileSide)
                            if isLoadingPhotos {
                                ProgressView().tint(Atlas.ink3)
                            } else {
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .light))
                                        .foregroundColor(Atlas.ink3)
                                    Text("Add")
                                        .font(Atlas.Font.sans(10))
                                        .foregroundColor(Atlas.ink3)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTE")
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)

            ZStack(alignment: .topLeading) {
                if visitNote.isEmpty {
                    Text("What made it special?")
                        .font(Atlas.Font.serif(15, italic: true))
                        .foregroundColor(Atlas.ink3)
                        .padding(.top, 14)
                        .padding(.leading, 16)
                }
                TextEditor(text: $visitNote)
                    .font(Atlas.Font.serif(15, italic: true))
                    .foregroundColor(Atlas.ink)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(10)
            }
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 24)
    }

    // MARK: - CTA buttons

    private var ctaButtons: some View {
        VStack(spacing: 10) {
            if let err = errorMessage {
                Text(err)
                    .font(Atlas.Font.sans(13))
                    .foregroundColor(Atlas.burnt)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)
            }
            Button {
                Task { await saveVisit() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView().tint(Atlas.paper)
                    } else {
                        Text("Save to journal")
                            .font(Atlas.Font.sans(14.5, weight: .semibold))
                            .foregroundColor(Atlas.paper)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Atlas.ink)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSaving || isSkipping)

            Button {
                Task { await skipVisit() }
            } label: {
                Group {
                    if isSkipping {
                        ProgressView().tint(Atlas.ink)
                    } else {
                        Text("Skip for now")
                            .font(Atlas.Font.sans(14, weight: .medium))
                            .foregroundColor(Atlas.ink2)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isSaving || isSkipping)
        }
    }

    // MARK: - Actions

    private func saveVisit() async {
        isSaving = true
        errorMessage = nil
        let ratingValue: Double? = selectedRating > 0 ? Double(selectedRating) : nil
        let noteValue = visitNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let photoData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        do {
            try await appState.markVisitedWithRecord(
                restaurantId: restaurant.id,
                rating: ratingValue,
                visitNote: noteValue.isEmpty ? nil : noteValue,
                photos: photoData
            )
            isPresented = false
        } catch {
            errorMessage = "Couldn't save — try again or skip."
        }
        isSaving = false
    }

    private func skipVisit() async {
        isSkipping = true
        do {
            try await appState.markVisited(restaurantId: restaurant.id)
            isPresented = false
        } catch {
            // Sheet remains open
        }
        isSkipping = false
    }
}

#Preview {
    let state = AppState.preview
    return MarkVisitedSheet(
        isPresented: .constant(true),
        restaurant: Restaurant.mockList[0]
    )
    .environment(state)
}
