import CoreLocation
import Foundation

private final class StubPlacesProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))!
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.handler(request)
            client?.urlProtocol(
                self,
                didReceive: HTTPURLResponse(
                    url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!,
                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}
@main struct PlacesTextSearchFallbackTests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubPlacesProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let service = PlacesTextSearchFallback(apiKey: "test-only-key", bundleId: "com.example.test", session: session)
        let fixture = Data(
            #"{"places":[{"id":"one","displayName":{"text":"Example Cafe"},"formattedAddress":"123 Main St","location":{"latitude":47.6,"longitude":-122.3},"types":["cafe","coffee_shop"],"priceLevel":"PRICE_LEVEL_MODERATE","attributions":[{"provider":"Example Provider","providerUri":"https://example.com/credit"}]},{"id":"bad","displayName":{"text":"Bad coordinate"},"location":{"latitude":999,"longitude":0}}]}"#
                .utf8)
        StubPlacesProtocol.handler = { request in
            precondition(request.url?.absoluteString == "https://places.googleapis.com/v1/places:searchText")
            precondition(
                request.httpMethod == "POST" && request.value(forHTTPHeaderField: "X-Goog-Api-Key") == "test-only-key")
            precondition(request.value(forHTTPHeaderField: "X-Ios-Bundle-Identifier") == "com.example.test")
            let mask = request.value(forHTTPHeaderField: "X-Goog-FieldMask")!
            precondition(mask.contains("places.attributions") && !mask.contains("*") && !mask.contains("photos"))
            return (200, fixture)
        }
        let result = try await service.search(
            query: "Example Cafe", near: CLLocation(latitude: 47.6, longitude: -122.3))
        precondition(result.count == 1 && result[0].googlePlaceId == "one" && result[0].name == "Example Cafe")
        precondition(result[0].establishmentType == .cafe && result[0].priceTier == .two)
        precondition(result[0].attribution?.link == URL(string: "https://example.com/credit"))
        for (status, data) in [(403, Data("{}".utf8)), (200, Data("broken json".utf8))] {
            StubPlacesProtocol.handler = { _ in (status, data) }
            do {
                _ = try await service.search(query: "query", near: nil)
                preconditionFailure("Invalid response accepted")
            } catch {}
        }
        StubPlacesProtocol.handler = { _ in (200, Data("{}".utf8)) }
        let empty = try await service.search(query: "no results", near: nil)
        precondition(empty.isEmpty)
        print(
            "PASS scoped REST request headers/field mask, SDK-compatible identity/type/price, provider links, invalid coordinates, HTTP/JSON failures and empty response"
        )
    }
}
