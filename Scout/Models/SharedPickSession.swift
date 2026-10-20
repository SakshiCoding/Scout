import Foundation

enum TimeOfDay: Int, Codable {
    case morning = 0, lunch = 1, dinner = 2
    static var current: Self {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 11 ? .morning : hour < 15 ? .lunch : .dinner
    }
    var label: String { self == .morning ? "Morning picks" : self == .lunch ? "Lunch picks" : "Dinner picks" }
    var accentLabel: String { self == .morning ? "THIS MORNING" : self == .lunch ? "TODAY" : "TONIGHT" }
    var matchedAccentLabel: String { self == .morning ? "THIS MORNING'S PICK" : self == .lunch ? "TODAY'S PICK" : "TONIGHT'S PICK" }
    var completePrefix: String { self == .morning ? "This morning: " : self == .lunch ? "Today: " : "Tonight: " }
}

struct SharedPickVote: Codable, Equatable {
    let userId: UUID
    let restaurantId: UUID
    let isYes: Bool
    enum CodingKeys: String, CodingKey {
        case userId = "user_id", restaurantId = "restaurant_id", isYes = "is_yes"
    }
}

struct SharedPickSession: Codable, Equatable {
    let id: UUID
    let circleId: UUID
    let sessionDay: String
    let timeWindow: TimeOfDay
    let restaurantIds: [UUID]
    let memberIds: [UUID]
    let matchedRestaurantId: UUID?
    let revision: Int
    let votes: [SharedPickVote]
    let restaurants: [Restaurant]

    enum CodingKeys: String, CodingKey {
        case id, revision, votes, restaurants
        case circleId = "circle_id", sessionDay = "session_day", timeWindow = "time_window"
        case restaurantIds = "restaurant_ids", memberIds = "member_ids", matchedRestaurantId = "matched_restaurant_id"
    }

    var everyoneFinished: Bool {
        !restaurantIds.isEmpty && memberIds.allSatisfy { progress(for: $0) == restaurantIds.count }
    }
    func progress(for userId: UUID) -> Int {
        Set(votes.filter { $0.userId == userId }.map(\.restaurantId)).intersection(restaurantIds).count
    }
    func canReplace(_ current: SharedPickSession?) -> Bool {
        guard let current else { return true }
        return circleId == current.circleId && revision >= current.revision
    }
}

/// A read-only view of acknowledged server votes; swiping never invents a local partner vote.
struct PickSession {
    let snapshot: SharedPickSession
    let userId: UUID
    var queue: [Restaurant] { snapshot.restaurantIds.compactMap { id in snapshot.restaurants.first { $0.id == id } } }
    var currentIndex: Int { snapshot.progress(for: userId) }
    var totalCount: Int { queue.count }
    var currentCard: Restaurant? { queue.indices.contains(currentIndex) ? queue[currentIndex] : nil }
    var nextCard: Restaurant? { queue.indices.contains(currentIndex + 1) ? queue[currentIndex + 1] : nil }
    var backCard: Restaurant? { queue.indices.contains(currentIndex + 2) ? queue[currentIndex + 2] : nil }
    var lastVotedId: UUID? { currentIndex > 0 ? snapshot.restaurantIds[currentIndex - 1] : nil }
    var isComplete: Bool { currentIndex >= totalCount }
    var canUndo: Bool { lastVotedId != nil && snapshot.matchedRestaurantId == nil }
    var timeOfDay: TimeOfDay { snapshot.timeWindow }
    var firstMatch: Restaurant? { queue.first { $0.id == snapshot.matchedRestaurantId } }
}
