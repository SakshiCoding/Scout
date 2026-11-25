import Foundation

/// Bounded journal payloads; the private bucket independently restricts types and size.
enum ScoutMediaUploadPolicy {
    nonisolated static let photoLimit = 10 * 1024 * 1024
    nonisolated static let videoLimit = 50 * 1024 * 1024
    nonisolated static let entryLimit = 100 * 1024 * 1024

    enum Failure: LocalizedError {
        case unsupported, empty, photoTooLarge, videoTooLarge, entryTooLarge, unreadable
        var errorDescription: String? {
            switch self {
            case .unsupported: return "Choose a JPEG, PNG, HEIC photo or an MP4, MOV, M4V video."
            case .empty, .unreadable: return "This file couldn’t be opened. Try another photo or video."
            case .photoTooLarge: return "This photo is too large. Choose a photo under 10 MB."
            case .videoTooLarge: return "This video is too large. Trim it to under 50 MB and try again."
            case .entryTooLarge: return "This entry has too much media. Keep attachments under 100 MB in total."
            }
        }
    }

    nonisolated static func validateSize(_ byteCount: Int, isVideo: Bool) throws {
        guard byteCount > 0 else { throw Failure.empty }
        guard byteCount <= (isVideo ? videoLimit : photoLimit) else {
            throw isVideo ? Failure.videoTooLarge : Failure.photoTooLarge
        }
    }

    static func validate(_ upload: VisitMediaUpload) throws {
        let permitted: [String: String] = upload.mediaType == .video
            ? ["mov": "video/quicktime", "mp4": "video/mp4", "m4v": "video/x-m4v"]
            : ["jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png", "heic": "image/heic", "heif": "image/heif"]
        guard permitted[upload.fileExtension] == upload.contentType else { throw Failure.unsupported }
        try validateSize(upload.data.count, isVideo: upload.mediaType == .video)
    }

    static func validate(_ uploads: [VisitMediaUpload]) throws {
        var total = 0
        for upload in uploads {
            try validate(upload)
            total += upload.data.count
            guard total <= entryLimit else { throw Failure.entryTooLarge }
        }
    }
}
