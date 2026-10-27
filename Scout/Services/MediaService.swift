import UIKit

@MainActor
final class MediaService {
    private let thumbnails = MediaThumbnailStore()

    func thumbnail(for media: Media, supabase: SupabaseService) async -> UIImage? {
        let image = await thumbnails.thumbnail(for: media) {
            try await supabase.downloadMedia(path: media.storagePath)
        }
        return image.map { UIImage(cgImage: $0) }
    }

    func shareFile(for media: Media, supabase: SupabaseService) async throws -> URL {
        let data = try await supabase.downloadMedia(path: media.storagePath)
        let url = temporaryURL(for: media)
        try data.write(to: url, options: .atomic)
        return url
    }

    func removeCachedThumbnail(for media: Media) {
        thumbnails.remove(path: media.storagePath)
        try? FileManager.default.removeItem(at: temporaryURL(for: media))
    }

    func clearThumbnails() {
        thumbnails.clear()
    }

    private func temporaryURL(for media: Media) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("scout-share-\(media.id.uuidString)")
            .appendingPathExtension(media.fileExtension)
    }
}
