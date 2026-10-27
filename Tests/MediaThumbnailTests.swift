import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

@MainActor private final class DeferredDownload {
    var requests: [CheckedContinuation<Data, Error>] = []
    func load() async throws -> Data {
        // Deliberately ignores cancellation so tests can deliver late responses.
        try await withCheckedThrowingContinuation { requests.append($0) }
    }
    func finish(_ index: Int, data: Data) { requests[index].resume(returning: data) }
}

@main private struct MediaThumbnailTests {
    @MainActor static func wait(_ condition: () -> Bool) async {
        for _ in 0..<10_000 { if condition() { return }; await Task.yield() }
        preconditionFailure("Expected deferred thumbnail state was not reached")
    }
    static func image(width: Int, height: Int) -> CGImage {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.8, green: 0.33, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        context.setFillColor(CGColor(red: 0.48, green: 0.55, blue: 0.24, alpha: 1))
        context.fill(CGRect(x: width / 2, y: 0, width: width / 2, height: height / 2))
        return context.makeImage()!
    }
    static func encode(_ image: CGImage, type: UTType, orientation: Int = 1) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        precondition(CGImageDestinationFinalize(destination))
        return data as Data
    }
    static func video(at url: URL) async throws -> Data {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1280, AVVideoHeightKey: 720
        ])
        input.transform = CGAffineTransform(rotationAngle: .pi / 2)
        let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
            sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: 1280, kCVPixelBufferHeightKey as String: 720,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true])
        writer.add(input)
        precondition(writer.startWriting())
        writer.startSession(atSourceTime: .zero)
        var buffer: CVPixelBuffer?
        precondition(CVPixelBufferCreate(kCFAllocatorDefault, 1280, 720,
            kCVPixelFormatType_32ARGB, nil, &buffer) == kCVReturnSuccess)
        CVPixelBufferLockBaseAddress(buffer!, [])
        memset(CVPixelBufferGetBaseAddress(buffer!), 0x88, CVPixelBufferGetDataSize(buffer!))
        CVPixelBufferUnlockBaseAddress(buffer!, [])
        for index in 0..<3 {
            while !input.isReadyForMoreMediaData { await Task.yield() }
            precondition(adapter.append(buffer!, withPresentationTime: CMTime(value: Int64(index), timescale: 2)))
        }
        input.markAsFinished()
        await writer.finishWriting()
        precondition(writer.status == .completed, "Video fixture failed: \(String(describing: writer.error))")
        return try Data(contentsOf: url)
    }
    static func render(_ data: Data, type: Media.MediaType = .photo, ext: String = "jpg") async -> CGImage? {
        await Task.detached {
            precondition(!Thread.isMainThread)
            return await MediaThumbnailRenderer.render(data: data, mediaType: type, fileExtension: ext)
        }.value
    }
    static func temporaryThumbnailFiles() throws -> Set<String> {
        Set(try FileManager.default.contentsOfDirectory(atPath: FileManager.default.temporaryDirectory.path)
            .filter { $0.hasPrefix("scout-thumbnail-") })
    }
    @MainActor static func main() async throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1])
        let large = image(width: 4000, height: 3000)
        let jpeg = encode(large, type: .jpeg, orientation: 6)
        let portrait = await render(jpeg)!
        precondition(portrait.width == 384 && portrait.height == 512)
        precondition(portrait.bytesPerRow * portrait.height <= 1_100_000)
        #if canImport(UIKit)
        let displayImage = UIImage(cgImage: portrait)
        precondition(displayImage.imageOrientation == .up && displayImage.size == CGSize(width: 384, height: 512))
        #endif
        try encode(portrait, type: .png).write(to: directory.appendingPathComponent("portrait-thumbnail.png"))
        let png = encode(image(width: 80, height: 40), type: .png)
        let small = await render(png)!
        precondition(small.width == 80 && small.height == 40 && small.alphaInfo != .none)
        let corruptPhoto = await render(Data("not an image".utf8))
        precondition(corruptPhoto == nil)
        print("PASS production ImageIO: 12MP EXIF portrait -> 384x512, <1.1MB decoded, small PNG/alpha, corrupt input, detached rendering")

        let tempBefore = try temporaryThumbnailFiles()
        let videoURL = directory.appendingPathComponent("fixture-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: videoURL) }
        let videoData = try await video(at: videoURL)
        let poster = await render(videoData, type: .video, ext: "mov")!
        precondition(poster.width <= 512 && poster.height <= 512 && poster.width < poster.height)
        let corruptVideo = await render(Data("bad video".utf8), type: .video, ext: "mov")
        precondition(corruptVideo == nil)
        let tempAfter = try temporaryThumbnailFiles()
        precondition(tempAfter == tempBefore)
        try encode(poster, type: .png).write(to: directory.appendingPathComponent("video-thumbnail.png"))
        print("PASS production AVFoundation: bounded video poster, preferred rotation, bad video fallback, temporary-file cleanup")

        let media = Media(id: UUID(), circleId: UUID(), userId: UUID(), storagePath: "fixture/photo.jpg",
                          mediaType: .photo, createdAt: Date())
        let store = MediaThumbnailStore()
        let download = DeferredDownload()
        let first = Task { await store.thumbnail(for: media) { try await download.load() } }
        await wait { download.requests.count == 1 }
        var secondStarted = false
        let second = Task {
            secondStarted = true
            return await store.thumbnail(for: media) { preconditionFailure("Duplicate download") }
        }
        await wait { secondStarted }
        download.finish(0, data: jpeg)
        let firstImage = await first.value
        let secondImage = await second.value
        precondition(firstImage != nil && firstImage === secondImage)
        let cached = await store.thumbnail(for: media) { preconditionFailure("Cache miss") }
        precondition(cached === firstImage)
        store.remove(path: media.storagePath)
        let afterRemoval = await store.thumbnail(for: media) { png }
        precondition(afterRemoval?.width == 80)
        print("PASS duplicate callers share one download/decode, cache reuse, removal and fresh replacement")

        // A cancelled view must not cancel the shared load needed by another visible view.
        store.clear()
        let cancelled = Task { await store.thumbnail(for: media) { try await download.load() } }
        await wait { download.requests.count == 2 }
        var remainingStarted = false
        let remaining = Task {
            remainingStarted = true
            return await store.thumbnail(for: media) { preconditionFailure("Duplicate download") }
        }
        await wait { remainingStarted }
        cancelled.cancel()
        download.finish(1, data: png)
        let cancelledResult = await cancelled.value
        precondition(cancelledResult == nil)
        let remainingResult = await remaining.value
        precondition(remainingResult != nil)

        // Sign-out/clear blocks late downloads even when the loader ignores cancellation.
        store.clear()
        let old = Task { await store.thumbnail(for: media) { try await download.load() } }
        await wait { download.requests.count == 3 }
        store.clear()
        let replacing = Task { await store.thumbnail(for: media) { try await download.load() } }
        await wait { download.requests.count == 4 }
        download.finish(2, data: jpeg)
        let oldResult = await old.value
        precondition(oldResult == nil)
        download.finish(3, data: png)
        let replacement = await replacing.value
        precondition(replacement != nil)
        let replacementCache = await store.thumbnail(for: media) { preconditionFailure("Old work removed replacement") }
        precondition(replacementCache === replacement)

        store.remove(path: media.storagePath)
        let deleted = Task { await store.thumbnail(for: media) { try await download.load() } }
        await wait { download.requests.count == 5 }
        store.remove(path: media.storagePath)
        download.finish(4, data: jpeg)
        let deletedResult = await deleted.value
        precondition(deletedResult == nil)
        let failed = await store.thumbnail(for: media) { throw URLError(.notConnectedToInternet) }
        precondition(failed == nil)
        let invalid = await store.thumbnail(for: media) { Data() }
        precondition(invalid == nil)
        let retry = await store.thumbnail(for: media) { png }
        precondition(retry?.width == 80)
        print("PASS independent caller cancellation, sign-out/clear and deletion during download, replacement isolation, failed/corrupt retries")
    }
}
