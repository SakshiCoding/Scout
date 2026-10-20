import Foundation

// Runs against the production service and models, without credentials or live API traffic.
private final class MockGeminiProtocol: URLProtocol {
    static var statusCode = 200
    static var responseText = ""
    static var requestCount = 0
    static var lastRequest: URLRequest?
    static var lastBody: [String: Any]?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requestCount += 1
        Self.lastRequest = request
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let count = stream.read(buffer, maxLength: 4096)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
            Self.lastBody = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        } else if let data = request.httpBody {
            Self.lastBody = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil)!
        let body = try! JSONSerialization.data(withJSONObject: [
            "candidates": [["content": ["parts": [["text": Self.responseText]]]]]
        ])
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
private struct GeminiMetadataTests {
    static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockGeminiProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let service = GeminiService(apiKey: "test-key", session: session)

        MockGeminiProtocol.responseText = #"{"cuisine":"  Italian  ","vibe_tags":["date NIGHT","Casual","casual","Invented tag"],"confidence":0.9}"#
        let suggestion = try await service.suggestMetadata(name: "Example Trattoria", address: "123 Main St, Seattle")
        precondition(suggestion?.cuisine == "Italian")
        precondition(suggestion?.vibeTags == ["Date night", "Casual"])
        let request = MockGeminiProtocol.lastRequest!
        precondition(request.httpMethod == "POST")
        precondition(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
        precondition(request.url!.query == nil)
        let body = MockGeminiProtocol.lastBody!
        let contents = body["contents"] as! [[String: Any]]
        let parts = contents[0]["parts"] as! [[String: String]]
        let prompt = parts[0]["text"]!
        precondition(prompt.contains("Example Trattoria") && prompt.contains("123 Main St, Seattle"))
        let generationConfig = body["generationConfig"] as! [String: Any]
        precondition(generationConfig["responseMimeType"] as? String == "application/json")
        print("PASS: request contract, address context, normalization, and canonical vibe filtering")

        MockGeminiProtocol.responseText = #"{"cuisine":"Italian","vibe_tags":["Casual"],"confidence":0.74}"#
        let uncertain = try await service.suggestMetadata(name: "Ambiguous", address: nil)
        precondition(uncertain == nil)
        MockGeminiProtocol.responseText = #"{"cuisine":" Restaurant ","vibe_tags":["Unknown"],"confidence":0.99}"#
        let generic = try await service.suggestMetadata(name: "Generic", address: nil)
        precondition(generic == nil)
        precondition(RestaurantMetadataSuggestion.isGenericCuisine(nil))
        precondition(RestaurantMetadataSuggestion.isGenericCuisine("  FOOD "))
        precondition(!RestaurantMetadataSuggestion.isGenericCuisine("Thai"))
        print("PASS: uncertain, generic, and unsupported metadata produces no autofill")

        let countBefore = MockGeminiProtocol.requestCount
        do {
            _ = try await service.suggestMetadata(name: "  ", address: nil)
            preconditionFailure("Expected empty input error")
        } catch GeminiServiceError.emptyInput {}
        do {
            _ = try await GeminiService(apiKey: nil, session: session).suggestMetadata(name: "Example", address: nil)
            preconditionFailure("Expected missing key error")
        } catch GeminiServiceError.missingAPIKey {}
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await service.suggestMetadata(name: "Example", address: nil)
        }
        do {
            _ = try await cancelled.value
            preconditionFailure("Expected cancellation")
        } catch is CancellationError {}
        precondition(MockGeminiProtocol.requestCount == countBefore)
        print("PASS: empty input, missing key, and cancellation make no network requests")

        MockGeminiProtocol.statusCode = 429
        do {
            _ = try await service.suggestMetadata(name: "Example", address: nil)
            preconditionFailure("Expected rate limit error")
        } catch GeminiServiceError.requestFailed(statusCode: 429) {}
        MockGeminiProtocol.statusCode = 200
        MockGeminiProtocol.responseText = "not JSON"
        do {
            _ = try await service.suggestMetadata(name: "Example", address: nil)
            preconditionFailure("Expected malformed response error")
        } catch is DecodingError {}
        print("PASS: HTTP failures and malformed responses surface for manual fallback")

        // Both features share transport, so protect the original social parser too.
        MockGeminiProtocol.responseText = "```json\n" + #"{"restaurant_name":" Kismet ","city":" Seattle ","cuisine":"Mediterranean","vibe_tags":["Cozy"],"confidence":1.5}"# + "\n```"
        let social = try await service.parseRestaurantText("Save Kismet in Seattle", sourceApp: .tiktok)
        precondition(social.restaurantName == "Kismet" && social.city == "Seattle")
        precondition(social.vibeTags == ["Cozy"] && social.confidence == 1)
        print("PASS: existing social parsing and fenced JSON remain supported")
    }
}
