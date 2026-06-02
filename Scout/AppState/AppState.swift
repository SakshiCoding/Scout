import SwiftUI
import Supabase

@MainActor
@Observable
final class AppState {
    // MARK: - Auth
    var currentUser: User?
    var isAuthenticated = false
    var isLoadingAuth   = true

    // MARK: - Circles
    var circles: [ScoutCircle] = []
    var activeCircle: ScoutCircle?

    // MARK: - Restaurants
    var restaurants: [Restaurant] = []
    var isLoadingRestaurants = false

    // MARK: - Journal
    var visits: [Visit] = []
    var media: [Media] = []
    var isLoadingJournal = false
    private var pendingVisitIds: Set<UUID> = []
    private var pendingMediaIds: Set<UUID> = []
    private var journalLoadRequestId = UUID()

    // MARK: - Wishlist UI state
    var activeTab: WishlistTab = .wantToTry
    var filterState = FilterState()

    // MARK: - Services
    let supabase  = SupabaseService.shared
    let auth      = AuthService()
    let location  = LocationService()
    let mediaService = MediaService()

    init() {
        observeAuth()
    }

    // MARK: - Computed

    var filteredRestaurants: [Restaurant] {
        let base = restaurants.filter { $0.status == (activeTab == .wantToTry ? .wantToTry : .visited) }
        return location.sortedByDistance(base.filter { filterState.matches($0) })
    }

    var wantToTryCount: Int { restaurants.filter { $0.status == .wantToTry }.count }
    var visitedCount: Int   { restaurants.filter { $0.status == .visited }.count }

    var journalLocations: [JournalLocationSummary] {
        let visitsByRestaurant = Dictionary(grouping: visits, by: \.restaurantId)

        return restaurants
            .filter { $0.status == .visited }
            .map { restaurant in
                let restaurantVisits = visitsByRestaurant[restaurant.id, default: []]
                let restaurantMedia = media.filter { $0.restaurantId == restaurant.id }
                return JournalLocationSummary(
                    restaurant: restaurant,
                    visits: restaurantVisits.sorted { $0.visitedAt > $1.visitedAt },
                    media: restaurantMedia,
                    lastVisitedAt: restaurantVisits.map(\.visitedAt).max() ?? restaurant.createdAt
                )
            }
            .sorted { $0.lastVisitedAt > $1.lastVisitedAt }
    }

    // MARK: - Actions

    func loadCircles() async {
        guard let userId = currentUser?.id else { return }
        do {
            var fetched = try await supabase.fetchCircles(for: userId)
            // Populate counts
            for i in fetched.indices {
                let rests = try? await supabase.fetchRestaurants(circleId: fetched[i].id)
                fetched[i].restaurantCount = rests?.filter { $0.status == .wantToTry }.count ?? 0
                fetched[i].visitedCount    = rests?.filter { $0.status == .visited }.count ?? 0
            }
            circles = fetched
            restoreActiveCircle()
        } catch {
            // Circles will remain empty; user sees empty state
        }
    }

    func loadRestaurants() async {
        guard let circleId = activeCircle?.id else { return }
        isLoadingRestaurants = true
        do {
            restaurants = try await supabase.fetchRestaurants(circleId: circleId)
        } catch {
            restaurants = []
        }
        isLoadingRestaurants = false
    }

    func loadJournal() async {
        guard let circleId = activeCircle?.id else { return }
        let requestId = UUID()
        journalLoadRequestId = requestId
        isLoadingJournal = true
        defer {
            if activeCircle?.id == circleId && journalLoadRequestId == requestId {
                isLoadingJournal = false
            }
        }

        do {
            let fetchedVisits = try await supabase.fetchVisits(circleId: circleId)
            guard activeCircle?.id == circleId, journalLoadRequestId == requestId else { return }
            let fetchedIds = Set(fetchedVisits.map(\.id))
            let pendingVisits = visits.filter {
                $0.circleId == circleId
                    && pendingVisitIds.contains($0.id)
                    && !fetchedIds.contains($0.id)
            }
            visits = (fetchedVisits + pendingVisits).sorted { $0.visitedAt > $1.visitedAt }
            pendingVisitIds.subtract(fetchedIds)
        } catch {
            // Preserve locally confirmed entries if a refresh is temporarily unavailable.
        }

        do {
            let fetchedMedia = try await supabase.fetchMedia(circleId: circleId)
            guard activeCircle?.id == circleId, journalLoadRequestId == requestId else { return }
            let fetchedIds = Set(fetchedMedia.map(\.id))
            let pendingMedia = media.filter {
                $0.circleId == circleId
                    && pendingMediaIds.contains($0.id)
                    && !fetchedIds.contains($0.id)
            }
            media = (fetchedMedia + pendingMedia).sorted { $0.createdAt > $1.createdAt }
            pendingMediaIds.subtract(fetchedIds)
        } catch {
            // Preserve locally confirmed uploads if a refresh is temporarily unavailable.
        }
    }

    func createCircle(name: String, accentColor: String = "#CC5500") async throws {
        guard let userId = currentUser?.id else { return }
        let initials = currentUser?.email.map { String($0.prefix(2).uppercased()) } ?? "?"
        let circle = try await supabase.createCircle(
            name: name,
            accentColor: accentColor,
            userId: userId,
            userInitials: initials
        )
        circles.append(circle)
        switchCircle(to: circle)
    }

    func switchCircle(to circle: ScoutCircle) {
        activeCircle = circle
        visits = []
        media = []
        pendingVisitIds = []
        pendingMediaIds = []
        UserDefaults.standard.set(circle.id.uuidString, forKey: "activeCircleId")
        Task {
            async let restaurants: Void = loadRestaurants()
            async let journal: Void = loadJournal()
            _ = await (restaurants, journal)
        }
    }

    func addRestaurant(_ restaurant: Restaurant) async throws {
        let saved = try await supabase.addRestaurant(restaurant)
        activeTab = .wantToTry
        restaurants.insert(saved, at: 0)
    }

    func bulkImport(names: [String]) async throws {
        guard let circleId = activeCircle?.id,
              let userId   = currentUser?.id else { return }
        let saved = try await supabase.bulkAddRestaurants(names, circleId: circleId, addedBy: userId)
        activeTab = .wantToTry
        restaurants.insert(contentsOf: saved.reversed(), at: 0)
    }

    func updateRestaurant(_ updated: Restaurant) async throws {
        try await supabase.updateRestaurant(updated)
        if let idx = restaurants.firstIndex(where: { $0.id == updated.id }) {
            var merged = updated
            merged.distanceMiles = restaurants[idx].distanceMiles
            restaurants[idx] = merged
        }
    }

    func deleteRestaurant(restaurantId: UUID) async throws {
        try await supabase.deleteRestaurant(restaurantId)
        restaurants.removeAll { $0.id == restaurantId }
        visits.removeAll { $0.restaurantId == restaurantId }
        media.removeAll { $0.restaurantId == restaurantId }
    }

    func markVisited(restaurantId: UUID) async throws {
        try await supabase.markVisited(restaurantId)
        if let idx = restaurants.firstIndex(where: { $0.id == restaurantId }) {
            restaurants[idx].status = .visited
        }
    }

    func markVisitedWithRecord(
        restaurantId: UUID,
        rating: Double?,
        visitNote: String?,
        photos: [Data] = []
    ) async throws {
        guard let userId = currentUser?.id,
              let circleId = activeCircle?.id else { return }

        try await supabase.markVisited(restaurantId)

        if let idx = restaurants.firstIndex(where: { $0.id == restaurantId }) {
            restaurants[idx].status = .visited
            if let rating { restaurants[idx].rating = rating }
        }

        if let rating {
            try? await supabase.updateRestaurantRating(restaurantId, rating: rating)
        }
        let visit = Visit(
            restaurantId: restaurantId,
            circleId: circleId,
            userId: userId,
            visitedAt: Date(),
            notes: visitNote,
            rating: rating
        )
        let savedVisit = try await supabase.addVisit(visit)
        upsertVisit(savedVisit)
        pendingVisitIds.insert(savedVisit.id)

        if !photos.isEmpty {
            do {
                let uploadedMedia = try await supabase.uploadVisitPhotos(
                    photos,
                    visitId: savedVisit.id,
                    restaurantId: restaurantId,
                    circleId: circleId,
                    userId: userId
                )
                uploadedMedia.forEach(upsertMedia)
            } catch {
                await loadJournal()
                throw error
            }
        }

        await loadJournal()
    }

    func addJournalEntry(
        restaurantId: UUID,
        visitedAt: Date,
        occasion: String?,
        visitNote: String?,
        vibeTags: [String],
        mediaUploads: [VisitMediaUpload]
    ) async throws {
        guard let userId = currentUser?.id,
              let circleId = activeCircle?.id else { return }

        try await supabase.markVisited(restaurantId)
        if let idx = restaurants.firstIndex(where: { $0.id == restaurantId }) {
            restaurants[idx].status = .visited
        }

        let visit = Visit(
            restaurantId: restaurantId,
            circleId: circleId,
            userId: userId,
            visitedAt: visitedAt,
            notes: visitNote,
            occasion: occasion,
            vibeTags: vibeTags
        )
        let savedVisit = try await supabase.addVisit(visit)
        upsertVisit(savedVisit)
        pendingVisitIds.insert(savedVisit.id)

        if !mediaUploads.isEmpty {
            do {
                let uploadedMedia = try await supabase.uploadVisitMedia(
                    mediaUploads,
                    visitId: savedVisit.id,
                    restaurantId: restaurantId,
                    circleId: circleId,
                    userId: userId
                )
                uploadedMedia.forEach(upsertMedia)
            } catch {
                await loadJournal()
                throw error
            }
        }

        await loadJournal()
    }

    func deleteMedia(_ item: Media) async throws {
        try await supabase.deleteMedia(item)
        mediaService.removeCachedThumbnail(for: item)
        media.removeAll { $0.id == item.id }
        pendingMediaIds.remove(item.id)
    }

    func deleteJournalEntry(_ visit: Visit) async throws {
        let entryMedia = media.filter { $0.visitId == visit.id }
        try await supabase.deleteVisit(visit, media: entryMedia)
        entryMedia.forEach(mediaService.removeCachedThumbnail)
        media.removeAll { $0.visitId == visit.id }
        visits.removeAll { $0.id == visit.id }
        pendingMediaIds.subtract(entryMedia.map(\.id))
        pendingVisitIds.remove(visit.id)
    }

    func crossPostMedia(
        _ item: Media,
        visit: Visit,
        restaurant: Restaurant,
        to circle: ScoutCircle
    ) async throws {
        guard let userId = currentUser?.id else { return }

        let targetRestaurants = try await supabase.fetchRestaurants(circleId: circle.id)
        let matchingRestaurant = targetRestaurants.first {
            $0.name.compare(restaurant.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        let targetRestaurant: Restaurant
        if let matchingRestaurant {
            targetRestaurant = matchingRestaurant
        } else {
            targetRestaurant = try await supabase.addRestaurant(Restaurant(
                circleId: circle.id,
                name: restaurant.name,
                cuisine: restaurant.cuisine,
                establishmentType: restaurant.establishmentType,
                priceTier: restaurant.priceTier,
                address: restaurant.address,
                latitude: restaurant.latitude,
                longitude: restaurant.longitude,
                status: .visited,
                notes: restaurant.notes,
                vibeTags: restaurant.vibeTags,
                rating: restaurant.rating,
                photoUrl: restaurant.photoUrl,
                addedBy: userId
            ))
        }

        try await supabase.markVisited(targetRestaurant.id)
        let targetVisit = try await supabase.addVisit(Visit(
            restaurantId: targetRestaurant.id,
            circleId: circle.id,
            userId: userId,
            visitedAt: visit.visitedAt,
            notes: visit.notes,
            rating: visit.rating,
            occasion: visit.occasion,
            vibeTags: visit.vibeTags
        ))
        let data = try await supabase.downloadMedia(path: item.storagePath)
        _ = try await supabase.uploadVisitMedia(
            [VisitMediaUpload(
                data: data,
                mediaType: item.mediaType,
                fileExtension: item.fileExtension,
                contentType: item.contentType
            )],
            visitId: targetVisit.id,
            restaurantId: targetRestaurant.id,
            circleId: circle.id,
            userId: userId
        )
    }

    // MARK: - Private

    private func upsertVisit(_ visit: Visit) {
        visits.removeAll { $0.id == visit.id }
        visits.append(visit)
        visits.sort { $0.visitedAt > $1.visitedAt }
    }

    private func upsertMedia(_ item: Media) {
        media.removeAll { $0.id == item.id }
        media.append(item)
        media.sort { $0.createdAt > $1.createdAt }
        pendingMediaIds.insert(item.id)
    }

    private func observeAuth() {
        Task {
            await auth.checkSession()
            isAuthenticated = auth.isAuthenticated
            currentUser     = auth.currentUser
            isLoadingAuth   = false
            if isAuthenticated {
                await loadCircles()
                location.requestWhenInUse()
                location.startUpdating()
            }
        }
    }

    private func restoreActiveCircle() {
        let savedId = UserDefaults.standard.string(forKey: "activeCircleId")
        activeCircle = circles.first { $0.id.uuidString == savedId } ?? circles.first
        if activeCircle != nil {
            Task {
                async let restaurants: Void = loadRestaurants()
                async let journal: Void = loadJournal()
                _ = await (restaurants, journal)
            }
        }
    }
}

struct JournalLocationSummary: Identifiable {
    let restaurant: Restaurant
    let visits: [Visit]
    let media: [Media]
    let lastVisitedAt: Date

    var id: UUID { restaurant.id }
    var photoCount: Int { media.filter { $0.mediaType == .photo }.count }
    var videoCount: Int { media.filter { $0.mediaType == .video }.count }
}

// MARK: - Supporting types

enum WishlistTab {
    case wantToTry, visited
}

struct FilterState {
    var cuisine: String?
    var priceTiers: Set<Restaurant.PriceTier> = []
    var vibeTags: Set<String> = []
    var maxDistanceMiles: Double?

    var isActive: Bool {
        cuisine != nil || !priceTiers.isEmpty || !vibeTags.isEmpty || maxDistanceMiles != nil
    }

    func matches(_ r: Restaurant) -> Bool {
        if let cuisine, r.cuisine?.lowercased() != cuisine.lowercased() { return false }
        if !priceTiers.isEmpty, let tier = r.priceTier,
           !priceTiers.contains(tier) { return false }
        if !vibeTags.isEmpty,
           vibeTags.isDisjoint(with: Set(r.vibeTags)) { return false }
        if let maxDist = maxDistanceMiles, let dist = r.distanceMiles,
           dist > maxDist { return false }
        return true
    }

    mutating func reset() {
        cuisine           = nil
        priceTiers        = []
        vibeTags          = []
        maxDistanceMiles  = nil
    }
}
