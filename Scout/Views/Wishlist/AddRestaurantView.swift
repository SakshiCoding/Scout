import SwiftUI
import Supabase

struct AddRestaurantView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    @State private var name            = ""
    @State private var cuisine         = ""
    @State private var priceTier       = Restaurant.PriceTier.two
    @State private var notes           = ""
    @State private var selectedVibeTags: Set<String> = []
    @State private var isSaving        = false
    @State private var errorMessage: String?

    private let vibes = ["Date night", "Casual", "Brunch", "Group", "Solo",
                         "Patio", "Late night", "Special occasion",
                         "Quick bite", "Lively", "Quiet", "Tasting menu"]

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Name field
                    FormField(label: "RESTAURANT NAME") {
                        TextField("e.g. Kismet", text: $name)
                            .font(Atlas.Font.serif(18))
                            .foregroundColor(Atlas.ink)
                    }

                    Divider().background(Atlas.rule)

                    // Cuisine field
                    FormField(label: "CUISINE (OPTIONAL)") {
                        TextField("e.g. Mediterranean", text: $cuisine)
                            .font(Atlas.Font.sans(15))
                            .foregroundColor(Atlas.ink)
                    }

                    Divider().background(Atlas.rule)

                    // Price tier
                    FormField(label: "PRICE RANGE") {
                        Picker("Price", selection: $priceTier) {
                            ForEach(Restaurant.PriceTier.allCases, id: \.self) { tier in
                                Text(tier.rawValue).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Atlas.burnt)
                    }

                    Divider().background(Atlas.rule)

                    // Vibe tags
                    FormField(label: "VIBE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(vibes, id: \.self) { vibe in
                                    FilterChip(label: vibe, isActive: selectedVibeTags.contains(vibe)) {
                                        if selectedVibeTags.contains(vibe) {
                                            selectedVibeTags.remove(vibe)
                                        } else {
                                            selectedVibeTags.insert(vibe)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider().background(Atlas.rule)

                    // Note
                    FormField(label: "NOTE (OPTIONAL)") {
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("A little reminder to yourself…")
                                    .font(Atlas.Font.serif(15, italic: true))
                                    .foregroundColor(Atlas.ink3)
                                    .padding(.top, 2)
                            }
                            TextEditor(text: $notes)
                                .font(Atlas.Font.serif(15, italic: true))
                                .foregroundColor(Atlas.ink)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                        }
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                            .padding(.horizontal, Atlas.screenHPad)
                            .padding(.top, 12)
                    }
                }
            }
            .background(Atlas.paper.ignoresSafeArea())
            .navigationTitle("Add restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .font(Atlas.Font.sans(15))
                        .foregroundColor(Atlas.ink2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(Atlas.burnt)
                        } else {
                            Text("Save")
                                .font(Atlas.Font.sans(15, weight: .semibold))
                                .foregroundColor(Atlas.burnt)
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func save() async {
        guard let circleId = appState.activeCircle?.id,
              let userId   = appState.currentUser?.id else {
            errorMessage = "Create a circle first before adding restaurants."
            return
        }
        isSaving = true
        errorMessage = nil
        let restaurant = Restaurant(
            circleId: circleId,
            name: name.trimmingCharacters(in: .whitespaces),
            cuisine: cuisine.isEmpty ? nil : cuisine,
            priceTier: priceTier,
            notes: notes.isEmpty ? nil : notes,
            vibeTags: Array(selectedVibeTags),
            addedBy: userId
        )
        do {
            try await appState.addRestaurant(restaurant)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Atlas.Font.sans(10.5, weight: .medium))
                .foregroundColor(Atlas.ink3)
                .kerning(1.6)
            content()
        }
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.vertical, 16)
    }
}

#Preview {
    AddRestaurantView(isPresented: .constant(true))
        .environment(AppState.preview)
}
