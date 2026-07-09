import SwiftUI
import CoreLocation
import GoogleMaps
import UIKit

struct MapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @State private var selectedPin: Restaurant?
    @State private var navigatingTo: Restaurant?
    @State private var showFilters = false
    @State private var showCirclePicker = false
    @State private var cameraRequest = GoogleMapCameraRequest(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        zoom: 12
    )
    @State private var hasInitiallyLocated = false
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    @State private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var mapZoom: Float = 12

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
        .overlay(alignment: .bottomTrailing) {
            zoomControls
                .padding(.trailing, 16)
                .padding(.bottom, Atlas.tabBarBottomOffset + Atlas.tabBarHeight + (selectedPin != nil ? 114 : 16))
                .animation(.spring(duration: 0.3), value: selectedPin?.id)
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
            appState.location.startUpdating()
        }
        .onReceive(appState.location.$authorizationStatus) { status in
            locationAuthStatus = status
        }
        .onReceive(appState.location.$userLocation) { newLoc in
            guard let loc = newLoc, !hasInitiallyLocated else { return }
            hasInitiallyLocated = true
            cameraRequest = GoogleMapCameraRequest(center: loc.coordinate, zoom: 13)
        }
    }

    private func locateUser() {
        switch locationAuthStatus {
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        case .notDetermined:
            appState.location.requestCurrentLocation()
        default:
            guard let loc = appState.location.userLocation else {
                appState.location.requestCurrentLocation()
                return
            }
            cameraRequest = GoogleMapCameraRequest(center: loc.coordinate, zoom: max(mapZoom, 13))
        }
    }

    private func zoomIn() {
        cameraRequest = GoogleMapCameraRequest(center: mapCenter, zoom: min(mapZoom + 1, 21))
    }

    private func zoomOut() {
        cameraRequest = GoogleMapCameraRequest(center: mapCenter, zoom: max(mapZoom - 1, 2))
    }

    private var zoomControls: some View {
        VStack(spacing: 0) {
            Button(action: zoomIn) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Atlas.ink)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            Divider()
                .frame(width: 22)
                .background(Atlas.rule)
            Button(action: zoomOut) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Atlas.ink)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .background(
            Atlas.paper.opacity(0.85)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .pillShadow(glass: true)
    }

    // MARK: - Map

    @ViewBuilder
    private var mapLayer: some View {
        if GoogleMapsConfiguration.configureIfPossible() {
            GoogleRestaurantMap(
                restaurants: mappableRestaurants,
                selectedRestaurant: $selectedPin,
                cameraRequest: cameraRequest,
                mapCenter: $mapCenter,
                mapZoom: $mapZoom,
                showsUserLocation: locationAuthStatus == .authorizedWhenInUse || locationAuthStatus == .authorizedAlways
            )
            .ignoresSafeArea()
        } else {
            Atlas.paper
                .ignoresSafeArea()
                .overlay {
                    Text("Add a Google Maps API key to show the map.")
                        .font(Atlas.Font.sans(13))
                        .foregroundColor(Atlas.ink2)
                        .padding(24)
                }
        }
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

private struct GoogleMapCameraRequest: Equatable {
    let id = UUID()
    let center: CLLocationCoordinate2D
    let zoom: Float

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

private struct GoogleRestaurantMap: UIViewRepresentable {
    let restaurants: [Restaurant]
    @Binding var selectedRestaurant: Restaurant?
    let cameraRequest: GoogleMapCameraRequest
    @Binding var mapCenter: CLLocationCoordinate2D
    @Binding var mapZoom: Float
    let showsUserLocation: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withTarget: cameraRequest.center,
            zoom: cameraRequest.zoom
        )
        let options = GMSMapViewOptions()
        options.camera = camera
        options.backgroundColor = UIColor(Atlas.paper)
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.mapType = .normal
        mapView.isBuildingsEnabled = false
        mapView.settings.compassButton = false
        mapView.settings.myLocationButton = false
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        mapView.padding = UIEdgeInsets(top: 110, left: 0, bottom: 110, right: 0)
        context.coordinator.renderMarkers(on: mapView)
        context.coordinator.lastCameraRequestId = cameraRequest.id
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.parent = self
        mapView.isMyLocationEnabled = showsUserLocation
        context.coordinator.renderMarkers(on: mapView)

        guard context.coordinator.lastCameraRequestId != cameraRequest.id else { return }
        context.coordinator.lastCameraRequestId = cameraRequest.id
        mapView.animate(to: GMSCameraPosition.camera(
            withTarget: cameraRequest.center,
            zoom: cameraRequest.zoom
        ))
    }

    @MainActor
    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleRestaurantMap
        var lastCameraRequestId: UUID?

        init(parent: GoogleRestaurantMap) {
            self.parent = parent
        }

        func renderMarkers(on mapView: GMSMapView) {
            mapView.clear()

            for restaurant in parent.restaurants {
                guard let coordinate = restaurant.coordinate else { continue }
                let marker = GMSMarker(position: coordinate)
                marker.userData = restaurant.id
                marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                marker.icon = markerImage(
                    for: restaurant,
                    isSelected: parent.selectedRestaurant?.id == restaurant.id
                )
                marker.map = mapView
            }
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let restaurantId = marker.userData as? UUID,
                  let restaurant = parent.restaurants.first(where: { $0.id == restaurantId }) else {
                return false
            }
            withAnimation(.spring(duration: 0.25)) {
                parent.selectedRestaurant = parent.selectedRestaurant?.id == restaurantId ? nil : restaurant
            }
            renderMarkers(on: mapView)
            return true
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            if parent.selectedRestaurant != nil {
                withAnimation(.spring(duration: 0.25)) {
                    parent.selectedRestaurant = nil
                }
                renderMarkers(on: mapView)
            }
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            parent.mapCenter = position.target
            parent.mapZoom = position.zoom
        }

        private func markerImage(for restaurant: Restaurant, isSelected: Bool) -> UIImage? {
            let renderer = ImageRenderer(content:
                RestaurantPinView(
                    name: restaurant.name,
                    isSelected: isSelected,
                    distance: restaurant.formattedDistance,
                    accentColor: restaurant.establishmentType.pinColor
                )
                .padding(8)
            )
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }
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
