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

    // MARK: - Wishlist UI state
    var activeTab: WishlistTab = .wantToTry
    var filterState = FilterState()

    // MARK: - Services
    let supabase  = SupabaseService.shared
    let auth      = AuthService()
    let location  = LocationService()

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
        UserDefaults.standard.set(circle.id.uuidString, forKey: "activeCircleId")
        Task { await loadRestaurants() }
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
    }

    func markVisited(restaurantId: UUID) async throws {
        try await supabase.markVisited(restaurantId)
        if let idx = restaurants.firstIndex(where: { $0.id == restaurantId }) {
            restaurants[idx].status = .visited
        }
    }

    // MARK: - Private

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
            Task { await loadRestaurants() }
        }
    }
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
