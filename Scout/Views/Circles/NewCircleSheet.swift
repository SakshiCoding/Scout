import SwiftUI

struct NewCircleSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var selectedColor = "#CC5500"
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let accentOptions: [(label: String, hex: String)] = [
        ("Burnt Orange", "#CC5500"),
        ("Sage",         "#7A8B3C"),
        ("Slate",        "#3D5A80"),
    ]

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CIRCLE NAME")
                            .font(Atlas.Font.sans(10.5, weight: .medium))
                            .foregroundColor(Atlas.ink3)
                            .kerning(1.6)
                        TextField("e.g. Arjun & Sakshi", text: $name)
                            .font(Atlas.Font.serif(20))
                            .foregroundColor(Atlas.ink)
                    }
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.vertical, 20)

                    Divider().background(Atlas.rule)

                    // Color picker
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ACCENT COLOR")
                            .font(Atlas.Font.sans(10.5, weight: .medium))
                            .foregroundColor(Atlas.ink3)
                            .kerning(1.6)

                        HStack(spacing: 12) {
                            ForEach(accentOptions, id: \.hex) { option in
                                Button {
                                    selectedColor = option.hex
                                } label: {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: option.hex))
                                            .frame(width: 16, height: 16)
                                        Text(option.label)
                                            .font(Atlas.Font.sans(13))
                                            .foregroundColor(Atlas.ink)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedColor == option.hex ? Atlas.paper2 : .clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedColor == option.hex ? Color(hex: option.hex) : Atlas.rule, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.vertical, 20)

                    if let err = errorMessage {
                        Text(err)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                            .padding(.horizontal, Atlas.screenHPad)
                            .padding(.top, 4)
                    }
                }
            }
            .background(Atlas.paper.ignoresSafeArea())
            .navigationTitle("New circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .font(Atlas.Font.sans(15))
                        .foregroundColor(Atlas.ink2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await create() }
                    } label: {
                        if isCreating {
                            ProgressView().tint(Atlas.burnt)
                        } else {
                            Text("Create")
                                .font(Atlas.Font.sans(15, weight: .semibold))
                                .foregroundColor(Atlas.burnt)
                        }
                    }
                    .disabled(!isValid || isCreating)
                }
            }
        }
    }

    private func create() async {
        isCreating = true
        errorMessage = nil
        do {
            try await appState.createCircle(
                name: name.trimmingCharacters(in: .whitespaces),
                accentColor: selectedColor
            )
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isCreating = false
    }
}

#Preview {
    NewCircleSheet(isPresented: .constant(true))
        .environment(AppState.preview)
}
