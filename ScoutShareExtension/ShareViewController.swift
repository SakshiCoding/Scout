import MapKit
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let detailLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private var pendingImport: SharedRestaurantImport?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await captureSharedContent() }
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)

        statusLabel.text = "Saving to Scout"
        statusLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        statusLabel.textColor = UIColor(red: 0.11, green: 0.09, blue: 0.07, alpha: 1)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.text = "Preparing this place for review..."
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = UIColor(red: 0.11, green: 0.09, blue: 0.07, alpha: 0.62)
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        openButton.setTitle("Open Scout", for: .normal)
        openButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        openButton.tintColor = .white
        openButton.backgroundColor = UIColor(red: 0.80, green: 0.33, blue: 0.00, alpha: 1)
        openButton.layer.cornerRadius = 24
        openButton.isHidden = true
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.addTarget(self, action: #selector(openScout), for: .touchUpInside)

        view.addSubview(statusLabel)
        view.addSubview(detailLabel)
        view.addSubview(openButton)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),

            detailLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),

            openButton.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            openButton.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            openButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 24),
            openButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func captureSharedContent() async {
        let captured = await SharedContentReader(extensionContext: extensionContext).read()
        let importPayload = await SharedImportParser.payload(from: captured)

        do {
            try SharedImportStore.save(importPayload)
            pendingImport = importPayload
            statusLabel.text = "Ready in Scout"
            detailLabel.text = importPayload.name ?? importPayload.sourceTitle ?? "Open Scout to confirm and save this place."
            openButton.isHidden = false
            openScout()
        } catch {
            statusLabel.text = "Could not save"
            detailLabel.text = "Open Scout and try sharing again."
            openButton.isHidden = true
        }
    }

    @objc private func openScout() {
        guard let url = URL(string: "scout://import-pending") else { return }
        extensionContext?.open(url) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}

private struct SharedContent {
    var url: URL?
    var text: String?
    var title: String?
    var mapItem: SharedMapItem?
}

private struct SharedMapItem {
    var name: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var url: URL?
}

private struct SharedContentReader {
    private let mapItemTypeIdentifier = "com.apple.mapkit.map-item"

    let extensionContext: NSExtensionContext?

    func read() async -> SharedContent {
        var content = SharedContent()
        let providers = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { item in
                item.attachments?.map { (item, $0) } ?? []
            } ?? []

        for (item, provider) in providers {
            content.title = content.title ?? item.attributedTitle?.string.nonEmpty ?? item.attributedContentText?.string.firstLine

            if content.url == nil, provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                content.url = await loadURL(from: provider)
            }
            if content.text == nil, provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                content.text = await loadText(from: provider)
            }
            if content.mapItem == nil, provider.hasItemConformingToTypeIdentifier(mapItemTypeIdentifier) {
                content.mapItem = await loadMapItem(from: provider)
            }
            if content.url != nil && content.text != nil && content.mapItem != nil { break }
        }

        if content.url == nil, let textURL = content.text?.firstURL {
            content.url = textURL
        }
        if content.url == nil, let mapURL = content.mapItem?.url {
            content.url = mapURL
        }
        if content.title == nil, let mapName = content.mapItem?.name {
            content.title = mapName
        }
        return content
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data,
                          let string = String(data: data, encoding: .utf8),
                          let url = URL(string: string) {
                    continuation.resume(returning: url)
                } else if let string = item as? String,
                          let url = URL(string: string) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let string = item as? String {
                    continuation.resume(returning: string)
                } else if let data = item as? Data {
                    continuation.resume(returning: String(data: data, encoding: .utf8))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadMapItem(from provider: NSItemProvider) async -> SharedMapItem? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: mapItemTypeIdentifier, options: nil) { item, _ in
                guard let mapItem = item as? MKMapItem else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: SharedMapItem(mapItem: mapItem))
            }
        }
    }
}

private extension SharedMapItem {
    init(mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        let addressParts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ]
            .compactMap { $0?.nonEmpty }
            .joined(separator: ", ")
            .nonEmpty

        self.init(
            name: mapItem.name?.nonEmpty,
            address: addressParts,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            url: mapItem.url
        )
    }
}

private enum SharedImportParser {
    nonisolated static func payload(from content: SharedContent) async -> SharedRestaurantImport {
        let resolvedURL = await resolveGoogleMapsRedirectIfNeeded(content.url)
        let parsingURL = resolvedURL ?? content.url
        let sourceApp: SharedRestaurantImport.SourceApp = content.mapItem == nil
            ? sourceApp(for: parsingURL ?? content.url)
            : .appleMaps
        let social = parseSocial(content: content, sourceApp: sourceApp)
        let appleMaps = parseAppleMaps(parsingURL)
        let googleMaps = parseGoogleMaps(parsingURL)
        let mapItem = content.mapItem.map {
            (name: $0.name, address: $0.address, latitude: $0.latitude, longitude: $0.longitude)
        } ?? (name: nil, address: nil, latitude: nil, longitude: nil)
        let maps: (name: String?, address: String?, latitude: Double?, longitude: Double?)
        if mapItem.name != nil || mapItem.address != nil || mapItem.latitude != nil {
            maps = mapItem
        } else if appleMaps.name != nil || appleMaps.address != nil || appleMaps.latitude != nil {
            maps = appleMaps
        } else {
            maps = googleMaps
        }
        let cleanedTitle = content.title?.shareCandidateLine
        let textLines = content.text?.linesWithoutURLs ?? []
        let inferredName = maps.name ?? social.name ?? cleanedTitle ?? textLines.first?.shareCandidateLine
        let inferredAddress = maps.address ?? textLines.dropFirst().first?.shareCandidateLine

        return SharedRestaurantImport(
            sourceURL: content.url,
            sourceText: content.text,
            sourceTitle: social.title ?? cleanedTitle,
            name: inferredName,
            address: inferredAddress,
            latitude: maps.latitude,
            longitude: maps.longitude,
            sourceApp: sourceApp
        )
    }

    nonisolated private static func resolveGoogleMapsRedirectIfNeeded(_ url: URL?) async -> URL? {
        guard let url, isGoogleMapsURL(url), url.host()?.lowercased().contains("goo.gl") == true else {
            return nil
        }

        if let resolved = await resolvedURL(for: url, method: "HEAD") {
            return resolved
        }
        return await resolvedURL(for: url, method: "GET")
    }

    nonisolated private static func resolvedURL(for url: URL, method: String) async -> URL? {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 3
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 3
        configuration.timeoutIntervalForResource = 3
        configuration.waitsForConnectivity = false
        let session = URLSession(configuration: configuration)

        do {
            let (_, response) = try await session.data(for: request)
            return response.url == url ? nil : response.url
        } catch {
            return nil
        }
    }

    nonisolated private static func sourceApp(for url: URL?) -> SharedRestaurantImport.SourceApp {
        guard let host = url?.host()?.lowercased() else { return .other }
        if host.contains("maps.apple.com") { return .appleMaps }
        if isGoogleMapsURL(url) { return .googleMaps }
        if host.contains("tiktok.com") { return .tiktok }
        if host.contains("instagram.com") { return .instagram }
        if isSocialURL(url) { return .social }
        return .safari
    }

    nonisolated private static func parseSocial(
        content: SharedContent,
        sourceApp: SharedRestaurantImport.SourceApp
    ) -> (name: String?, title: String?) {
        guard sourceApp == .tiktok || sourceApp == .instagram || sourceApp == .social else {
            return (nil, nil)
        }

        let candidateLines = [
            content.title,
            content.text
        ]
            .compactMap { $0 }
            .flatMap(\.socialCandidateLines)

        let bestLine = candidateLines.first
        let restaurantGuess = candidateLines
            .compactMap(\.restaurantNameGuess)
            .first
            ?? bestLine

        return (restaurantGuess, bestLine)
    }

    nonisolated private static func parseAppleMaps(_ url: URL?) -> (name: String?, address: String?, latitude: Double?, longitude: Double?) {
        guard let url,
              url.host()?.lowercased().contains("maps.apple.com") == true,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return (nil, nil, nil, nil)
        }

        let items = (components.queryItems ?? []).reduce(into: [String: String]()) { result, item in
            guard result[item.name] == nil, let value = item.value else { return }
            result[item.name] = value
        }
        let name = items["q"]?.shareCandidateLine
        let address = items["address"]?.shareCandidateLine
        let coordinate = items["ll"].flatMap(parseCoordinate) ?? items["sll"].flatMap(parseCoordinate)
        return (name, address, coordinate?.latitude, coordinate?.longitude)
    }

    nonisolated private static func parseGoogleMaps(_ url: URL?) -> (name: String?, address: String?, latitude: Double?, longitude: Double?) {
        guard let url, isGoogleMapsURL(url) else {
            return (nil, nil, nil, nil)
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = (components?.queryItems ?? []).reduce(into: [String: String]()) { result, item in
            guard result[item.name] == nil, let value = item.value else { return }
            result[item.name] = value
        }
        let queryName = items["q"] ?? items["query"] ?? items["destination"] ?? items["daddr"]
        let pathName = googleMapsPlaceName(from: url)
        let coordinate = googleMapsCoordinate(from: url)

        return (
            queryName?.googleMapsCandidateLine ?? pathName,
            nil,
            coordinate?.latitude,
            coordinate?.longitude
        )
    }

    nonisolated private static func isGoogleMapsURL(_ url: URL?) -> Bool {
        guard let url, let host = url.host()?.lowercased() else { return false }
        if host == "maps.app.goo.gl" || host == "goo.gl" { return true }
        if host.contains("google.") && url.path.lowercased().contains("/maps") { return true }
        return false
    }

    nonisolated private static func isSocialURL(_ url: URL?) -> Bool {
        guard let host = url?.host()?.lowercased() else { return false }
        return [
            "x.com",
            "twitter.com",
            "threads.net",
            "facebook.com",
            "fb.watch",
            "youtube.com",
            "youtu.be"
        ].contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    nonisolated private static func googleMapsPlaceName(from url: URL) -> String? {
        let parts = url.path
            .split(separator: "/")
            .map(String.init)

        guard let placeIndex = parts.firstIndex(where: { $0.lowercased() == "place" }),
              parts.indices.contains(placeIndex + 1) else {
            return nil
        }

        return parts[placeIndex + 1].googleMapsCandidateLine
    }

    nonisolated private static func googleMapsCoordinate(from url: URL) -> (latitude: Double, longitude: Double)? {
        let path = url.path.removingPercentEncoding ?? url.path
        guard let atRange = path.range(of: "@") else { return nil }
        let afterAt = path[atRange.upperBound...]
        let parts = afterAt.split(separator: ",", maxSplits: 2).compactMap { Double($0) }
        guard parts.count >= 2 else { return nil }
        return (parts[0], parts[1])
    }

    nonisolated private static func parseCoordinate(_ raw: String) -> (latitude: Double, longitude: Double)? {
        let parts = raw.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var firstLine: String? {
        linesWithoutURLs.first
    }

    var linesWithoutURLs: [String] {
        removingURLs
            .components(separatedBy: .newlines)
            .flatMap(\.splitSocialCaption)
            .map(\.shareCandidateLine)
            .filter { !$0.isEmpty && !$0.lowercased().hasPrefix("http") }
    }

    var shareCandidateLine: String {
        let trimmed = removingPercentEncoding ?? self
        return trimmed
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    var googleMapsCandidateLine: String {
        let decoded = (removingPercentEncoding ?? self)
            .replacingOccurrences(of: "+", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        return decoded.shareCandidateLine
    }

    var socialCandidateLines: [String] {
        removingURLs
            .components(separatedBy: .newlines)
            .flatMap(\.splitSocialCaption)
            .map(\.socialCandidateLine)
            .filter(\.isUsefulSocialLine)
    }

    var socialCandidateLine: String {
        var line = shareCandidateLine
        for token in ["#"] {
            if let range = line.range(of: token) {
                line = String(line[..<range.lowerBound])
            }
        }
        return line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    var restaurantNameGuess: String? {
        let lowercasedLine = lowercased()
        let markers = [" at ", " @ ", " from ", " in "]
        for marker in markers {
            guard let range = lowercasedLine.range(of: marker, options: .backwards) else { continue }
            let suffix = String(self[range.upperBound...]).socialNameFragment
            if suffix.count >= 2 { return suffix }
        }

        if hasPrefix("@") {
            let handleName = dropFirst()
                .split { $0.isWhitespace || [".", ",", ":", "|"].contains(String($0)) }
                .first
                .map(String.init)?
                .replacingOccurrences(of: "_", with: " ")
            return handleName?.socialNameFragment
        }

        return isUsefulSocialLine && count <= 80 ? self : nil
    }

    var socialNameFragment: String {
        let stopCharacters = CharacterSet(charactersIn: "#@|\u{2022}\n")
            .union(.newlines)
        let fragment = components(separatedBy: stopCharacters).first ?? self
        return fragment
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .replacingOccurrences(of: "  ", with: " ")
    }

    var isUsefulSocialLine: Bool {
        let cleaned = socialCandidateLine
        let lower = cleaned.lowercased()
        guard cleaned.count >= 2 else { return false }
        guard !lower.hasPrefix("http") else { return false }
        guard !lower.hasPrefix("@") else { return false }
        guard !lower.contains("tiktok") || cleaned.count > 12 else { return false }
        guard !lower.contains("instagram") || cleaned.count > 14 else { return false }
        guard !["watch more", "watch now", "original sound", "reels", "reel"].contains(lower) else { return false }
        return true
    }

    var splitSocialCaption: [String] {
        replacingOccurrences(of: "\u{1F4CD}", with: "\n")
            .replacingOccurrences(of: "\u{2022}", with: "\n")
            .components(separatedBy: " - ")
    }

    var firstURL: URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        return detector.firstMatch(in: self, range: range)?.url
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
