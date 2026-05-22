import SwiftUI

struct FilterSheetView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    @State private var localFilter: FilterState

    private let cuisines = ["American", "Italian", "Mexican", "Japanese", "Chinese",
                            "Thai", "Indian", "Mediterranean", "French", "Korean"]
    private let vibes    = ["Date night", "Casual", "Brunch", "Group", "Solo",
                            "Patio", "Late night", "Special occasion", "Quick bite",
                            "Lively", "Quiet", "Tasting menu"]

    init(isPresented: Binding<Bool>, currentFilter: FilterState) {
        _isPresented   = isPresented
        _localFilter   = State(initialValue: currentFilter)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()

            HStack {
                Text("Filter")
                    .font(Atlas.Font.serif(26))
                    .foregroundColor(Atlas.ink)
                Spacer()
                CloseButton { isPresented = false }
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Cuisine
                    FilterSection(title: "CUISINE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                FilterChip(label: "Any", isActive: localFilter.cuisine == nil) {
                                    localFilter.cuisine = nil
                                }
                                ForEach(cuisines, id: \.self) { c in
                                    FilterChip(label: c, isActive: localFilter.cuisine == c) {
                                        localFilter.cuisine = (localFilter.cuisine == c) ? nil : c
                                    }
                                }
                            }
                            .padding(.horizontal, Atlas.screenHPad)
                        }
                        .padding(.horizontal, -Atlas.screenHPad)
                    }

                    // Price tiers
                    FilterSection(title: "PRICE") {
                        HStack(spacing: 6) {
                            ForEach(Restaurant.PriceTier.allCases, id: \.self) { tier in
                                FilterChip(label: tier.rawValue, isActive: localFilter.priceTiers.contains(tier)) {
                                    if localFilter.priceTiers.contains(tier) {
                                        localFilter.priceTiers.remove(tier)
                                    } else {
                                        localFilter.priceTiers.insert(tier)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }

                    // Distance
                    FilterSection(title: "DISTANCE") {
                        HStack(spacing: 6) {
                            ForEach(distanceOptions, id: \.label) { opt in
                                FilterChip(label: opt.label, isActive: localFilter.maxDistanceMiles == opt.miles) {
                                    localFilter.maxDistanceMiles = (localFilter.maxDistanceMiles == opt.miles) ? nil : opt.miles
                                }
                            }
                            Spacer()
                        }
                    }

                    // Vibe tags
                    FilterSection(title: "VIBE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(vibes, id: \.self) { vibe in
                                    FilterChip(label: vibe, isActive: localFilter.vibeTags.contains(vibe)) {
                                        if localFilter.vibeTags.contains(vibe) {
                                            localFilter.vibeTags.remove(vibe)
                                        } else {
                                            localFilter.vibeTags.insert(vibe)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Atlas.screenHPad)
                        }
                        .padding(.horizontal, -Atlas.screenHPad)
                    }
                }
                .padding(.horizontal, Atlas.screenHPad)
                .padding(.bottom, 8)
            }

            // Apply / Reset CTAs
            HStack(spacing: 12) {
                Button("Reset") {
                    localFilter.reset()
                    appState.filterState.reset()
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .font(Atlas.Font.sans(14))
                .foregroundColor(Atlas.ink2)
                .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))

                Button("Apply") {
                    appState.filterState = localFilter
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .font(Atlas.Font.sans(14, weight: .semibold))
                .foregroundColor(Atlas.paper)
                .background(Atlas.ink)
                .clipShape(Capsule())
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.vertical, 16)
        }
        .background(Atlas.paper)
    }

    private struct DistanceOption {
        let label: String
        let miles: Double?
    }

    private let distanceOptions: [DistanceOption] = [
        DistanceOption(label: "Walking",  miles: 0.5),
        DistanceOption(label: "1 mi",     miles: 1.0),
        DistanceOption(label: "2 mi",     miles: 2.0),
        DistanceOption(label: "5 mi",     miles: 5.0),
    ]
}

private struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)
            content()
        }
    }
}

#Preview {
    FilterSheetView(isPresented: .constant(true), currentFilter: FilterState())
        .environment(AppState.preview)
}
