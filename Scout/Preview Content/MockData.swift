import Foundation

// MARK: - Circle mocks

extension ScoutCircle {
    static let mockMorgan = ScoutCircle(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Morgan & me",
        shortName: "Morgan",
        accentColor: "#CC5500",
        members: [
            CircleMember(circleId: UUID(), userId: UUID(), initials: "M"),
            CircleMember(circleId: UUID(), userId: UUID(), initials: "J"),
        ],
        restaurantCount: 42,
        visitedCount: 18,
        photoCount: 47
    )

    static let mockFamily = ScoutCircle(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Family",
        shortName: "Family",
        accentColor: "#7A8B3C",
        members: [
            CircleMember(circleId: UUID(), userId: UUID(), initials: "M"),
            CircleMember(circleId: UUID(), userId: UUID(), initials: "D"),
            CircleMember(circleId: UUID(), userId: UUID(), initials: "A"),
        ],
        restaurantCount: 28,
        visitedCount: 9,
        photoCount: 22
    )

    static let mockRoommates = ScoutCircle(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Roommates",
        shortName: "Roomies",
        accentColor: "#3D5A80",
        members: [
            CircleMember(circleId: UUID(), userId: UUID(), initials: "K"),
            CircleMember(circleId: UUID(), userId: UUID(), initials: "L"),
            CircleMember(circleId: UUID(), userId: UUID(), initials: "B"),
        ],
        restaurantCount: 19,
        visitedCount: 12,
        photoCount: 31
    )

    static let mockAll: [ScoutCircle] = [.mockMorgan, .mockFamily, .mockRoommates]
}

// MARK: - Restaurant mocks

extension Restaurant {
    static let mockList: [Restaurant] = [
        Restaurant(circleId: ScoutCircle.mockMorgan.id,
                   name: "Kismet",
                   cuisine: "Mediterranean",
                   priceTier: .two,
                   vibeTags: ["Date night", "Patio"],
                   rating: 4.7,
                   distanceMiles: 0.4),
        Restaurant(circleId: ScoutCircle.mockMorgan.id,
                   name: "Sunshine Laundry",
                   cuisine: "American",
                   priceTier: .two,
                   vibeTags: ["Brunch", "Casual"],
                   rating: 4.5,
                   distanceMiles: 0.8),
        Restaurant(circleId: ScoutCircle.mockMorgan.id,
                   name: "Sonoratown",
                   cuisine: "Mexican",
                   priceTier: .one,
                   vibeTags: ["Quick bite", "Casual"],
                   rating: 4.8,
                   distanceMiles: 1.2),
        Restaurant(circleId: ScoutCircle.mockMorgan.id,
                   name: "Night + Market",
                   cuisine: "Thai",
                   priceTier: .two,
                   vibeTags: ["Lively", "Group"],
                   rating: 4.6,
                   distanceMiles: 1.9),
        Restaurant(circleId: ScoutCircle.mockMorgan.id,
                   name: "Republique",
                   cuisine: "French",
                   priceTier: .three,
                   vibeTags: ["Special occasion", "Quiet"],
                   rating: 4.9,
                   distanceMiles: 2.4),
    ]
}

// MARK: - AppState preview helper

extension AppState {
    @MainActor
    static var preview: AppState {
        let state               = AppState()
        state.isAuthenticated   = true
        state.isLoadingAuth     = false
        state.circles           = ScoutCircle.mockAll
        state.activeCircle      = .mockMorgan
        state.restaurants       = Restaurant.mockList
        return state
    }
}
