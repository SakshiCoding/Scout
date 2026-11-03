import AVFoundation
import ImageIO

enum MediaPreviewSize: String, CaseIterable, Sendable {
    case thumbnail, cover
    nonisolated var maximumPixelSize: Int { self == .cover ? 1024 : 512 }
}

enum MediaThumbnailRenderer {

    /// Called by the store's detached task so image decoding/file IO never blocks SwiftUI.
    nonisolated static func render(data: Data, mediaType: Media.MediaType, fileExtension: String,
                                  size: MediaPreviewSize = .thumbnail) async -> CGImage? {
        guard !Task.isCancelled else { return nil }
        switch mediaType {
        case .photo:
            guard let source = CGImageSourceCreateWithData(data as CFData,
                [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
            return CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: size.maximumPixelSize,
                kCGImageSourceShouldCacheImmediately: true
            ] as CFDictionary)
        case .video:
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("scout-thumbnail-\(UUID().uuidString)")
                .appendingPathExtension(fileExtension)
            defer { try? FileManager.default.removeItem(at: url) }
            do {
                try data.write(to: url, options: .atomic)
                try Task.checkCancellation()
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: size.maximumPixelSize, height: size.maximumPixelSize)
                return await withTaskCancellationHandler {
                    try? await generator.image(at: .zero).image
                } onCancel: {
                    generator.cancelAllCGImageGeneration()
                }
            } catch { return nil }
        }
    }
}
