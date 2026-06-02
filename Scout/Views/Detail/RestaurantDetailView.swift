import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurantId: UUID
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showMarkVisited = false
    @State private var showJournal = false
    @State private var showDeleteConfirm = false
    @State private var showReservationOptions = false
    @State private var isDeleting = false

    @Environment(\.openURL) private var openURL

    private var restaurant: Restaurant? {
        appState.restaurants.first { $0.id == restaurantId }
    }

    var body: some View {
        Group {
            if let r = restaurant {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            heroArea(r)
                            titleBlock(r)
                            statRow(r)
                            if let notes = r.notes, !notes.isEmpty {
                                noteCard(notes)
                            }
                            if !r.vibeTags.isEmpty {
                                vibeTagsSection(r.vibeTags)
                            }
                            Spacer().frame(height: Atlas.listBottomPad + 80)
                        }
                    }
                    .ignoresSafeArea(edges: .top)

                    ctaButtons(r)
                        .padding(.horizontal, Atlas.screenHPad)
                        .padding(.bottom, Atlas.tabBarBottomOffset + Atlas.tabBarHeight + 12)
                }
                .background(Atlas.paper.ignoresSafeArea())
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let r = restaurant {
                EditRestaurantSheet(restaurant: r, isPresented: $showEdit)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
        .sheet(isPresented: $showMarkVisited) {
            if let r = restaurant {
                MarkVisitedSheet(isPresented: $showMarkVisited, restaurant: r)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
        .fullScreenCover(isPresented: $showJournal) {
            NavigationStack {
                JournalLocationView(restaurantId: restaurantId)
                    .environment(appState)
            }
        }
        .confirmationDialog(
            "Delete \(restaurant?.name ?? "this restaurant")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if let r = restaurant { await deleteRestaurant(r) }
                }
            }
        } message: {
            Text("It will be removed from the circle's wishlist.")
        }
        .confirmationDialog(
            "Make a reservation",
            isPresented: $showReservationOptions,
            titleVisibility: .visible
        ) {
            Button("OpenTable") {
                if let r = restaurant { openReservation(.openTable, for: r) }
            }
            Button("Resy") {
                if let r = restaurant { openReservation(.resy, for: r) }
            }
        } message: {
            if let r = restaurant {
                Text("Search for \(r.name) on your preferred reservation platform.")
            }
        }
    }

    // MARK: - Hero area

    private func heroArea(_ r: Restaurant) -> some View {
        ZStack(alignment: .top) {
            // Placeholder hero
            Atlas.paper2
                .frame(height: 300)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundColor(Atlas.ink3)
                        Text("No photo yet")
                            .font(Atlas.Font.sans(12))
                            .foregroundColor(Atlas.ink3)
                    }
                )

            // Controls overlay
            HStack(alignment: .center) {
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(Atlas.paper.opacity(0.92))
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .frame(width: 38, height: 38)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Atlas.ink)
                    }
                }
                .buttonStyle(.plain)
                .shadow(color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.18),
                        radius: 6, x: 0, y: 4)

                Spacer()

                if let circle = appState.activeCircle {
                    CircleSwitcherPill(circle: circle, glassStyle: true)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 56)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Title block

    private func titleBlock(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cuisine · Price · Distance
            HStack(spacing: 5) {
                if let cuisine = r.cuisine {
                    Text(cuisine.uppercased())
                }
                if r.cuisine != nil && (r.priceTier != nil || r.formattedDistance != nil) {
                    Text("·").foregroundColor(Atlas.ink3)
                }
                if let price = r.priceTier {
                    Text(price.rawValue)
                }
                if let dist = r.formattedDistance {
                    if r.priceTier != nil {
                        Text("·").foregroundColor(Atlas.ink3)
                    }
                    Text("\(dist) MI")
                }
            }
            .font(Atlas.Font.sans(11.5))
            .foregroundColor(Atlas.ink3)
            .kerning(1.4)

            Text(r.name)
                .font(Atlas.Font.serif(40))
                .foregroundColor(Atlas.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .padding(.top, 8)

            StatusDot(status: .open)
                .padding(.top, 12)
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.top, 22)
    }

    // MARK: - Stat row

    private func statRow(_ r: Restaurant) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if let rating = r.rating {
                StatCell(value: String(format: "%.1f", rating), label: "RATING")
                Spacer()
            }
            if let price = r.priceTier {
                StatCell(value: price.rawValue, label: "PRICE")
                Spacer()
            }
            if let dist = r.formattedDistance {
                StatCell(value: dist, label: "MILES AWAY")
            } else if r.rating == nil && r.priceTier == nil {
                StatCell(value: "—", label: "RATING")
                Spacer()
                StatCell(value: "—", label: "PRICE")
                Spacer()
                StatCell(value: "—", label: "MILES AWAY")
            }
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Atlas.rule
                .frame(height: 1)
                .padding(.horizontal, Atlas.screenHPad)
        }
        .overlay(alignment: .bottom) {
            Atlas.rule
                .frame(height: 1)
                .padding(.horizontal, Atlas.screenHPad)
        }
        .padding(.top, 22)
    }

    // MARK: - Note card

    private func noteCard(_ notes: String) -> some View {
        Text(notes)
            .font(Atlas.Font.serif(16, italic: true))
            .foregroundColor(Atlas.ink)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 20)
    }

    // MARK: - Vibe tags

    private func vibeTagsSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VIBE")
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        FilterChip(label: tag, isActive: false, action: {})
                    }
                }
            }
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.top, 24)
    }

    // MARK: - CTA buttons

    private func ctaButtons(_ r: Restaurant) -> some View {
        HStack(spacing: 10) {
            if r.status == .wantToTry {
                Button {
                    showMarkVisited = true
                } label: {
                    Text("Mark as visited")
                        .font(Atlas.Font.sans(14.5, weight: .semibold))
                        .foregroundColor(Atlas.paper)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Atlas.ink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button { showReservationOptions = true } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Atlas.ink)
                        .frame(width: 52, height: 52)
                        .background(Atlas.paper)
                        .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Atlas.statusOpen)
                        .frame(width: 7, height: 7)
                    Text("Visited")
                        .font(Atlas.Font.sans(14, weight: .medium))
                        .foregroundColor(Atlas.ink2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))

                Button { showJournal = true } label: {
                    Image(systemName: "book.closed")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Atlas.ink)
                        .frame(width: 52, height: 52)
                        .background(Atlas.paper)
                        .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button { showReservationOptions = true } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Atlas.ink)
                        .frame(width: 52, height: 52)
                        .background(Atlas.paper)
                        .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button { showEdit = true } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Atlas.ink)
                    .frame(width: 52, height: 52)
                    .background(Atlas.paper)
                    .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button { showDeleteConfirm = true } label: {
                Group {
                    if isDeleting {
                        ProgressView().tint(Atlas.burnt)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Atlas.burnt)
                    }
                }
                .frame(width: 52, height: 52)
                .background(Atlas.paper)
                .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        }
    }

    // MARK: - Actions

    private func deleteRestaurant(_ r: Restaurant) async {
        isDeleting = true
        do {
            try await appState.deleteRestaurant(restaurantId: r.id)
            dismiss()
        } catch {
            isDeleting = false
        }
    }

    private enum ReservationPlatform {
        case openTable, resy
    }

    private func openReservation(_ platform: ReservationPlatform, for restaurant: Restaurant) {
        var components = URLComponents()
        components.scheme = "https"
        switch platform {
        case .openTable:
            components.host = "www.opentable.com"
            components.path = "/s/"
            components.queryItems = [
                URLQueryItem(name: "term", value: restaurant.name),
                URLQueryItem(name: "covers", value: "2")
            ]
        case .resy:
            components.host = "resy.com"
            components.path = "/"
        }
        if let url = components.url {
            openURL(url)
        }
    }
}

// MARK: - Stat cell

private struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Atlas.Font.serif(28))
                .foregroundColor(Atlas.ink)
            Text(label)
                .font(Atlas.Font.sans(9.5))
                .foregroundColor(Atlas.ink3)
                .kerning(1.4)
        }
    }
}

// MARK: - Edit sheet

private struct EditRestaurantSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    let restaurant: Restaurant

    @State private var name: String
    @State private var cuisine: String
    @State private var establishmentType: Restaurant.EstablishmentType
    @State private var priceTier: Restaurant.PriceTier
    @State private var suggestions: [MKMapItem]
    @State private var selectedMapItem: MKMapItem?
    @State private var selectedAddress: String?
    @State private var selectedLat: Double?
    @State private var selectedLon: Double?
    @State private var searchTask: Task<Void, Never>?
    @State private var notes: String
    @State private var selectedVibeTags: Set<String>
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let vibes = ["Date night", "Casual", "Brunch", "Group", "Solo",
                         "Patio", "Late night", "Special occasion",
                         "Quick bite", "Lively", "Quiet", "Tasting menu"]

    init(restaurant: Restaurant, isPresented: Binding<Bool>) {
        self.restaurant = restaurant
        self._isPresented = isPresented
        self._name = State(initialValue: restaurant.name)
        self._cuisine = State(initialValue: restaurant.cuisine ?? "")
        self._establishmentType = State(initialValue: restaurant.establishmentType)
        self._priceTier = State(initialValue: restaurant.priceTier ?? .two)
        self._suggestions = State(initialValue: [])
        self._selectedAddress = State(initialValue: restaurant.address)
        self._selectedLat = State(initialValue: restaurant.latitude)
        self._selectedLon = State(initialValue: restaurant.longitude)
        self._notes = State(initialValue: restaurant.notes ?? "")
        self._selectedVibeTags = State(initialValue: Set(restaurant.vibeTags))
    }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    EditFormField(label: "RESTAURANT NAME") {
                        TextField("e.g. Kismet", text: $name)
                            .font(Atlas.Font.serif(18))
                            .foregroundColor(Atlas.ink)
                    }

                    if !suggestions.isEmpty && selectedMapItem == nil {
                        suggestionsView
                    } else if let addr = selectedAddress {
                        selectedAddressRow(addr)
                    }

                    Divider().background(Atlas.rule)

                    EditFormField(label: "CUISINE (OPTIONAL)") {
                        TextField("e.g. Mediterranean", text: $cuisine)
                            .font(Atlas.Font.sans(15))
                            .foregroundColor(Atlas.ink)
                    }

                    Divider().background(Atlas.rule)

                    EditFormField(label: "PRICE RANGE") {
                        Picker("Price", selection: $priceTier) {
                            ForEach(Restaurant.PriceTier.allCases, id: \.self) { tier in
                                Text(tier.rawValue).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider().background(Atlas.rule)

                    EditFormField(label: "VIBE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(vibes, id: \.self) { vibe in
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

                    EditFormField(label: "NOTE (OPTIONAL)") {
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
            .navigationTitle("Edit restaurant")
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
        .task {
            searchForPlace(named: name)
        }
    }

    private var suggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { idx, item in
                Button { selectPlace(item) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                            .foregroundColor(Atlas.burnt)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "")
                                .font(Atlas.Font.serif(15))
                                .foregroundColor(Atlas.ink)
                                .lineLimit(1)
                            if !item.displayAddress.isEmpty {
                                Text(item.displayAddress)
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
            Button {
                clearSelectedPlace()
                searchForPlace(named: name)
            } label: {
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

    private func handleNameChange(_ newValue: String) {
        if let item = selectedMapItem, item.name == newValue { return }

        clearSelectedPlace()
        searchForPlace(named: newValue)
    }

    private func searchForPlace(named name: String) {
        searchTask?.cancel()

        guard name.count >= 2 else {
            suggestions = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            suggestions = await PlacesService.shared.search(
                query: name,
                near: appState.location.userLocation
            )
        }
    }

    private func selectPlace(_ item: MKMapItem) {
        selectedMapItem = item
        if let placeName = item.name { name = placeName }
        let addr = item.displayAddress
        selectedAddress = addr.isEmpty ? nil : addr
        selectedLat = item.placemark.coordinate.latitude
        selectedLon = item.placemark.coordinate.longitude

        if let category = item.pointOfInterestCategory {
            if let detectedType = category.establishmentTypeHint {
                establishmentType = detectedType
            }
            selectedVibeTags.formUnion(category.vibeHints)
        }

        suggestions = []
        searchTask?.cancel()
    }

    private func clearSelectedPlace() {
        selectedMapItem = nil
        selectedAddress = nil
        selectedLat = nil
        selectedLon = nil
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        var updated = restaurant
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.cuisine = cuisine.isEmpty ? nil : cuisine
        updated.establishmentType = establishmentType
        updated.priceTier = priceTier
        updated.address = selectedAddress
        updated.latitude = selectedLat
        updated.longitude = selectedLon
        updated.notes = notes.isEmpty ? nil : notes
        updated.vibeTags = Array(selectedVibeTags)
        do {
            try await appState.updateRestaurant(updated)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private struct EditFormField<Content: View>: View {
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
    let state = AppState.preview
    return RestaurantDetailView(restaurantId: Restaurant.mockList[0].id)
        .environment(state)
}
