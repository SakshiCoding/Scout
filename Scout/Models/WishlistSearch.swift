import Foundation

enum WishlistSearch {
    static func matches(_ restaurant: Restaurant, query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let text =
            ([restaurant.name, restaurant.cuisine ?? "", restaurant.address ?? ""] + restaurant.vibeTags)
            .joined(separator: " ")
        return text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
