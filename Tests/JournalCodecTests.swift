import AVFoundation
import Foundation

/// Reuse the exact real files whose hosted download bytes were verified.
@main struct JournalCodecTests {
    static func main() async throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1])
        for ext in ["jpg", "png", "heic", "heif", "mov", "mp4", "m4v"] {
            let url = directory.appendingPathComponent("fixture." + ext)
            let imported = try JournalMediaFile.read(from: url)
            let video = ["mov", "mp4", "m4v"].contains(ext)
            let item = Media(id: UUID(), circleId: UUID(), userId: UUID(), storagePath: url.lastPathComponent,
                             mediaType: video ? .video : .photo, createdAt: Date())
            try ScoutMediaUploadPolicy.validate(VisitMediaUpload(data: imported.data, mediaType: item.mediaType,
                fileExtension: imported.fileExtension, contentType: item.contentType))
            let image = await Task.detached {
                await MediaThumbnailRenderer.render(data: imported.data, mediaType: item.mediaType,
                                                   fileExtension: imported.fileExtension, size: .thumbnail)
            }.value
            precondition(image != nil && max(image!.width, image!.height) <= 512)
            if video {
                let asset = AVURLAsset(url: url)
                let duration = try await asset.load(.duration)
                let playable = try await asset.load(.isPlayable)
                precondition(playable && duration.seconds > 0)
            }
            print("PASS native \(ext) fixture import, upload policy, bounded poster/photo decode\(video ? ", playable video and duration" : "")")
        }
    }
}
