import SwiftUI

struct WishlistView: View {
    @Environment(AppState.self) private var appState
    @State private var showCirclePicker   = false
    @State private var showAddRestaurant  = false
    @State private var showBulkImport     = false
    @State private var showFilter         = false
    @State private var selectedRestaurant: Restaurant?

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()

            if appState.isLoadingAuth {
                ProgressView().tint(Atlas.burnt)
            } else if appState.activeCircle == nil {
                NoCircleView(showNewCircle: $showCirclePicker)
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

    private var wishlistContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                // Circle switcher pill
                if let circle = appState.activeCircle {
                    CircleSwitcherPill(
                        circle: circle,
                        onTap: { showCirclePicker = true },
                        onOverflow: { /* future actions */ }
                    )
                    .padding(.top, 46)
                }

                // Masthead
                WishlistMasthead()
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.top, 14)

                // Want to try / Visited toggle
                WishlistTabRow()
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.top, 4)

                // Filter chips + add buttons row
                WishlistActionsRow(
                    showFilter: $showFilter,
                    showAdd: $showAddRestaurant,
                    showBulk: $showBulkImport
                )
                .padding(.top, 14)
                .padding(.bottom, 14)

                // Restaurant rows
                if appState.isLoadingRestaurants {
                    ProgressView()
                        .tint(Atlas.burnt)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if appState.filteredRestaurants.isEmpty {
                    EmptyWishlistView(
                        showAdd: $showAddRestaurant,
                        showBulk: $showBulkImport
                    )
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.top, 32)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(appState.filteredRestaurants.enumerated()), id: \.element.id) { i, r in
                            Button { selectedRestaurant = r } label: {
                                RestaurantRowView(restaurant: r, index: i + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Atlas.screenHPad)
                }

                Spacer().frame(height: Atlas.listBottomPad)
            }
        }
    }
}

// MARK: - No circle onboarding state

private struct NoCircleView: View {
    @Binding var showNewCircle: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Atlas.burnt.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(Atlas.burnt.opacity(0.06), lineWidth: 1)
                    .frame(width: 100, height: 100)
                Text("S")
                    .font(Atlas.Font.serif(48))
                    .foregroundColor(Atlas.burnt)
            }

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

            Button { showNewCircle = true } label: {
                Text("Create a circle")
                    .font(Atlas.Font.sans(15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Atlas.burnt)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Atlas.screenHPad)

            Spacer()
        }
    }
}

// MARK: - Masthead

private struct WishlistMasthead: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let circle = appState.activeCircle {
                CircleAccentRule(circle: circle)
            }

            // "Your atlas" — italic "atlas" in burnt orange
            (Text("Your ") + Text("atlas").italic().foregroundColor(Atlas.burnt))
                .font(Atlas.Font.serif(44))
                .foregroundColor(Atlas.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 10)

            // Subtitle
            let count       = appState.wantToTryCount
            let neighborhood = appState.location.currentNeighborhood ?? "your area"
            Text("\(count) place\(count == 1 ? "" : "s") to try · sorted by distance from \(neighborhood)")
                .font(Atlas.Font.sans(13.5))
                .foregroundColor(Atlas.ink2)
                .padding(.top, 8)
        }
    }
}

// MARK: - Want to try / Visited toggle

private struct WishlistTabRow: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            TabRowButton(
                label: "Want to try",
                count: appState.wantToTryCount,
                isActive: appState.activeTab == .wantToTry
            ) { appState.activeTab = .wantToTry }

            Spacer().frame(width: 28)

            TabRowButton(
                label: "Visited",
                count: appState.visitedCount,
                isActive: appState.activeTab == .visited
            ) { appState.activeTab = .visited }

            Spacer()
        }
        .overlay(alignment: .bottom) {
            Divider().background(Atlas.rule)
        }
    }
}

private struct TabRowButton: View {
    let label: String
    let count: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(Atlas.Font.sans(13, weight: isActive ? .semibold : .medium))
                        .foregroundColor(isActive ? Atlas.ink : Atlas.ink3)
                    Text("\(count)")
                        .font(Atlas.Font.sans(13))
                        .foregroundColor(Atlas.ink3)
                }
                .padding(.vertical, 12)

                Rectangle()
                    .fill(isActive ? Atlas.burnt : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter chips + action buttons row

private struct WishlistActionsRow: View {
    @Environment(AppState.self) private var appState
    @Binding var showFilter: Bool
    @Binding var showAdd: Bool
    @Binding var showBulk: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Spacer().frame(width: Atlas.screenHPad - 6)

                // Filter chip — "All" or active filter count
                FilterChip(
                    label: appState.filterState.isActive ? "Filtered" : "All",
                    isActive: appState.filterState.isActive
                ) { showFilter = true }

                FilterChip(label: "Add", isActive: false) { showAdd = true }
                FilterChip(label: "Import list", isActive: false) { showBulk = true }

                if appState.filterState.isActive {
                    FilterChip(label: "Clear", isActive: false) {
                        appState.filterState.reset()
                    }
                }

                Spacer().frame(width: Atlas.screenHPad - 6)
            }
        }
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
