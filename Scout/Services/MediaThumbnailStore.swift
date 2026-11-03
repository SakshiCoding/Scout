import CoreGraphics
import Foundation

/// One in-memory store per AppState; never persists private journal previews to disk.
@MainActor
final class MediaThumbnailStore {
    private struct Key: Hashable {
        let path: String
        let size: MediaPreviewSize
        var cacheKey: NSString { "\(size.rawValue):\(path)" as NSString }
    }
    private struct Flight {
        let id: UUID
        let task: Task<CGImage?, Never>
    }
    private let cache = NSCache<NSString, CGImage>()
    private var inFlight: [Key: Flight] = [:]
    private var generation = UUID()

    init() {
        // NSCache budgets are advisory; decoded byte costs let it evict large previews first.
        cache.totalCostLimit = 32 * 1_024 * 1_024
        cache.countLimit = 128
    }

    func thumbnail(for media: Media, size: MediaPreviewSize = .thumbnail,
                   load: @escaping @MainActor () async throws -> Data) async -> CGImage? {
        guard !Task.isCancelled else { return nil }
        let key = Key(path: media.storagePath, size: size)
        if let cached = cache.object(forKey: key.cacheKey) { return cached }
        let scope = generation
        let task: Task<CGImage?, Never>
        if let existing = inFlight[key] {
            task = existing.task
        } else {
            let id = UUID()
            task = Task { [weak self] in
                guard let data = try? await load(), !Task.isCancelled else {
                    self?.finish(key: key, id: id)
                    return nil
                }
                let rendering = Task.detached(priority: .utility) {
                    await MediaThumbnailRenderer.render(data: data, mediaType: media.mediaType,
                                                        fileExtension: media.fileExtension, size: size)
                }
                let image = await withTaskCancellationHandler {
                    await rendering.value
                } onCancel: { rendering.cancel() }
                guard let self, !Task.isCancelled, self.generation == scope,
                      self.inFlight[key]?.id == id else { return nil }
                if let image {
                    self.cache.setObject(image, forKey: key.cacheKey,
                                         cost: image.bytesPerRow * image.height)
                }
                self.finish(key: key, id: id)
                return image
            }
            inFlight[key] = Flight(id: id, task: task)
        }
        let image = await task.value
        guard !Task.isCancelled, generation == scope else { return nil }
        return image
    }

    func remove(path: String) {
        for size in MediaPreviewSize.allCases {
            let key = Key(path: path, size: size)
            cache.removeObject(forKey: key.cacheKey)
            inFlight.removeValue(forKey: key)?.task.cancel()
        }
    }

    func clear() {
        generation = UUID()
        cache.removeAllObjects()
        let tasks = inFlight.values.map(\.task)
        inFlight.removeAll()
        tasks.forEach { $0.cancel() }
    }

    private func finish(key: Key, id: UUID) {
        if inFlight[key]?.id == id { inFlight.removeValue(forKey: key) }
    }
}
