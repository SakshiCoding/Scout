import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @State private var selectedPin: Restaurant?
    @State private var navigatingTo: Restaurant?
    @State private var showFilters = false
    @State private var showCirclePicker = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasInitiallyLocated = false
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined

    private var mappableRestaurants: [Restaurant] {
        let base = appState.restaurants.filter { $0.coordinate != nil && appState.filterState.matches($0) }
        return appState.location.sortedByDistance(base)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            headerOverlay
        }
        .overlay(alignment: .bottom) {
            if let pin = selectedPin {
                MapPeekCard(restaurant: pin) {
                    navigatingTo = pin
                }
                .padding(.horizontal, 16)
                .padding(.bottom, Atlas.tabBarBottomOffset + Atlas.tabBarHeight + 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: selectedPin?.id)
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
        .sheet(isPresented: $showFilters) {
            FilterSheetView(isPresented: $showFilters, currentFilter: appState.filterState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .fullScreenCover(item: $navigatingTo) { r in
            RestaurantDetailView(restaurantId: r.id)
                .environment(appState)
        }
        .onAppear {
            locationAuthStatus = appState.location.authorizationStatus
        }
        .onReceive(appState.location.$authorizationStatus) { status in
            locationAuthStatus = status
        }
        .onReceive(appState.location.$userLocation) { newLoc in
            guard let loc = newLoc, !hasInitiallyLocated else { return }
            hasInitiallyLocated = true
            cameraPosition = .region(MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    private func locateUser() {
        switch locationAuthStatus {
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        case .notDetermined:
            appState.location.requestWhenInUse()
        default:
            guard let loc = appState.location.userLocation else {
                appState.location.startUpdating()
                return
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(mappableRestaurants) { r in
                Annotation("", coordinate: r.coordinate!, anchor: .bottom) {
                    RestaurantPinView(
                        name: r.name,
                        isSelected: selectedPin?.id == r.id,
                        distance: r.formattedDistance,
                        accentColor: r.establishmentType.pinColor
                    )
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedPin = (selectedPin?.id == r.id) ? nil : r
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
        .mapControls { }
        .ignoresSafeArea()
    }

    // MARK: - Floating header

    private var headerOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 0) {
                if let circle = appState.activeCircle {
                    Button { showCirclePicker = true } label: {
                        HStack(spacing: 10) {
                            AvatarStack(
                                members: circle.members,
                                accentColor: circle.accentSwiftUIColor,
                                size: 24,
                                borderColor: Atlas.paper.opacity(0.9)
                            )
                            Text(circle.name)
                                .font(Atlas.Font.serif(15))
                                .foregroundColor(Atlas.ink)
                                .lineLimit(1)
                            ChevronDown(color: Atlas.ink2)
                        }
                        .padding(.leading, 6)
                        .padding(.trailing, 14)
                        .frame(height: Atlas.pillHeight)
                        .background(
                            Atlas.paper.opacity(0.85)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        )
                        .clipShape(Capsule())
                        .pillShadow(glass: true)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button { locateUser() } label: {
                    let isDenied = locationAuthStatus == .denied || locationAuthStatus == .restricted
                    Image(systemName: isDenied ? "location.slash.fill" : "location.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isDenied ? Atlas.ink3 : (appState.location.userLocation != nil ? Atlas.burnt : Atlas.ink3))
                        .frame(width: Atlas.pillHeight, height: Atlas.pillHeight)
                        .background(
                            Atlas.paper.opacity(0.85)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        )
                        .clipShape(Circle())
                        .pillShadow(glass: true)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)

                Button { showFilters = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Atlas.ink2)
                        Text("Filters")
                            .font(Atlas.Font.sans(12))
                            .foregroundColor(Atlas.ink2)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: Atlas.pillHeight)
                    .background(
                        Atlas.paper.opacity(0.85)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    )
                    .clipShape(Capsule())
                    .pillShadow(glass: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Count chip
            let count = mappableRestaurants.count
            HStack {
                Text(countChipText(count))
                    .font(Atlas.Font.sans(11.5))
                    .foregroundColor(Atlas.ink2)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(
                        Atlas.paper.opacity(0.85)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    )
                    .clipShape(Capsule())
                    .shadow(
                        color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.10),
                        radius: 6, x: 0, y: 4
                    )
                Spacer()
            }
            .padding(.leading, 16)
        }
    }

    private func countChipText(_ count: Int) -> String {
        let base = "\(count) place\(count == 1 ? "" : "s")"
        return appState.filterState.isActive ? "\(base) · Filtered" : base
    }
}

// MARK: - Custom pin annotation

private struct RestaurantPinView: View {
    let name: String
    var isSelected: Bool = false
    var distance: String?
    var accentColor: Color = Atlas.burnt

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
                Text(name)
                    .font(Atlas.Font.sans(11.5, weight: .semibold))
                    .foregroundColor(isSelected ? Atlas.paper : Atlas.ink)
                    .lineLimit(1)
                    .fixedSize()
                if isSelected, let dist = distance {
                    Text("\(dist) mi")
                        .font(Atlas.Font.serif(12, italic: true))
                        .foregroundColor(Atlas.paper.opacity(0.8))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Atlas.ink : Atlas.paper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Atlas.ink : Atlas.rule, lineWidth: 1)
            )
            .shadow(
                color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.18),
                radius: 6, x: 0, y: 4
            )

            Rectangle()
                .fill(isSelected ? Atlas.ink : Atlas.rule)
                .frame(width: 2, height: 8)

            Circle()
                .fill(accentColor)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Establishment type pin colors

private extension Restaurant.EstablishmentType {
    var pinColor: Color {
        switch self {
        case .restaurant: return Atlas.burnt
        case .cafe:       return Atlas.accentSage
        case .bar:        return Atlas.accentSlate
        case .bakery:     return Atlas.orange
        case .brewery:    return Color(red: 0.55, green: 0.35, blue: 0.15)
        case .winery:     return Color(red: 0.55, green: 0.15, blue: 0.30)
        case .other:      return Atlas.ink2
        }
    }
}

// MARK: - Bottom peek card

private struct MapPeekCard: View {
    let restaurant: Restaurant
    var onNavigate: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Atlas.paper2)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Atlas.ink3)
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(restaurant.name)
                    .font(Atlas.Font.serif(19))
                    .foregroundColor(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                let parts = [
                    restaurant.cuisine,
                    restaurant.priceTier?.rawValue,
                    restaurant.formattedDistance.map { "\($0) mi" }
                ].compactMap { $0 }
                if !parts.isEmpty {
                    Text(parts.joined(separator: " · "))
                        .font(Atlas.Font.sans(12))
                        .foregroundColor(Atlas.ink2)
                        .padding(.top, 4)
                }

                StatusDot(status: .open)
                    .padding(.top, 6)
            }

            Spacer()

            Button(action: onNavigate) {
                Circle()
                    .fill(Atlas.burnt)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Atlas.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(
            color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.18),
            radius: 24, x: 0, y: 18
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Atlas.ink.opacity(0.06), lineWidth: 1)
        )
    }
}
