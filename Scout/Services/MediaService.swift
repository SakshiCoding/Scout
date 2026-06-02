import AVFoundation
import UIKit

@MainActor
final class MediaService {
    private let thumbnailCache = NSCache<NSString, UIImage>()

    func thumbnail(for media: Media, supabase: SupabaseService) async -> UIImage? {
        let key = media.storagePath as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        guard let data = try? await supabase.downloadMedia(path: media.storagePath) else {
            return nil
        }

        let image: UIImage?
        switch media.mediaType {
        case .photo:
            image = UIImage(data: data)
        case .video:
            image = await videoThumbnail(data: data, fileExtension: media.fileExtension)
        }

        if let image {
            thumbnailCache.setObject(image, forKey: key)
        }
        return image
    }

    func shareFile(for media: Media, supabase: SupabaseService) async throws -> URL {
        let data = try await supabase.downloadMedia(path: media.storagePath)
        let url = temporaryURL(for: media)
        try data.write(to: url, options: .atomic)
        return url
    }

    func removeCachedThumbnail(for media: Media) {
        thumbnailCache.removeObject(forKey: media.storagePath as NSString)
        try? FileManager.default.removeItem(at: temporaryURL(for: media))
    }

    private func videoThumbnail(data: Data, fileExtension: String) async -> UIImage? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            try data.write(to: url, options: .atomic)
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            return await withCheckedContinuation { continuation in
                generator.generateCGImageAsynchronously(for: .zero) { image, _, _ in
                    continuation.resume(returning: image.map(UIImage.init(cgImage:)))
                }
            }
        } catch {
            return nil
        }
    }

    private func temporaryURL(for media: Media) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("scout-share-\(media.id.uuidString)")
            .appendingPathExtension(media.fileExtension)
    }
}
