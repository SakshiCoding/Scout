import CoreLocation
import Combine
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentNeighborhood: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate          = self
        manager.desiredAccuracy   = kCLLocationAccuracyHundredMeters
        manager.distanceFilter    = 100  // only update after moving 100m
        authorizationStatus       = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else { return }
        manager.startUpdatingLocation()
    }

    // Returns distance in miles from user to a coordinate
    func distance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLoc = userLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLoc.distance(from: target) / 1609.344
    }

    // Returns the array with distanceMiles populated and sorted nearest-first
    func sortedByDistance(_ restaurants: [Restaurant]) -> [Restaurant] {
        var result = restaurants
        for i in result.indices {
            if let coord = result[i].coordinate {
                result[i].distanceMiles = distance(to: coord)
            }
        }
        return result.sorted {
            switch ($0.distanceMiles, $1.distanceMiles) {
            case let (a?, b?): return a < b
            case (nil, _):     return false
            case (_, nil):     return true
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            Task { @MainActor in
                self.currentNeighborhood = placemark.subLocality
                    ?? placemark.locality
                    ?? placemark.administrativeArea
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            userLocation = loc
            if currentNeighborhood == nil {
                reverseGeocode(loc)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let clError = error as? CLError, clError.code == .denied else { return }
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            manager.stopUpdatingLocation()
        }
    }
}
