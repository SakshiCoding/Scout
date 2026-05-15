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

        let filtered = base.filter { r in
            if let cuisine = filterState.cuisine,
               r.cuisine?.lowercased() != cuisine.lowercased() { return false }
            if !filterState.priceTiers.isEmpty,
               let tier = r.priceTier,
               !filterState.priceTiers.contains(tier) { return false }
            if !filterState.vibeTags.isEmpty,
               filterState.vibeTags.isDisjoint(with: Set(r.vibeTags)) { return false }
            if let maxDist = filterState.maxDistanceMiles,
               let dist = r.distanceMiles,
               dist > maxDist { return false }
            return true
        }

        return location.sortedByDistance(filtered)
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
        restaurants.insert(saved, at: 0)
    }

    func bulkImport(names: [String]) async throws {
        guard let circleId = activeCircle?.id,
              let userId   = currentUser?.id else { return }
        try await supabase.bulkAddRestaurants(names, circleId: circleId, addedBy: userId)
        await loadRestaurants()
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

    mutating func reset() {
        cuisine           = nil
        priceTiers        = []
        vibeTags          = []
        maxDistanceMiles  = nil
    }
}
