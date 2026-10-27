import Foundation

/// Transient Google details, separate from the circle's persisted restaurant metadata.
struct PlaceContactDetails {
    enum OpenStatus: String {
        case open, closed, unknown, temporarilyClosed, permanentlyClosed

        var label: String {
            switch self {
            case .open: return "Open at last check"
            case .closed: return "Closed at last check"
            case .unknown: return "Live status unavailable"
            case .temporarilyClosed: return "Temporarily closed"
            case .permanentlyClosed: return "Permanently closed"
            }
        }
    }

    let websiteURL: URL?
    let phoneNumber: String?
    let weekdayText: [String]
    let openStatus: OpenStatus
    let checkedAt: Date
    let providerAttribution: AttributedString?

    init(websiteURL: URL? = nil, phoneNumber: String? = nil, weekdayText: [String] = [],
         openStatus: OpenStatus = .unknown, checkedAt: Date = Date(),
         providerAttribution: AttributedString? = nil) {
        self.websiteURL = websiteURL
        self.phoneNumber = phoneNumber
        self.weekdayText = weekdayText.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        self.openStatus = openStatus
        self.checkedAt = checkedAt
        self.providerAttribution = providerAttribution
    }

    var hasDirectContact: Bool {
        websiteURL != nil || !(phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}
