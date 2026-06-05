import Foundation
import GoogleMaps

enum GoogleMapsConfiguration {
    private static var hasConfigured = false

    @MainActor
    static func configureIfPossible(bundle: Bundle = .main) -> Bool {
        if hasConfigured { return true }

        let configuredKey = (bundle.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let apiKey = configuredKey,
              !apiKey.isEmpty,
              !apiKey.hasPrefix("$(") else {
            return false
        }

        hasConfigured = GMSServices.provideAPIKey(apiKey)
        return hasConfigured
    }
}
