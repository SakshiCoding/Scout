import Foundation

extension Set where Element == String {
    var establishmentTypeHint: Restaurant.EstablishmentType? {
        if contains("cafe") || contains("coffee_shop") { return .cafe }
        if contains("bakery") { return .bakery }
        if contains("brewery") { return .brewery }
        if contains("winery") { return .winery }
        if contains("bar") || contains("night_club") { return .bar }
        if contains("restaurant") || contains(where: { $0.hasSuffix("_restaurant") }) {
            return .restaurant
        }
        return nil
    }

    var cuisineHint: String? {
        let cuisines: [(String, String)] = [
            ("american_restaurant", "American"),
            ("barbecue_restaurant", "BBQ"),
            ("brazilian_restaurant", "Brazilian"),
            ("chinese_restaurant", "Chinese"),
            ("french_restaurant", "French"),
            ("greek_restaurant", "Greek"),
            ("hamburger_restaurant", "American"),
            ("indian_restaurant", "Indian"),
            ("indonesian_restaurant", "Indonesian"),
            ("italian_restaurant", "Italian"),
            ("japanese_restaurant", "Japanese"),
            ("korean_restaurant", "Korean"),
            ("lebanese_restaurant", "Lebanese"),
            ("mediterranean_restaurant", "Mediterranean"),
            ("mexican_restaurant", "Mexican"),
            ("middle_eastern_restaurant", "Middle Eastern"),
            ("pizza_restaurant", "Italian"),
            ("ramen_restaurant", "Japanese"),
            ("seafood_restaurant", "Seafood"),
            ("spanish_restaurant", "Spanish"),
            ("steak_house", "Steakhouse"),
            ("sushi_restaurant", "Japanese"),
            ("thai_restaurant", "Thai"),
            ("turkish_restaurant", "Turkish"),
            ("vietnamese_restaurant", "Vietnamese"),
        ]
        return cuisines.first { contains($0.0) }?.1
    }

    var vibeHints: Set<String> {
        var hints: Set<String> = []
        if contains("cafe") || contains("coffee_shop") || contains("bakery") {
            hints.formUnion(["Casual", "Quick bite"])
        }
        if contains("bar") || contains("night_club") {
            hints.formUnion(["Late night", "Lively"])
        }
        if contains("sports_bar") {
            hints.formUnion(["Lively", "Group"])
        }
        if contains("brewery") {
            hints.formUnion(["Casual", "Lively"])
        }
        if contains("winery") {
            hints.formUnion(["Date night", "Special occasion"])
        }
        if contains("fine_dining_restaurant") {
            hints.formUnion(["Date night", "Special occasion", "Tasting menu"])
        }
        if contains("fast_food_restaurant") || contains("hamburger_restaurant") || contains("sandwich_shop") {
            hints.formUnion(["Quick bite", "Casual"])
        }
        if contains("brunch_restaurant") || contains("breakfast_restaurant") {
            hints.insert("Brunch")
        }
        return hints
    }
}
