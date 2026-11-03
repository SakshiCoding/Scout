import Foundation

enum RestaurantJournalCover {
    /// Bound automatic retries; videos and media from other circles/restaurants are never covers.
    static func candidates(restaurantId: UUID, circleId: UUID, media: [Media]) -> [Media] {
        Array(media.filter {
            guard $0.restaurantId == restaurantId, $0.circleId == circleId, $0.mediaType == .photo else { return false }
            let path = $0.storagePath.split(separator: "/", omittingEmptySubsequences: false)
            return path.count >= 3 && path[0] == "circles"
                && UUID(uuidString: String(path[1])) == circleId && !path.last!.isEmpty
                && !path.contains("..") && !path.contains(".")
        }.sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }.prefix(3))
    }

    struct PhotoKey: Hashable {
        let id: UUID
        let path: String
        init(_ media: Media) { id = media.id; path = media.storagePath }
    }
}
