import Foundation

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
