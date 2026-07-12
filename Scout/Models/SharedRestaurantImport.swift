import CoreLocation
import Foundation

struct SharedRestaurantImport: Codable, Identifiable, Equatable {
    enum SourceApp: String, Codable {
        case appleMaps
        case googleMaps
        case tiktok
        case instagram
        case social
        case safari
        case other
    }

    let id: UUID
    var sourceURL: URL?
    var sourceText: String?
    var sourceTitle: String?
    var name: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var sourceApp: SourceApp
    var capturedAt: Date

    init(
        id: UUID = UUID(),
        sourceURL: URL? = nil,
        sourceText: String? = nil,
        sourceTitle: String? = nil,
        name: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        sourceApp: SourceApp = .other,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceText = sourceText
        self.sourceTitle = sourceTitle
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.sourceApp = sourceApp
        self.capturedAt = capturedAt
    }

    var coordinate: CLLocation? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    var searchQuery: String {
        [name, address, sourceTitle, sourceText?.firstCandidateLine]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty }
            .first ?? sourceURL?.absoluteString ?? ""
    }
}

enum SharedImportStore {
    static let appGroupIdentifier = "group.com.sakshisangani.Scout"
    static let pendingImportKey = "scout.pendingRestaurantImport"

    static func save(_ pendingImport: SharedRestaurantImport) throws {
        let data = try JSONEncoder().encode(pendingImport)
        defaults.set(data, forKey: pendingImportKey)
    }

    static func load() -> SharedRestaurantImport? {
        guard let data = defaults.data(forKey: pendingImportKey) else { return nil }
        return try? JSONDecoder().decode(SharedRestaurantImport.self, from: data)
    }

    static func clear() {
        defaults.removeObject(forKey: pendingImportKey)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    var firstCandidateLine: String? {
        removingURLs
            .components(separatedBy: .newlines)
            .map(\.socialCandidateLine)
            .first { !$0.isEmpty && !$0.lowercased().hasPrefix("http") }
    }

    var socialCandidateLine: String {
        var line = trimmingCharacters(in: .whitespacesAndNewlines)
        for token in ["#"] {
            if let range = line.range(of: token) {
                line = String(line[..<range.lowerBound])
            }
        }
        return line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    private var removingURLs: String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return self
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        return detector
            .matches(in: self, range: range)
            .reversed()
            .reduce(self) { text, match in
                guard let range = Range(match.range, in: text) else { return text }
                var edited = text
                edited.removeSubrange(range)
                return edited
            }
    }
}
