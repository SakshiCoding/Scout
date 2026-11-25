import GooglePlaces
import SwiftUI

// Opt-in disposable Simulator app; no Scout login, database writes, or user data.
@main struct LivePlaceHoursCheck: App {
    var body: some Scene { WindowGroup { LiveHoursCheckView() } }
}

private struct LiveHoursCheckView: View {
    @State private var state = PlaceDetailsLoadState()
    var body: some View {
        ScrollView {
            RestaurantHoursCard(details: state.details, isLoading: state.isLoading,
                failed: state.failed, canLoad: true, refresh: {})
                .padding(20)
        }
        .background(Atlas.paper)
        .task {
            let service = PlacesService.shared
            let results = await service.search(query: "Dishoom Covent Garden London")
            guard let result = results.first(where: { $0.googlePlaceId != nil }), let id = result.googlePlaceId else {
                await searchDiagnostic()
                return
            }
            await state.load(placeId: id) { await service.contactDetails(placeId: $0) }
            guard let details = state.details else { await diagnostic(stage: "details"); return }
            report(["passed": details.weekdayText.count == 7 && details.openStatus != .unknown && details.hasDirectContact,
                    "stage": "complete", "weekdayRows": details.weekdayText.count,
                    "status": details.openStatus.rawValue, "hasContact": details.hasDirectContact,
                    "checkedAt": details.checkedAt.ISO8601Format()])
        }
    }

    private func searchDiagnostic() async {
        let values: [String: Any] = await withCheckedContinuation { continuation in
            let properties = [GMSPlaceProperty.name, .placeID, .formattedAddress, .coordinate, .types, .priceLevel].map(\.rawValue)
            let request = GMSPlaceSearchByTextRequest(textQuery: "Dishoom Covent Garden London", placeProperties: properties)
            request.maxResultCount = 5
            GMSPlacesClient.shared().searchByText(with: request) { result, error in
                let error = error as NSError?
                let message = (error?.localizedDescription ?? "No search error")
                    .replacingOccurrences(of: "AIza[0-9A-Za-z_-]+", with: "[REDACTED]", options: .regularExpression)
                continuation.resume(returning: ["passed": false, "stage": "search", "placeCount": result?.places?.count ?? 0,
                    "errorDomain": error?.domain ?? "none", "errorCode": error?.code ?? 0, "message": message])
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
