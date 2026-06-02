import Foundation

struct Media: Identifiable, Codable {
    let id: UUID
    var restaurantId: UUID?
    var visitId: UUID?
    var circleId: UUID
    var userId: UUID
    var storagePath: String
    var mediaType: MediaType
    let createdAt: Date

    enum MediaType: String, Codable {
        case photo, video
    }

    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case visitId      = "visit_id"
        case circleId     = "circle_id"
        case userId       = "user_id"
        case storagePath  = "storage_path"
        case mediaType    = "media_type"
        case createdAt    = "created_at"
    }

    var fileExtension: String {
        let pathExtension = (storagePath as NSString).pathExtension
        guard !pathExtension.isEmpty else {
            return mediaType == .video ? "mov" : "jpg"
        }
        return pathExtension
    }

    var contentType: String {
        switch fileExtension.lowercased() {
        case "png": return "image/png"
        case "heic", "heif": return "image/heic"
        case "mp4": return "video/mp4"
        case "m4v": return "video/x-m4v"
        case "mov": return "video/quicktime"
        default: return mediaType == .video ? "video/quicktime" : "image/jpeg"
        }
    }
}

struct VisitMediaUpload {
    let data: Data
    let mediaType: Media.MediaType
    let fileExtension: String
    let contentType: String

    static func photo(_ data: Data) -> VisitMediaUpload {
        VisitMediaUpload(
            data: data,
            mediaType: .photo,
            fileExtension: "jpg",
            contentType: "image/jpeg"
        )
    }

    static func video(_ data: Data, fileExtension: String = "mov", contentType: String = "video/quicktime") -> VisitMediaUpload {
        VisitMediaUpload(
            data: data,
            mediaType: .video,
            fileExtension: fileExtension,
            contentType: contentType
        )
    }
}
