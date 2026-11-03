#if canImport(AppKit)
import AppKit
#endif
import CoreText
import Foundation
import SwiftUI

@MainActor private final class DeferredCover {
    var requests: [(Media, CheckedContinuation<CGImage?, Never>)] = []
    func fetch(_ media: Media) async -> CGImage? {
        await withCheckedContinuation { requests.append((media, $0)) }
    }
    func finish(_ index: Int, _ image: CGImage?) { requests[index].1.resume(returning: image) }
}

@main private struct RestaurantCoverTests {
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10_000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Cover request did not reach expected state")
    }
    static func image(width: Int, height: Int) -> CGImage {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.8, green: 0.33, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.48, green: 0.55, blue: 0.24, alpha: 1))
        context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        return context.makeImage()!
    }
    @MainActor static func main() async throws {
        let circleId = UUID(), restaurantId = UUID()
        func photo(_ id: String = UUID().uuidString, date: TimeInterval = 10) -> Media {
            Media(id: UUID(uuidString: id)!, restaurantId: restaurantId, circleId: circleId,
                  userId: UUID(), storagePath: "circles/\(circleId)/\(id).jpg", mediaType: .photo,
                  createdAt: Date(timeIntervalSince1970: date))
        }
        let first = photo(date: 30), second = photo(date: 20), third = photo(), fourth = photo(date: 0)
        var outsider = photo(date: 200); outsider.circleId = UUID()
        var otherRestaurant = photo(date: 200); otherRestaurant.restaurantId = UUID()
        var video = photo(date: 200); video.mediaType = .video
        var unlinked = photo(date: 200); unlinked.restaurantId = nil
        var blank = photo(date: 200); blank.storagePath = "  "
        var forgedPath = photo(date: 200); forgedPath.storagePath = "circles/\(UUID())/foreign.jpg"
        var traversal = photo(date: 200); traversal.storagePath = "circles/\(circleId)/../foreign.jpg"
        let selection = RestaurantJournalCover.candidates(restaurantId: restaurantId, circleId: circleId,
            media: [fourth, video, third, outsider, second, otherRestaurant, first, unlinked, blank, forgedPath, traversal])
        precondition(selection.map(\.id) == [first.id, second.id, third.id])
        let tieA = photo("00000000-0000-0000-0000-000000000001")
        let tieB = photo("00000000-0000-0000-0000-000000000002")
        let ties = RestaurantJournalCover.candidates(restaurantId: restaurantId, circleId: circleId, media: [tieB, tieA])
        precondition(ties.map(\.id) == [tieA.id, tieB.id])
        precondition(RestaurantJournalCover.candidates(restaurantId: restaurantId, circleId: circleId,
            media: [outsider, otherRestaurant, video, unlinked, blank]).isEmpty)
        var replaced = first; replaced.storagePath += "replacement"
        precondition(RestaurantJournalCover.PhotoKey(first) != RestaurantJournalCover.PhotoKey(replaced))
        print("PASS newest-three selection, stable ties, photo-only covers, circle/restaurant isolation, missing paths and replaced-asset identity")

        let landscape = image(width: 1024, height: 768)
        let state = RestaurantCoverLoadState()
        var attempted: [UUID] = []
        await state.load(candidates: selection) { item in
            attempted.append(item.id)
            return item.id == second.id ? landscape : nil
        }
        precondition(attempted == [first.id, second.id] && state.selectedMedia?.id == second.id)
        precondition(state.image(matching: selection) === landscape && !state.failed && !state.isLoading)
        precondition(state.image(matching: [first]).isNil)
        var replacedSecond = second; replacedSecond.storagePath = "new-path"
        precondition(state.image(matching: [replacedSecond]).isNil)
        var differentCircle = second; differentCircle.circleId = UUID()
        precondition(state.image(matching: [differentCircle]).isNil)
        var differentRestaurant = second; differentRestaurant.restaurantId = UUID()
        precondition(state.image(matching: [differentRestaurant]).isNil)
        await state.load(candidates: []) { _ in preconditionFailure("Empty cover fetched") }
        precondition(state.image == nil && state.selectedMedia == nil && !state.failed && !state.isLoading)
        var failures = 0
        await state.load(candidates: [first, second, third, fourth]) { _ in failures += 1; return nil }
        precondition(failures == 3 && state.failed && state.image == nil && !state.isLoading)
        await state.load(candidates: [first]) { _ in landscape }
        precondition(!state.failed && state.image === landscape)
        print("PASS older-photo fallback, immediate deletion/replacement hiding, empty/video-only state, bounded failures and retry")

        let deferred = DeferredCover()
        let old = Task { await state.load(candidates: [first]) { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 1 }
        let latest = Task { await state.load(candidates: [second]) { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 2 }
        deferred.finish(0, landscape)
        await old.value
        precondition(state.image == nil && state.isLoading)
        deferred.finish(1, landscape)
        await latest.value
        precondition(state.selectedMedia?.id == second.id && !state.isLoading)
        let cancelled = Task { await state.load(candidates: selection) { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 3 }
        cancelled.cancel()
        deferred.finish(2, landscape)
        await cancelled.value
        precondition(state.image == nil && state.selectedMedia == nil && !state.isLoading)
        precondition(deferred.requests.count == 3) // cancellation must not schedule fallback work
        let scoped = Task { await state.load(candidates: [first]) { await deferred.fetch($0) } }
        await wait { deferred.requests.count == 4 }
        await state.load(candidates: []) { _ in preconditionFailure("Cleared scope fetched") }
        deferred.finish(3, landscape)
        await scoped.value
        precondition(state.image == nil && !state.failed && !state.isLoading)
        print("PASS stale-response/loading ownership, cancellation, no fallback after cancellation, and cleared auth/circle scope")

        if CommandLine.arguments.count > 2, !CommandLine.arguments[2].isEmpty {
            struct HostedFixture: Decodable {
                let circleId: UUID
                let restaurantId: UUID
                let photos: [Media]
                let photoPath: String
                let downloadedFile: String
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let value = try decoder.singleValueContainer().decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: value) { return date }
                formatter.formatOptions = [.withInternetDateTime]
                guard let date = formatter.date(from: value) else { throw CocoaError(.coderReadCorrupt) }
                return date
            }
            let fixture = try decoder.decode(HostedFixture.self,
                from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
            let hosted = RestaurantJournalCover.candidates(restaurantId: fixture.restaurantId,
                circleId: fixture.circleId, media: fixture.photos)
            precondition(hosted.count == 1 && hosted[0].storagePath == fixture.photoPath)
            let bytes = try Data(contentsOf: URL(fileURLWithPath: fixture.downloadedFile))
            let cache = MediaThumbnailStore()
            await state.load(candidates: hosted) { item in
                await cache.thumbnail(for: item, size: .cover) { bytes }
            }
            precondition(state.image != nil && state.selectedMedia?.storagePath == fixture.photoPath)
            precondition(max(state.image!.width, state.image!.height) <= 1024)
            print("PASS real hosted media JSON -> production scoped selector -> authenticated photo bytes -> native cover decoder/cache/load state")
        }

        #if canImport(AppKit)
        for font in ["DMSans-Regular.ttf", "DMSans-SemiBold.ttf"] {
            CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: font) as CFURL, .process, nil)
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let cases: [(String, CGImage?, Bool, Bool)] = [
            ("landscape", landscape, false, false), ("portrait", image(width: 768, height: 1024), false, false),
            ("empty", nil, false, false), ("loading", nil, true, false), ("failed", nil, false, true)
        ]
        for (name, cover, loading, failed) in cases {
            let content = RestaurantCoverImage(image: cover, restaurantName: "A restaurant with a long name",
                isLoading: loading, failed: failed, retry: {}, openJournal: {})
                .frame(width: 390)
            let renderer = ImageRenderer(content: content); renderer.scale = 2
            guard let result = renderer.nsImage, let tiff = result.tiffRepresentation,
                  let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
                preconditionFailure("Unable to render cover: \(name)")
            }
            try png.write(to: output.appendingPathComponent("cover-\(name).png"))
        }
        print("PASS five production cover renders: landscape, portrait crop, empty, loading, failed/retry")
        #else
        print("PASS cover selection/load state on iOS Simulator; UI render diagnostics run on macOS")
        #endif
    }
}

private extension Optional { var isNil: Bool { self == nil } }
