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
        let importPayload = SharedImportParser.payload(from: captured)

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
}

private struct SharedContentReader {
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
            if content.url != nil && content.text != nil { break }
        }

        if content.url == nil, let textURL = content.text?.firstURL {
            content.url = textURL
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
}

private enum SharedImportParser {
    nonisolated static func payload(from content: SharedContent) -> SharedRestaurantImport {
        let sourceApp = sourceApp(for: content.url)
        let maps = parseAppleMaps(content.url)
        let cleanedTitle = content.title?.cleanSharedLine
        let textLines = content.text?.linesWithoutURLs ?? []
        let inferredName = maps.name ?? cleanedTitle ?? textLines.first?.cleanSharedLine
        let inferredAddress = maps.address ?? textLines.dropFirst().first?.cleanSharedLine

        return SharedRestaurantImport(
            sourceURL: content.url,
            sourceText: content.text,
            sourceTitle: cleanedTitle,
            name: inferredName,
            address: inferredAddress,
            latitude: maps.latitude,
            longitude: maps.longitude,
            sourceApp: sourceApp
        )
    }

    nonisolated private static func sourceApp(for url: URL?) -> SharedRestaurantImport.SourceApp {
        guard let host = url?.host()?.lowercased() else { return .other }
        if host.contains("maps.apple.com") { return .appleMaps }
        return .safari
    }

    nonisolated private static func parseAppleMaps(_ url: URL?) -> (name: String?, address: String?, latitude: Double?, longitude: Double?) {
        guard let url,
              url.host()?.lowercased().contains("maps.apple.com") == true,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return (nil, nil, nil, nil)
        }

        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })
        let name = items["q"]?.removingPercentEncoding?.cleanSharedLine
        let address = items["address"]?.removingPercentEncoding?.cleanSharedLine
        let coordinate = items["ll"].flatMap(parseCoordinate) ?? items["sll"].flatMap(parseCoordinate)
        return (name, address, coordinate?.latitude, coordinate?.longitude)
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
        components(separatedBy: .newlines)
            .map(\.cleanSharedLine)
            .filter { !$0.isEmpty && !$0.lowercased().hasPrefix("http") }
    }

    var cleanSharedLine: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var firstURL: URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        return detector.firstMatch(in: self, range: range)?.url
    }
}
