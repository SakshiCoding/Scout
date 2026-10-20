import Foundation

@main private struct PickSessionTests {
    static func main() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = fractional.date(from: text) ?? ISO8601DateFormatter().date(from: text) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid date"))
            }
            return date
        }
        let s = try decoder.decode(SharedPickSession.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let me = s.memberIds[0], partner = s.memberIds[1], first = s.restaurantIds[0]
        func state(votes: [SharedPickVote], match: UUID? = nil, revision: Int? = nil, id: UUID? = nil) -> SharedPickSession {
            SharedPickSession(id: id ?? s.id, circleId: s.circleId, sessionDay: s.sessionDay, timeWindow: s.timeWindow,
                restaurantIds: s.restaurantIds, memberIds: s.memberIds, matchedRestaurantId: match,
                revision: revision ?? s.revision, votes: votes, restaurants: s.restaurants)
        }
        let initial = PickSession(snapshot: s, userId: me)
        precondition(initial.queue.map(\.id) == s.restaurantIds)
        precondition(initial.currentCard?.id == first && initial.nextCard != nil && initial.backCard != nil)
        precondition(initial.currentIndex == 0 && !initial.canUndo && !initial.isComplete)
        precondition(s.progress(for: partner) == 0 && initial.firstMatch == nil)
        let vote = SharedPickVote(userId: me, restaurantId: first, isYes: true)
        let voted = state(votes: [vote], revision: s.revision + 1)
        let view = PickSession(snapshot: voted, userId: me)
        precondition(view.currentIndex == 1 && view.lastVotedId == first && view.canUndo)
        precondition(voted.progress(for: partner) == 0 && view.firstMatch == nil)
        precondition(!s.canReplace(voted) && voted.canReplace(s))
        let newRound = state(votes: [], revision: voted.revision + 1, id: UUID())
        precondition(newRound.canReplace(voted) && !voted.canReplace(newRound))
        let bothYes = state(votes: [vote, SharedPickVote(userId: partner, restaurantId: first, isYes: true)])
        precondition(PickSession(snapshot: bothYes, userId: me).firstMatch == nil) // only the server declares a winner
        let matched = state(votes: bothYes.votes, match: first)
        precondition(PickSession(snapshot: matched, userId: me).firstMatch?.id == first)
        precondition(!PickSession(snapshot: matched, userId: me).canUndo)
        let complete = state(votes: s.memberIds.flatMap { user in
            s.restaurantIds.map { SharedPickVote(userId: user, restaurantId: $0, isYes: false) }
        })
        precondition(complete.everyoneFinished)
        precondition(PickSession(snapshot: complete, userId: me).isComplete)
        precondition(PickSession(snapshot: complete, userId: me).currentCard == nil)
        precondition(!voted.everyoneFinished)
        print("PASS real SQL snapshot decoding, shared card order, acknowledged progress, waiting, undo, server-only match, stale-response rejection, completion")
    }
}
