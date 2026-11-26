import Supabase
import SwiftUI

struct WishlistView: View {
    @Environment(AppState.self) private var appState
    @State private var showCirclePicker = false
    @State private var showJoinCircle = false
    @State private var showAddRestaurant = false
    @State private var showBulkImport = false
    @State private var showFilter = false
    @State private var selectedRestaurant: Restaurant?
    @State private var search = ""
    @FocusState private var searchIsFocused: Bool
    @State private var photoRefreshId = 0

    @State private var discovery = RestaurantDiscoveryState()
    @State private var loadedDiscovery: DiscoveryRequest?
    @State private var addRequest: AddRequest?
    private struct DiscoveryRequest: Hashable {
        let query: String
        let refreshId: Int
        let user: UUID?
        let circle: UUID?
    }
    private struct AddRequest: Identifiable {
        let id = UUID()
        var place: PlaceSearchResult?
        var name = ""
    }
    private var discoveryRequest: DiscoveryRequest {
        DiscoveryRequest(
            query: search, refreshId: photoRefreshId, user: appState.isAuthenticated ? appState.currentUser?.id : nil,
            circle: appState.activeCircle?.id)
    }
    private var searching: Bool { !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var discovered: [PlaceSearchResult] {
        loadedDiscovery == discoveryRequest ? discovery.results : []
    }
    private var savedSearchResults: [Restaurant] {
        var found = appState.restaurants.filter { WishlistSearch.matches($0, query: search) }
        for place in discovered {
            if let saved = SavedPlaceMatch.restaurant(
                for: place, in: appState.restaurants, circleId: appState.activeCircle?.id),
                !found.contains(where: { $0.id == saved.id })
            {
                found.append(saved)
            }
        }
        return found
    }
    private var newSearchResults: [PlaceSearchResult] {
        discovered.filter {
            SavedPlaceMatch.restaurant(for: $0, in: appState.restaurants, circleId: appState.activeCircle?.id) == nil
        }
    }

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()

            if appState.isLoadingAuth {
                ProgressView().tint(Atlas.burnt)
            } else if appState.activeCircle == nil {
                NoCircleView(showNewCircle: $showCirclePicker, showJoinCircle: $showJoinCircle)
            } else {
                wishlistContent
            }
        }
        .task {
            if appState.restaurants.isEmpty {
                await appState.loadRestaurants()
            }
        }
        .sheet(isPresented: $showCirclePicker) {
            if appState.activeCircle == nil {
                NewCircleSheet(isPresented: $showCirclePicker)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            } else {
                CirclePickerSheet(isPresented: $showCirclePicker)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
        .sheet(isPresented: $showAddRestaurant) {
            AddRestaurantView(isPresented: $showAddRestaurant)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .sheet(item: $addRequest) { request in
            AddRestaurantView(
                isPresented: Binding(get: { addRequest != nil }, set: { if !$0 { addRequest = nil } }),
                initialPlace: request.place, initialName: request.name
            )
            .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .sheet(isPresented: $showJoinCircle) {
            JoinCircleSheet().presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .sheet(isPresented: $showBulkImport) {
            BulkImportView(isPresented: $showBulkImport)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .sheet(isPresented: $showFilter) {
            FilterSheetView(isPresented: $showFilter, currentFilter: appState.filterState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .fullScreenCover(item: $selectedRestaurant) { r in
            RestaurantDetailView(restaurantId: r.id)
                .environment(appState)
        }
    }

    private var visibleRestaurants: [Restaurant] {
        appState.filteredRestaurants.filter { WishlistSearch.matches($0, query: search) }
    }

    private var wishlistContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let circle = appState.activeCircle {
                    ZStack(alignment: .trailing) {
                        CircleSwitcherPill(circle: circle, onTap: { showCirclePicker = true })
                        Menu {
                            Button("Add a restaurant", systemImage: "plus") { showAddRestaurant = true }
                            Button("Import a list", systemImage: "text.badge.plus") { showBulkImport = true }
                            #if DEBUG
                                Button("Test social import", systemImage: "music.note") {
                                    appState.loadDebugTikTokImport()
                                }
                            #endif
                        } label: {
                            Image(systemName: "plus").font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Atlas.paper).frame(width: 44, height: 44)
                                .background(Atlas.ink).clipShape(Circle())
                        }
                        .accessibilityLabel("Add or import restaurants")
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 12)
                }
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        (Text("Your ") + Text("places.").italic().foregroundColor(Atlas.burnt))
                            .font(Atlas.Font.serif(34)).foregroundStyle(Atlas.ink)
                        Text("A little list of good things to come.")
                            .font(Atlas.Font.sans(12.5)).foregroundStyle(Atlas.ink2)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Atlas.ink2)
                        TextField("Search restaurants and cafés", text: $search)
                            .font(Atlas.Font.sans(14)).foregroundStyle(Atlas.ink)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Search all restaurants")
                            .focused($searchIsFocused).submitLabel(.search)
                            .onSubmit { searchIsFocused = false }
                        if !search.isEmpty {
                            Button {
                                search = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .accessibilityLabel("Clear search").foregroundStyle(Atlas.ink2)
                        }
                    }
                    .padding(.horizontal, 14).frame(minHeight: 46)
                    .background(Atlas.paper2.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 14))
                    if !searching { WishlistTabRow() }
                    if appState.activeTab == .wantToTry, appState.wantToTryCount > 0,
                        let circle = appState.activeCircle,
                        search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        !appState.filterState.isActive
                    {
                        WishlistTogetherCard(members: circle.members, count: appState.wantToTryCount) {
                            if appState.wantToTryCount == 0 {
                                showAddRestaurant = true
                            } else if circle.members.count < 2 {
                                showCirclePicker = true
                            } else {
                                appState.navigate(to: .pick)
                            }
                        }
                    }
                    if !searching {
                        HStack {
                            Text(
                                "\(appState.activeTab == .visited ? "YOUR VISITS" : "YOUR SHORTLIST") · \(visibleRestaurants.count)"
                            )
                            .font(Atlas.Font.sans(10.5, weight: .medium)).kerning(1.1).foregroundStyle(Atlas.ink2)
                            Spacer(minLength: 8)
                            Button {
                                showFilter = true
                            } label: {
                                Label(
                                    appState.filterState.isActive ? "Filtered" : "Filters",
                                    systemImage: "slider.horizontal.3"
                                )
                                .font(Atlas.Font.sans(12)).foregroundStyle(Atlas.burnt)
                                .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            if appState.filterState.isActive {
                                Button("Clear") { appState.filterState.reset() }
                                    .font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink2)
                            }
                        }
                    }
                }
                .padding(.horizontal, Atlas.screenHPad).padding(.top, 22)

                if searching {
                    discoveryContent.padding(.horizontal, Atlas.screenHPad)
                } else if appState.isLoadingRestaurants && appState.restaurants.isEmpty {
                    ProgressView().tint(Atlas.burnt).frame(maxWidth: .infinity).padding(30)
                } else if visibleRestaurants.isEmpty {
                    if !search.isEmpty || appState.filterState.isActive {
                        VStack(spacing: 12) {
                            Text("No places found").font(Atlas.Font.serif(24))
                            Button("Clear search and filters") {
                                search = ""
                                appState.filterState.reset()
                            }
                            .font(Atlas.Font.sans(13)).foregroundStyle(Atlas.burnt)
                        }.frame(maxWidth: .infinity).padding(24)
                    } else {
                        EmptyWishlistView(showAdd: $showAddRestaurant, showBulk: $showBulkImport)
                            .padding(.horizontal, Atlas.screenHPad).padding(.top, 24)
                    }
                } else {
                    ForEach(visibleRestaurants) { restaurant in
                        WishlistRestaurantRow(restaurant: restaurant, refreshId: photoRefreshId) {
                            searchIsFocused = false
                            selectedRestaurant = restaurant
                        }
                    }.padding(.horizontal, Atlas.screenHPad)
                }
                Spacer().frame(height: Atlas.listBottomPad)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await appState.loadRestaurants()
            photoRefreshId += 1
        }
        .onChange(of: appState.activeCircle?.id) { _, _ in
            search = ""
            searchIsFocused = false
        }
        .task(id: discoveryRequest) {
            guard !Task.isCancelled else { return }
            let request = discoveryRequest
            loadedDiscovery = request
            await discovery.load(query: request.user != nil && request.circle != nil ? request.query : "") {
                await PlacesService.shared.search(query: $0, near: appState.location.userLocation)
            }
        }
    }

    private var discoveryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !savedSearchResults.isEmpty {
                Text("IN YOUR CIRCLE").font(Atlas.Font.sans(10.5, weight: .medium)).kerning(1.1)
                    .foregroundStyle(Atlas.ink2).padding(.top, 22)
                ForEach(savedSearchResults) { restaurant in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(restaurant.status == .visited ? "Visited" : "Saved")
                            .font(Atlas.Font.sans(11, weight: .medium)).foregroundStyle(Atlas.burnt)
                        WishlistRestaurantRow(restaurant: restaurant, refreshId: photoRefreshId) {
                            searchIsFocused = false
                            selectedRestaurant = restaurant
                        }
                    }
                }
            }
            HStack {
                Text("FIND A RESTAURANT").font(Atlas.Font.sans(10.5, weight: .medium)).kerning(1.1)
                    .foregroundStyle(Atlas.ink2)
                Spacer()
                if !newSearchResults.isEmpty {
                    Text(newSearchResults.contains(where: { $0.provider == .google }) ? "Google Maps" : "Apple Maps")
                        .font(.system(size: 12)).foregroundStyle(Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255))
                }
            }.padding(.top, 22)
            if search.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                Text("Type at least two characters to find places beyond your list.")
                    .font(Atlas.Font.sans(13)).foregroundStyle(Atlas.ink2)
            } else if loadedDiscovery != discoveryRequest || discovery.isLoading {
                HStack {
                    ProgressView().tint(Atlas.burnt)
                    Text("Finding places…").font(Atlas.Font.sans(13))
                }
                .padding(.vertical, 16)
            } else if newSearchResults.isEmpty {
                Text(
                    discovered.isEmpty
                        ? "No other places found. Try a name with a city, or add it manually."
                        : "Matching places are already in your circle."
                )
                .font(Atlas.Font.sans(13)).foregroundStyle(Atlas.ink2)
            }
            ForEach(newSearchResults) { place in
                Button {
                    searchIsFocused = false
                    // Recheck current state at selection time: another member may have saved it meanwhile.
                    if let saved = SavedPlaceMatch.restaurant(
                        for: place, in: appState.restaurants, circleId: appState.activeCircle?.id)
                    {
                        selectedRestaurant = saved
                    } else {
                        addRequest = AddRequest(place: place)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.and.ellipse").foregroundStyle(Atlas.burnt).frame(width: 24)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(place.name).font(Atlas.Font.serif(20)).foregroundStyle(Atlas.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if let address = place.address {
                                Text(address).font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                        Text("Add").font(Atlas.Font.sans(12, weight: .semibold)).foregroundStyle(Atlas.burnt)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 14).contentShape(Rectangle())
                }.buttonStyle(.plain)
                if let attribution = place.attribution {
                    Text(attribution).font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink2).tint(Atlas.burnt)
                }
                Rectangle().fill(Atlas.rule).frame(height: 1)
            }
            Button("Add \"\(search.trimmingCharacters(in: .whitespacesAndNewlines))\" manually") {
                searchIsFocused = false
                addRequest = AddRequest(name: search.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .font(Atlas.Font.sans(13, weight: .medium)).foregroundStyle(Atlas.burnt)
            .frame(minHeight: 44).padding(.top, 8)
        }
    }

}

// MARK: - No circle onboarding state

private struct NoCircleView: View {
    @Binding var showNewCircle: Bool
    @Binding var showJoinCircle: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ScoutBrandMark(size: 100)

            Spacer().frame(height: 32)

            Text("Start your atlas")
                .font(Atlas.Font.serif(30))
                .foregroundColor(Atlas.ink)

            Text("Create a circle to start tracking\nrestaurants with someone.")
                .font(Atlas.Font.sans(15))
                .foregroundColor(Atlas.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)
                .padding(.horizontal, 40)

            Spacer().frame(height: 40)

            Button {
                showNewCircle = true
            } label: {
                Text("Create a circle")
                    .font(Atlas.Font.sans(15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Atlas.burnt)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Atlas.screenHPad)

            Button("Join a circle") { showJoinCircle = true }
                .font(Atlas.Font.sans(15, weight: .semibold))
                .foregroundStyle(Atlas.burnt).padding(.top, 20)

            Spacer()
        }
    }
}

// MARK: - Want to try / Visited
private struct WishlistTabRow: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        HStack(spacing: 4) {
            tab("Want to try", count: appState.wantToTryCount, selected: appState.activeTab == .wantToTry) {
                appState.activeTab = .wantToTry
            }
            tab("Visited", count: appState.visitedCount, selected: appState.activeTab == .visited) {
                appState.activeTab = .visited
            }
        }
        .padding(4).background(Atlas.paper2).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private func tab(_ title: String, count: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(title) · \(count)")
                .font(Atlas.Font.sans(12.5, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Atlas.ink : Atlas.ink2)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(selected ? Atlas.paper : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Empty state

private struct EmptyWishlistView: View {
    @Binding var showAdd: Bool
    @Binding var showBulk: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Three placeholder polaroids
            HStack(spacing: -8) {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Atlas.paper2)
                        .frame(width: 68, height: 80)
                        .rotationEffect(.degrees(Double([-6, 0, 6][i])))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Atlas.rule, lineWidth: 1)
                        )
                }
            }
            .padding(.bottom, 4)

            Text("Your atlas starts here.")
                .font(Atlas.Font.serif(22))
                .foregroundColor(Atlas.ink)

            Text("Add your first restaurant to get started.")
                .font(Atlas.Font.sans(14))
                .foregroundColor(Atlas.ink2)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button("Add a restaurant") { showAdd = true }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .font(Atlas.Font.sans(14, weight: .semibold))
                    .foregroundColor(Atlas.paper)
                    .background(Atlas.ink)
                    .clipShape(Capsule())

                Button("Import a list") { showBulk = true }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .font(Atlas.Font.sans(14))
                    .foregroundColor(Atlas.ink2)
                    .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

#Preview("Populated") {
    WishlistView()
        .environment(AppState.preview)
}

#Preview("Empty") {
    let state = AppState.preview
    state.restaurants = []
    return WishlistView()
        .environment(state)
}
