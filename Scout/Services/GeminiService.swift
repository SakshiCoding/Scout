import Foundation

struct GeminiRestaurantGuess: Equatable {
    let name: String
    let cuisine: String?
    let establishmentType: Restaurant.EstablishmentType?
    let priceTier: Restaurant.PriceTier?
    let vibeTags: [String]
    let confidence: String?
}

@MainActor
final class GeminiService {
    static let shared = GeminiService()

    private let apiKey: String?
    private let isEnabled: Bool

    private init(bundle: Bundle = .main) {
        let configuredKey = (bundle.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let key = configuredKey?.hasPrefix("$(") == true ? nil : configuredKey?.nonEmpty
        self.apiKey = key
        self.isEnabled = key != nil
    }

    func parseRestaurantMention(
        caption: String?,
        sourceTitle: String?,
        sourceURL: URL?,
        sourceApp: SharedRestaurantImport.SourceApp
    ) async -> GeminiRestaurantGuess? {
        guard isEnabled, let apiKey = apiKey else { return nil }

        let captionText = (caption ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let titleText = (sourceTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !captionText.isEmpty || !titleText.isEmpty else { return nil }

        let sourceAppName = sourceAppDisplayName(sourceApp)
        let urlText = sourceURL?.absoluteString ?? ""
        let userPrompt = buildPrompt(caption: captionText, title: titleText, url: urlText, app: sourceAppName)

        return await fetchGeminiGuess(prompt: userPrompt, apiKey: apiKey)
    }

    private func sourceAppDisplayName(_ app: SharedRestaurantImport.SourceApp) -> String {
        switch app {
        case .tiktok:
            return "TikTok"
        case .instagram:
            return "Instagram"
        case .social, .other:
            return "Social Media"
        case .appleMaps, .googleMaps, .safari:
            return "Shared Link"
        }
    }

    private func buildPrompt(caption: String, title: String, url: String, app: String) -> String {
        var parts: [String] = []
        if !caption.isEmpty {
            parts.append("Caption: \(caption)")
        }
        if !title.isEmpty {
            parts.append("Title: \(title)")
        }
        if !url.isEmpty {
            parts.append("URL: \(url)")
        }

        let content = parts.joined(separator: "\n")
        return """
You are given a caption or title from a social media post (app: \(app)). Identify the single most likely specific restaurant, cafe, bar, or food establishment being mentioned or reviewed. If no specific establishment can be confidently identified, return an empty name and confidence "low". Do not invent a business that isn't referenced.

\(content)
"""
    }

    private func fetchGeminiGuess(prompt: String, apiKey: String) async -> GeminiRestaurantGuess? {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest/generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { return nil }

        let requestBody = GeminiRequest(prompt: prompt)
        guard let httpBody = try? JSONEncoder().encode(requestBody) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            guard let candidates = geminiResponse.candidates, !candidates.isEmpty else {
                return nil
            }

            guard let textContent = candidates[0].content?.parts?.first?.text else {
                return nil
            }

            guard let innerData = textContent.data(using: .utf8) else { return nil }
            let guess = try JSONDecoder().decode(GeminiInnerGuess.self, from: innerData)

            let name = guess.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return nil }

            let establishmentType = guess.establishmentType.flatMap { Restaurant.EstablishmentType(rawValue: $0) }
            let priceTier = guess.priceTier.flatMap { Restaurant.PriceTier(rawValue: $0) }

            return GeminiRestaurantGuess(
                name: name,
                cuisine: guess.cuisine,
                establishmentType: establishmentType,
                priceTier: priceTier,
                vibeTags: guess.vibeTags ?? [],
                confidence: guess.confidence
            )
        } catch {
            return nil
        }
    }
}

private struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig

    init(prompt: String) {
        self.contents = [GeminiContent(parts: [GeminiPart(text: prompt)])]
        self.generationConfig = GeminiGenerationConfig()
    }
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiGenerationConfig: Codable {
    let responseMimeType: String
    let responseSchema: GeminiSchema

    init() {
        self.responseMimeType = "application/json"
        self.responseSchema = GeminiSchema()
    }

    enum CodingKeys: String, CodingKey {
        case responseMimeType
        case responseSchema
    }
}

private struct GeminiSchema: Codable {
    let type: String
    let properties: [String: GeminiProperty]
    let required: [String]

    init() {
        self.type = "OBJECT"
        self.properties = [
            "name": GeminiProperty(type: "STRING"),
            "cuisine": GeminiProperty(type: "STRING"),
            "establishmentType": GeminiProperty(type: "STRING", enumValues: ["restaurant", "cafe", "bar", "bakery", "brewery", "winery", "other"]),
            "priceTier": GeminiProperty(type: "STRING", enumValues: ["$", "$$", "$$$", "$$$$"]),
            "vibeTags": GeminiProperty(type: "ARRAY", items: GeminiProperty(type: "STRING")),
            "confidence": GeminiProperty(type: "STRING", enumValues: ["low", "medium", "high"])
        ]
        self.required = ["name", "confidence"]
    }
}

private final class GeminiProperty: Codable {
    let type: String
    let enumValues: [String]?
    let items: GeminiProperty?

    init(type: String, enumValues: [String]? = nil, items: GeminiProperty? = nil) {
        self.type = type
        self.enumValues = enumValues
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case type
        case enumValues = "enum"
        case items
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(enumValues, forKey: .enumValues)
        try container.encodeIfPresent(items, forKey: .items)
    }
}

private struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Codable {
    let content: GeminiCandidateContent?
}

private struct GeminiCandidateContent: Codable {
    let parts: [GeminiResponsePart]?
}

private struct GeminiResponsePart: Codable {
    let text: String?
}

private struct GeminiInnerGuess: Codable {
    let name: String?
    let cuisine: String?
    let establishmentType: String?
    let priceTier: String?
    let vibeTags: [String]?
    let confidence: String?

    enum CodingKeys: String, CodingKey {
        case name
        case cuisine
        case establishmentType
        case priceTier
        case vibeTags
        case confidence
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
