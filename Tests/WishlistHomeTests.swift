import ImageIO
import UniformTypeIdentifiers
import CoreText
import SwiftUI

@MainActor private final class PendingPhoto {
    var requests: [CheckedContinuation<PlacePhoto?, Never>] = []
    func fetch() async -> PlacePhoto? { await withCheckedContinuation { requests.append($0) } }
}
@main struct WishlistHomeTests {
    static func write(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        precondition(CGImageDestinationFinalize(destination))
    }
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Deferred photo did not start")
    }
    @MainActor static func main() async throws {
        let dir = URL(fileURLWithPath: CommandLine.arguments[1])
        let circle = UUID(), restaurant = UUID(), user = UUID()
        let item = Media(id: UUID(), restaurantId: restaurant, circleId: circle, userId: user,
                         storagePath: "circles/\(circle)/photo.jpg", mediaType: .photo, createdAt: Date())
        let context = CGContext(data: nil, width: 512, height: 512, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.4, green: 0.55, blue: 0.25, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
        let image = context.makeImage()!
        let photo = PlacePhoto(image: image, attribution: nil, authors: [], googleMapsURL: nil, reportURL: nil)
        let state = WishlistPhotoLoadState()
        await state.load(candidates: [item], placeId: "google", journal: { _ in image },
                         google: { _ in preconditionFailure("Journal must have priority") })
        precondition(state.image === image && state.googlePhoto == nil)
        var attempts = 0, googleCalls = 0
        await state.load(candidates: [item,item,item,item], placeId: "google", journal: { _ in attempts += 1; return nil },
                         google: { _ in googleCalls += 1; return photo })
        precondition(attempts == 3 && googleCalls == 1 && state.googlePhoto?.image === image)
        let abandoned = Task { await state.load(candidates: [], placeId: "abandoned", journal: { _ in nil }, google: { _ in preconditionFailure("Pre-canceled photo fetched") }) }
        abandoned.cancel(); await abandoned.value
        precondition(state.image === image && state.googlePhoto?.image === image)
        await state.load(candidates: [], placeId: nil, journal: { _ in nil }, google: { _ in preconditionFailure() })
        precondition(state.image == nil && !state.isLoading)
        let pending = PendingPhoto()
        let old = Task { await state.load(candidates: [], placeId: "old", journal: { _ in nil }, google: { _ in await pending.fetch() }) }
        await wait { pending.requests.count == 1 }
        state.clear()
        pending.requests[0].resume(returning: photo)
        await old.value
        precondition(state.image == nil && state.googlePhoto == nil && !state.isLoading)
        let cancelled = Task { await state.load(candidates: [], placeId: "cancel", journal: { _ in nil }, google: { _ in await pending.fetch() }) }
        await wait { pending.requests.count == 2 }
        cancelled.cancel(); pending.requests[1].resume(returning: photo); await cancelled.value
        precondition(state.image == nil && !state.isLoading)
        print("PASS journal priority, bounded older-photo attempts, Google fallback, manual empty state, cleared scope and canceled late results")

        let queue = PlacePhotoRequestQueue(limit: 2), held = PendingPhoto()
        let first = Task { await queue.run { await held.fetch() } }
        let second = Task { await queue.run { await held.fetch() } }
        await wait { held.requests.count == 2 }
        let third = Task { await queue.run { preconditionFailure("Canceled queued lookup ran") } }
        for _ in 0..<30 { await Task.yield() }
        precondition(held.requests.count == 2)
        third.cancel()
        held.requests[0].resume(returning: nil); _ = await first.value; _ = await third.value
        held.requests[1].resume(returning: nil); _ = await second.value
        _ = await queue.run { photo }
        print("PASS at most two live lookups, queued cancellation does not call Google, permits recover")

        let long = Restaurant(circleId: circle, name: "August Moon Chinese Restaurant and Dumpling House", cuisine: "Chinese",
                              priceTier: .two, vibeTags: ["Casual", "Quick bite"], distanceMiles: 123.4)
        precondition(WishlistSearch.matches(long, query: "  moon  "))
        precondition(WishlistSearch.matches(long, query: "CHINESE"))
        precondition(WishlistSearch.matches(long, query: "quick bite"))
        precondition(!WishlistSearch.matches(long, query: "cafe"))
        var cafe = long; cafe.name = "Café Hagen"
        precondition(WishlistSearch.matches(cafe, query: "cafe"))
        print("PASS whitespace, name/cuisine/vibe search, case/diacritic matching and no-match state")
        for font in ["DMSans-Regular.ttf","DMSans-Medium.ttf","DMSans-SemiBold.ttf","DMSerifDisplay-Regular.ttf"] {
            let url = URL(fileURLWithPath: CommandLine.arguments[2]).appendingPathComponent(font)
            if FileManager.default.fileExists(atPath: url.path) { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
        }
        for (name, width, large, shownImage) in [("narrow",320,false,true),("large-text",320,true,true),("fallback",390,false,false)] {
            let view = RestaurantRowView(restaurant: long, image: shownImage ? image : nil)
                .padding(.horizontal,24).frame(width:CGFloat(width))
                .environment(\.dynamicTypeSize, large ? .accessibility3 : .large).background(Atlas.paper)
            let renderer = ImageRenderer(content: view); renderer.scale = 2
            guard let rendered = renderer.cgImage else { fatalError("Row did not render") }
            precondition(rendered.width == width * 2 && rendered.height >= 176)
            try write(rendered, to: dir.appendingPathComponent(name+".png"))
        }
        let together = WishlistTogetherCard(members: [], count: 3, action: {})
            .padding(24).frame(width:320).background(Atlas.paper)
        let renderer = ImageRenderer(content: together); renderer.scale = 2
        try write(renderer.cgImage!, to: dir.appendingPathComponent("together.png"))
        let linkedPhoto = PlacePhoto(image: image, attribution: AttributedString("Example Photographer"),
            authors: [.init(name: "Example Photographer", url: URL(string: "https://example.com/author"))],
            googleMapsURL: URL(string: "https://maps.google.com"), reportURL: nil)
        let credited = RestaurantRowView(restaurant: long, image: image, googlePhoto: linkedPhoto)
            .padding(.horizontal,24).frame(width:390).background(Atlas.paper)
        let creditRenderer = ImageRenderer(content: credited); creditRenderer.scale = 2
        try write(creditRenderer.cgImage!, to: dir.appendingPathComponent("inline-credit.png"))
        print("PASS production row renders at 320pt, accessibility text, no-photo fallback, long names/large distance, and Together card")
    }
}
