import AppKit
import CoreGraphics
import SwiftUI

@MainActor private final class DeferredPhoto {
    var requests: [CheckedContinuation<PlacePhoto?, Never>] = []
    func fetch(_ id: String) async -> PlacePhoto? {
        await withCheckedContinuation { requests.append($0) }
    }
}
@main struct PlacePhotoTests {
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Request never reached expected state")
    }
    @MainActor static func main() async throws {
        let context = CGContext(data: nil, width: 1024, height: 680, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.4, green: 0.55, blue: 0.3, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1024, height: 680))
        var credit = AttributedString("Additional image provider")
        credit.link = URL(string: "https://example.com/provider")!
        let fixture = PlacePhoto(image: context.makeImage()!, attribution: credit,
            authors: [.init(name: "An example photographer with a long name", url: URL(string: "https://example.com/author"))],
            googleMapsURL: URL(string: "https://maps.google.com"), reportURL: URL(string: "https://example.com/report"))
        precondition(fixture.attribution?.link == credit.link && fixture.authors[0].url != nil)
        let state = PlacePhotoLoadState()
        await state.load(placeId: nil) { _ in preconditionFailure("Manual restaurant fetched") }
        await state.load(placeId: " ") { _ in preconditionFailure("Blank ID fetched") }
        precondition(state.photo == nil && !state.isLoading && !state.failed)
        let deferred = DeferredPhoto()
        let old = Task { await state.load(placeId: "old") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 1 }
        let new = Task { await state.load(placeId: "new") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 2 }
        deferred.requests[0].resume(returning: fixture)
        await old.value
        precondition(state.photo == nil && state.isLoading)
        deferred.requests[1].resume(returning: nil)
        await new.value
        precondition(state.failed && !state.isLoading)
        await state.load(placeId: "new") { _ in fixture }
        precondition(state.photo?.image === fixture.image && !state.failed)
        let revoked = Task { await state.load(placeId: "new") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 3 }
        await state.load(placeId: nil) { _ in nil }
        deferred.requests[2].resume(returning: fixture)
        await revoked.value
        precondition(state.photo == nil && !state.failed && !state.isLoading)
        let cancelled = Task { await state.load(placeId: "new") { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 4 }
        cancelled.cancel()
        deferred.requests[3].resume(returning: fixture)
        await cancelled.value
        precondition(state.photo == nil && !state.failed && !state.isLoading)
        print("PASS photo load state: manual IDs, overlap, failure/retry, clearing after scope changes and canceled late responses; attribution links preserved")
        let output = CommandLine.arguments[1]
        let view = VStack(spacing: 0) {
            RestaurantCoverImage(image: fixture.image, restaurantName: "An example restaurant", isLoading: false,
                failed: false, retry: {}, imageDescription: "Google photo of an example restaurant")
            PlacePhotoCredits(photo: fixture)
        }.frame(width: 390).background(Atlas.paper)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let cgImage = renderer.cgImage else { fatalError("Cover did not render") }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
        print("PASS production cover/credit layout rasterized at iPhone width; native links verified in live Simulator")
    }
}
