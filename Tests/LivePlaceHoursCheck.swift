import GooglePlaces
import SwiftUI
import UIKit

// Opt-in disposable Simulator app; no Scout login, database writes, or user data.
@MainActor private final class LivePlacesDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = PlacesService.shared
        return true
    }
}
@main struct LivePlaceHoursCheck: App {
    @UIApplicationDelegateAdaptor(LivePlacesDelegate.self) private var delegate
    var body: some Scene { WindowGroup { LiveHoursCheckView() } }
}

private struct LiveHoursCheckView: View {
    @State private var state = PlaceDetailsLoadState()
    @State private var discovery = RestaurantDiscoveryState()
    @State private var photo: PlacePhoto?
    var body: some View {
        ScrollView {
            if let photo {
                Image(photo.image, scale: 1, label: Text("Live Google restaurant photo"))
                    .resizable().scaledToFit().frame(maxHeight: 300)
                PlacePhotoCredits(photo: photo)
            }
            RestaurantHoursCard(details: state.details, isLoading: state.isLoading,
                failed: state.failed, canLoad: true, refresh: {})
                .padding(20)
        }
        .background(Atlas.paper)
        .task {
            let service = PlacesService.shared
            await discovery.load(query: "Dishoom Covent Garden London") {
                await service.search(query: $0)
            }
            let results = discovery.results
            guard let result = results.first(where: { $0.googlePlaceId != nil }), let id = result.googlePlaceId else {
                await searchDiagnostic()
                return
            }
            if ProcessInfo.processInfo.arguments.contains("--discovery-only") {
                report(["passed": discovery.didSearch && !discovery.isLoading && !result.name.isEmpty && result.address != nil,
                        "stage": "discovery", "results": results.count, "hasPlaceId": !id.isEmpty,
                        "hasAddress": result.address != nil])
                return
            }
            await state.load(placeId: id) { await service.contactDetails(placeId: $0) }
            guard let details = state.details else { await diagnostic(stage: "details"); return }
            photo = await service.photo(placeId: id)
            report(["passed": details.weekdayText.count == 7 && details.openStatus != .unknown && details.hasDirectContact && photo != nil && !(photo?.authors.isEmpty ?? true),
                    "photoWidth": photo?.image.width ?? 0, "photoHeight": photo?.image.height ?? 0,
                    "photoAuthors": photo?.authors.count ?? 0,
                    "discoveryResults": results.count, "discoveryReady": discovery.didSearch && !discovery.isLoading,
                    "stage": "complete", "weekdayRows": details.weekdayText.count,
                    "status": details.openStatus.rawValue, "hasContact": details.hasDirectContact,
                    "checkedAt": details.checkedAt.ISO8601Format()])
        }
    }

    private func searchDiagnostic() async {
        let didSearch = discovery.didSearch
        let resultCount = discovery.results.count
        let canceled = Task.isCancelled
        let values: [String: Any] = await withCheckedContinuation { continuation in
            let properties = [GMSPlaceProperty.name, .placeID, .formattedAddress, .coordinate, .types, .priceLevel].map(\.rawValue)
            let request = GMSPlaceSearchByTextRequest(textQuery: "Dishoom Covent Garden London", placeProperties: properties)
            request.maxResultCount = 5
            GMSPlacesClient.shared().searchByText(with: request) { result, error in
                let error = error as NSError?
                let message = (error?.localizedDescription ?? "No search error")
                    .replacingOccurrences(of: "AIza[0-9A-Za-z_-]+", with: "[REDACTED]", options: .regularExpression)
                continuation.resume(returning: ["passed": false, "stage": "search", "placeCount": result?.places?.count ?? 0,
                    "errorDomain": error?.domain ?? "none", "errorCode": error?.code ?? 0, "message": message,
                    "taskCancelled": canceled, "didSearch": didSearch, "discoveryCount": resultCount])
            }
        }
        report(values)
    }

    private func diagnostic(stage: String) async {
        let values: [String: Any] = await withCheckedContinuation { continuation in
            let request = GMSFetchPlaceRequest(placeID: "ChIJV4k8_9UodTERU5KXbkYpSYs",
                placeProperties: [GMSPlaceProperty.placeID.rawValue], sessionToken: nil)
            GMSPlacesClient.shared().fetchPlace(with: request) { _, error in
                let error = error as NSError?
                let message = (error?.localizedDescription ?? "Basic lookup succeeded; inspect the requested detail fields")
                    .replacingOccurrences(of: "AIza[0-9A-Za-z_-]+", with: "[REDACTED]", options: .regularExpression)
                continuation.resume(returning: ["passed": false, "stage": stage,
                    "errorDomain": error?.domain ?? "none", "errorCode": error?.code ?? 0, "message": message])
            }
        }
        report(values)
    }

    private func report(_ value: [String: Any]) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("hours-report.json")
        try? JSONSerialization.data(withJSONObject: value, options: .sortedKeys).write(to: url)
    }
}
