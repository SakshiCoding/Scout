import CoreLocation
import SwiftUI
import Supabase

struct ImportReviewView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let pendingImport: SharedRestaurantImport

    @State private var selectedCircleId: UUID?
    @State private var query: String
    @State private var note = ""
    @State private var suggestions: [PlaceSearchResult] = []
    @State private var selectedPlace: PlaceSearchResult?
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(pendingImport: SharedRestaurantImport) {
        self.pendingImport = pendingImport
        _query = State(initialValue: pendingImport.searchQuery)
    }

    private var selectedCircle: ScoutCircle? {
        guard let selectedCircleId else { return appState.activeCircle }
        return appState.circles.first { $0.id == selectedCircleId }
    }

    private var canSave: Bool {
        selectedCircle != nil && importedName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && !isSaving
    }

    private var importedName: String {
        selectedPlace?.name
            ?? query.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
            ?? pendingImport.name
            ?? pendingImport.sourceTitle
            ?? "Imported place"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    circleSelector
                    sourceCard
                    searchSection
                    noteField
                    if let errorMessage {
                        Text(errorMessage)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                    }
                }
                .padding(.horizontal, Atlas.screenHPad)
                .padding(.vertical, 18)
            }
            .background(Atlas.paper.ignoresSafeArea())
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        appState.clearPendingSharedImport()
                        dismiss()
                    }
                    .font(Atlas.Font.sans(15))
                    .foregroundColor(Atlas.ink2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(Atlas.burnt)
                        } else {
                            Text("Save")
                                .font(Atlas.Font.sans(15, weight: .semibold))
                                .foregroundColor(Atlas.burnt)
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            selectedCircleId = appState.activeCircle?.id ?? appState.circles.first?.id
            Task { await searchPlaces() }
        }
        .onChange(of: query) { _, _ in
            if selectedPlace?.name != query {
                selectedPlace = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add to Scout")
                .font(Atlas.Font.serif(34))
                .foregroundColor(Atlas.ink)
            Text("Confirm the place and choose where it belongs.")
                .font(Atlas.Font.sans(13))
                .foregroundColor(Atlas.ink2)
        }
    }

    private var circleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("CIRCLE")
            Menu {
                ForEach(appState.circles) { circle in
                    Button(circle.name) { selectedCircleId = circle.id }
                }
            } label: {
                HStack(spacing: 10) {
                    if let selectedCircle {
                        AvatarStack(
                            members: selectedCircle.members,
                            accentColor: selectedCircle.accentSwiftUIColor,
                            size: 24,
                            borderColor: Atlas.paper
                        )
                        Text(selectedCircle.name)
                            .font(Atlas.Font.serif(17))
                            .foregroundColor(Atlas.ink)
                    } else {
                        Text("Create a circle first")
                            .font(Atlas.Font.serif(17))
                            .foregroundColor(Atlas.ink2)
                    }
                    Spacer()
                    ChevronDown(color: Atlas.ink2)
                }
                .padding(14)
                .background(Atlas.paper2)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("SOURCE")
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: sourceIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Atlas.burnt)
                    .frame(width: 28, height: 28)
                    .background(Atlas.burnt.opacity(0.10))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(pendingImport.sourceTitle ?? pendingImport.name ?? pendingImport.sourceApp.displayName)
                        .font(Atlas.Font.serif(17))
                        .foregroundColor(Atlas.ink)
                        .lineLimit(2)
                    if let url = pendingImport.sourceURL {
                        Text(url.host() ?? url.absoluteString)
                            .font(Atlas.Font.sans(12))
                            .foregroundColor(Atlas.ink2)
                            .lineLimit(1)
                    } else if let text = pendingImport.sourceText {
                        Text(text)
                            .font(Atlas.Font.sans(12))
                            .foregroundColor(Atlas.ink2)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("MATCH")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(Atlas.ink3)
                TextField("Restaurant name or address", text: $query)
                    .font(Atlas.Font.serif(18))
                    .foregroundColor(Atlas.ink)
                    .submitLabel(.search)
                    .onSubmit { Task { await searchPlaces() } }
                Button {
                    Task { await searchPlaces() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Atlas.burnt)
                }
                .buttonStyle(.plain)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
            }
            .padding(14)
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if isSearching {
                ProgressView()
                    .tint(Atlas.burnt)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, place in
                        placeRow(place)
                        if index < suggestions.count - 1 {
                            Divider().background(Atlas.rule)
                        }
                    }
                }
                .background(Atlas.paper2)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if hasSearched {
                Text("No exact match found. Scout will save the name you entered.")
                    .font(Atlas.Font.sans(12.5))
                    .foregroundColor(Atlas.ink2)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("NOTE")
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Optional context from the share...")
                        .font(Atlas.Font.serif(15, italic: true))
                        .foregroundColor(Atlas.ink3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $note)
                    .font(Atlas.Font.serif(15, italic: true))
                    .foregroundColor(Atlas.ink)
                    .frame(minHeight: 92)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func placeRow(_ place: PlaceSearchResult) -> some View {
        Button {
            query = place.name
            selectedPlace = place
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedPlace?.id == place.id ? "checkmark.circle.fill" : "mappin")
                    .font(.system(size: 13))
                    .foregroundColor(selectedPlace?.id == place.id ? Atlas.statusOpen : Atlas.burnt)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(Atlas.Font.serif(16))
                        .foregroundColor(Atlas.ink)
                    if let address = place.address {
                        Text(address)
                            .font(Atlas.Font.sans(12))
                            .foregroundColor(Atlas.ink2)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Atlas.Font.sans(10.5, weight: .medium))
            .foregroundColor(Atlas.ink3)
            .kerning(1.6)
    }

    private var sourceIcon: String {
        switch pendingImport.sourceApp {
        case .appleMaps: return "map"
        case .googleMaps: return "mappin.and.ellipse"
        case .tiktok: return "music.note"
        case .instagram: return "camera"
        case .social: return "bubble.left.and.text.bubble.right"
        case .safari:    return "safari"
        case .other:     return "square.and.arrow.down"
        }
    }

    private func searchPlaces() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        isSearching = true
        defer { isSearching = false }
        suggestions = await PlacesService.shared.search(query: trimmed, near: pendingImport.coordinate ?? appState.location.userLocation)
        hasSearched = true
        if selectedPlace == nil {
            selectedPlace = suggestions.first
        }
    }

    private func save() async {
        guard let circle = selectedCircle,
              let userId = appState.currentUser?.id else {
            errorMessage = "Create a circle first before importing."
            return
        }

        isSaving = true
        errorMessage = nil
        let sourceNote = pendingImport.sourceURL?.absoluteString
        let noteText = [note.nonEmpty, sourceNote.map { "Imported from \($0)" }]
            .compactMap { $0 }
            .joined(separator: "\n")
            .nonEmpty

        let restaurant = Restaurant(
            circleId: circle.id,
            name: importedName.trimmingCharacters(in: .whitespacesAndNewlines),
            cuisine: selectedPlace?.cuisine,
            establishmentType: selectedPlace?.establishmentType ?? .restaurant,
            priceTier: selectedPlace?.priceTier,
            address: selectedPlace?.address ?? pendingImport.address,
            latitude: selectedPlace?.latitude ?? pendingImport.latitude,
            longitude: selectedPlace?.longitude ?? pendingImport.longitude,
            notes: noteText,
            vibeTags: Array(selectedPlace?.vibeHints ?? Set<String>()),
            googlePlaceId: selectedPlace?.googlePlaceId,
            addedBy: userId
        )

        do {
            try await appState.addImportedRestaurant(restaurant)
            appState.clearPendingSharedImport()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private extension SharedRestaurantImport.SourceApp {
    var displayName: String {
        switch self {
        case .appleMaps: return "Apple Maps"
        case .googleMaps: return "Google Maps"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .social: return "Social post"
        case .safari:    return "Safari"
        case .other:     return "Shared link"
        }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    ImportReviewView(
        pendingImport: SharedRestaurantImport(
            sourceURL: URL(string: "https://maps.apple.com/?q=Kismet&ll=34.101,-118.291"),
            sourceTitle: "Kismet",
            name: "Kismet",
            latitude: 34.101,
            longitude: -118.291,
            sourceApp: .appleMaps
        )
    )
    .environment(AppState.preview)
}
