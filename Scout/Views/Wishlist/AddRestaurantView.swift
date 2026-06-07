import SwiftUI
import Supabase

struct AddRestaurantView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    @State private var name                  = ""
    @State private var establishmentType     = Restaurant.EstablishmentType.restaurant
    @State private var cuisine               = ""
    @State private var cuisineOtherText      = ""
    @State private var showCuisineOtherField = false
    @State private var priceTier             = Restaurant.PriceTier.two
    @State private var notes                 = ""
    @State private var selectedVibeTags: Set<String> = []
    @State private var isSaving              = false
    @State private var errorMessage: String?

    // Place search
    @State private var suggestions: [PlaceSearchResult]  = []
    @State private var selectedPlace: PlaceSearchResult?
    @State private var selectedAddress: String?
    @State private var selectedLat: Double?
    @State private var selectedLon: Double?
    @State private var selectedGooglePlaceId: String?
    @State private var searchTask: Task<Void, Never>?

    private let popularCuisines = [
        "American", "Italian", "Mexican", "Japanese", "Chinese",
        "Thai", "Indian", "Mediterranean", "French", "Korean",
        "Vietnamese", "Greek", "Seafood", "Steakhouse", "BBQ",
        "Spanish", "Middle Eastern"
    ]

    private let vibes = ["Date night", "Casual", "Brunch", "Group", "Solo",
                         "Patio", "Late night", "Special occasion",
                         "Quick bite", "Lively", "Quiet", "Tasting menu"]

    private var orderedCuisines: [String] {
        guard !cuisine.isEmpty, let idx = popularCuisines.firstIndex(of: cuisine) else {
            return popularCuisines
        }
        var ordered = popularCuisines
        ordered.remove(at: idx)
        ordered.insert(cuisine, at: 0)
        return ordered
    }

    private var orderedVibes: [String] {
        guard !selectedVibeTags.isEmpty else { return vibes }
        let selected = vibes.filter { selectedVibeTags.contains($0) }
        let rest = vibes.filter { !selectedVibeTags.contains($0) }
        return selected + rest
    }

    private var effectiveCuisine: String? {
        if establishmentType != .restaurant { return nil }
        if showCuisineOtherField { return cuisineOtherText.isEmpty ? nil : cuisineOtherText }
        return cuisine.isEmpty ? nil : cuisine
    }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Name field
                    FormField(label: "NAME") {
                        TextField("e.g. Kismet", text: $name)
                            .font(Atlas.Font.serif(18))
                            .foregroundColor(Atlas.ink)
                    }

                    // Inline suggestions or selected address chip
                    if !suggestions.isEmpty && selectedPlace == nil {
                        suggestionsView
                    } else if let addr = selectedAddress {
                        selectedAddressRow(addr)
                    }

                    Divider().background(Atlas.rule)

                    // Establishment type pills
                    FormField(label: "TYPE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Restaurant.EstablishmentType.allCases, id: \.self) { type in
                                    FilterChip(
                                        label: type.displayName,
                                        isActive: establishmentType == type
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            establishmentType = type
                                            if type != .restaurant {
                                                cuisine = ""
                                                cuisineOtherText = ""
                                                showCuisineOtherField = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Cuisine pills — only shown when type is Restaurant
                    if establishmentType == .restaurant {
                        Divider().background(Atlas.rule)
                        FormField(label: "CUISINE") {
                            VStack(alignment: .leading, spacing: 10) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(orderedCuisines, id: \.self) { c in
                                            FilterChip(label: c, isActive: !showCuisineOtherField && cuisine == c) {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    if cuisine == c {
                                                        cuisine = ""
                                                    } else {
                                                        cuisine = c
                                                        showCuisineOtherField = false
                                                        cuisineOtherText = ""
                                                    }
                                                }
                                            }
                                        }
                                        FilterChip(label: "Other", isActive: showCuisineOtherField) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                showCuisineOtherField.toggle()
                                                if showCuisineOtherField { cuisine = "" }
                                                else { cuisineOtherText = "" }
                                            }
                                        }
                                    }
                                }

                                if showCuisineOtherField {
                                    TextField("Enter cuisine…", text: $cuisineOtherText)
                                        .font(Atlas.Font.sans(15))
                                        .foregroundColor(Atlas.ink)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Atlas.paper2)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }

                    Divider().background(Atlas.rule)

                    // Price tier
                    FormField(label: "PRICE RANGE") {
                        Picker("Price", selection: $priceTier) {
                            ForEach(Restaurant.PriceTier.allCases, id: \.self) { tier in
                                Text(tier.rawValue).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Atlas.burnt)
                    }

                    Divider().background(Atlas.rule)

                    // Vibe tags
                    FormField(label: "VIBE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(orderedVibes, id: \.self) { vibe in
                                    FilterChip(label: vibe, isActive: selectedVibeTags.contains(vibe)) {
                                        if selectedVibeTags.contains(vibe) {
                                            selectedVibeTags.remove(vibe)
                                        } else {
                                            selectedVibeTags.insert(vibe)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider().background(Atlas.rule)

                    // Note
                    FormField(label: "NOTE (OPTIONAL)") {
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("A little reminder to yourself…")
                                    .font(Atlas.Font.serif(15, italic: true))
                                    .foregroundColor(Atlas.ink3)
                                    .padding(.top, 2)
                            }
                            TextEditor(text: $notes)
                                .font(Atlas.Font.serif(15, italic: true))
                                .foregroundColor(Atlas.ink)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                        }
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                            .padding(.horizontal, Atlas.screenHPad)
                            .padding(.top, 12)
                    }
                }
            }
            .background(Atlas.paper.ignoresSafeArea())
            .navigationTitle("Add restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
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
                    .disabled(!isValid || isSaving)
                }
            }
        }
        .onChange(of: name) { _, newValue in
            handleNameChange(newValue)
        }
    }

    // MARK: - Suggestions list

    private var suggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { idx, item in
                Button { selectPlace(item) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                            .foregroundColor(Atlas.burnt)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(Atlas.Font.serif(15))
                                .foregroundColor(Atlas.ink)
                                .lineLimit(1)
                            if let address = item.address {
                                Text(address)
                                    .font(Atlas.Font.sans(12))
                                    .foregroundColor(Atlas.ink2)
                            }
                        }
                        Spacer()
                        ChevronRight(color: Atlas.ink3)
                    }
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.vertical, 10)
                    .background(Atlas.paper)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < suggestions.count - 1 {
                    Divider()
                        .background(Atlas.rule)
                        .padding(.leading, Atlas.screenHPad + 28)
                }
            }

        }
        .background(Atlas.paper2)
    }

    // MARK: - Selected address chip

    private func selectedAddressRow(_ address: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Atlas.statusOpen)
            Text(address)
                .font(Atlas.Font.sans(12))
                .foregroundColor(Atlas.ink2)
                .lineLimit(1)
            Spacer()
            Button { clearSelectedPlace() } label: {
                CloseIcon(color: Atlas.ink3, size: 10)
                    .frame(width: 24, height: 24)
                    .background(Atlas.rule)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.vertical, 10)
        .background(Atlas.paper2)
    }

    // MARK: - Place search logic

    private func handleNameChange(_ newValue: String) {
        if let item = selectedPlace, item.name == newValue { return }

        clearSelectedPlace()
        searchTask?.cancel()

        guard newValue.count >= 2 else {
            suggestions = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            suggestions = await PlacesService.shared.search(
                query: newValue,
                near: appState.location.userLocation
            )
        }
    }

    private func selectPlace(_ item: PlaceSearchResult) {
        selectedPlace = item
        name = item.name
        selectedAddress = item.address
        selectedLat = item.latitude
        selectedLon = item.longitude
        selectedGooglePlaceId = item.googlePlaceId

        if let detectedType = item.establishmentType {
            withAnimation(.easeInOut(duration: 0.2)) {
                establishmentType = detectedType
            }
        }
        if let detectedCuisine = item.cuisine, cuisine.isEmpty, cuisineOtherText.isEmpty {
            if popularCuisines.contains(detectedCuisine) {
                cuisine = detectedCuisine
                showCuisineOtherField = false
            } else {
                cuisineOtherText = detectedCuisine
                showCuisineOtherField = true
            }
        }
        if let detectedPrice = item.priceTier {
            priceTier = detectedPrice
        }
        selectedVibeTags.formUnion(item.vibeHints)

        suggestions = []
        searchTask?.cancel()
    }

    private func clearSelectedPlace() {
        selectedPlace = nil
        selectedAddress = nil
        selectedLat = nil
        selectedLon = nil
        selectedGooglePlaceId = nil
    }

    // MARK: - Save

    private func save() async {
        guard let circleId = appState.activeCircle?.id,
              let userId   = appState.currentUser?.id else {
            errorMessage = "Create a circle first before adding restaurants."
            return
        }
        isSaving = true
        errorMessage = nil
        let restaurant = Restaurant(
            circleId: circleId,
            name: name.trimmingCharacters(in: .whitespaces),
            cuisine: effectiveCuisine,
            establishmentType: establishmentType,
            priceTier: priceTier,
            address: selectedAddress,
            latitude: selectedLat,
            longitude: selectedLon,
            notes: notes.isEmpty ? nil : notes,
            vibeTags: Array(selectedVibeTags),
            googlePlaceId: selectedGooglePlaceId,
            addedBy: userId
        )
        do {
            try await appState.addRestaurant(restaurant)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)
            content()
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.vertical, 16)
    }
}

#Preview {
    AddRestaurantView(isPresented: .constant(true))
        .environment(AppState.preview)
}
