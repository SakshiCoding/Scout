import SwiftUI

struct MarkVisitedSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    let restaurant: Restaurant

    @State private var visitedAt = Date()
    @State private var rating: Double?
    @State private var note = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var circle: ScoutCircle? { appState.activeCircle }
    private var circleName: String { circle?.displayShortName ?? "this circle" }
    private var accent: Color { circle?.accentSwiftUIColor ?? Atlas.burnt }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Capsule()
                        .fill(Atlas.rule)
                        .frame(width: 44, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 18)

                    header
                        .padding(.horizontal, Atlas.screenHPad)

                    mediaTray
                        .padding(.horizontal, Atlas.screenHPad)
                        .padding(.top, 20)

                    visitDetails
                        .padding(.horizontal, Atlas.screenHPad)
                        .padding(.top, 18)

                    noteField
                        .padding(.horizontal, Atlas.screenHPad)
                        .padding(.top, 16)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                            .padding(.horizontal, Atlas.screenHPad)
                            .padding(.top, 12)
                    }

                    actionRow
                        .padding(.horizontal, Atlas.screenHPad)
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Atlas.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text("LOGGED FOR \(circleName.uppercased())")
                    .font(Atlas.Font.sans(11, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(1.6)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("You went to")
                    .foregroundColor(Atlas.ink)
                Text(restaurant.name)
                    .foregroundColor(Atlas.burnt)
                    .italic()
            }
            .font(Atlas.Font.serif(32))
            .lineSpacing(2)

            Text("While it's fresh, drop a photo or two and a quick note. Adds straight to \(circleName)'s journal.")
                .font(Atlas.Font.sans(13.5))
                .foregroundColor(Atlas.ink2)
                .lineSpacing(4)
                .padding(.top, 2)
        }
    }

    private var mediaTray: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Atlas.paper2)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(Atlas.ink3)
                    }
                    .frame(height: 78)
            }

            Button {} label: {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Atlas.rule, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(height: 78)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.system(size: 18, weight: .light))
                            Text("add")
                                .font(Atlas.Font.sans(9))
                                .textCase(.lowercase)
                        }
                        .foregroundColor(Atlas.ink3)
                    }
            }
            .buttonStyle(.plain)
            .disabled(true)
        }
    }

    private var visitDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("VISIT DATE")
                    .font(Atlas.Font.sans(10.5, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(1.6)

                DatePicker("Visit date", selection: $visitedAt, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Atlas.burnt)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("RATING")
                    .font(Atlas.Font.sans(10.5, weight: .medium))
                    .foregroundColor(Atlas.ink3)
                    .kerning(1.6)

                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            rating = Double(value)
                        } label: {
                            Image(systemName: (rating ?? 0) >= Double(value) ? "star.fill" : "star")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor((rating ?? 0) >= Double(value) ? Atlas.burnt : Atlas.ink3)
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if rating != nil {
                        Button("Clear") { rating = nil }
                            .font(Atlas.Font.sans(12, weight: .medium))
                            .foregroundColor(Atlas.ink3)
                    }
                }
            }
        }
    }

    private var noteField: some View {
        ZStack(alignment: .topLeading) {
            if note.isEmpty {
                Text("Add a quick note...")
                    .font(Atlas.Font.serif(15, italic: true))
                    .foregroundColor(Atlas.ink3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
            }

            TextEditor(text: $note)
                .font(Atlas.Font.serif(15, italic: true))
                .foregroundColor(Atlas.ink)
                .frame(minHeight: 96)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
                .background(.clear)
        }
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                Task { await save(skipDetails: true) }
            } label: {
                Text("Skip for now")
                    .font(Atlas.Font.sans(13.5, weight: .medium))
                    .foregroundColor(Atlas.ink2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Atlas.paper)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button {
                Task { await save(skipDetails: false) }
            } label: {
                Group {
                    if isSaving {
                        ProgressView().tint(Atlas.paper)
                    } else {
                        Text("Save to journal")
                            .font(Atlas.Font.sans(14.5, weight: .semibold))
                            .foregroundColor(Atlas.paper)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Atlas.ink)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
    }

    private func save(skipDetails: Bool) async {
        isSaving = true
        errorMessage = nil

        do {
            try await appState.saveVisit(
                for: restaurant,
                visitedAt: visitedAt,
                notes: skipDetails ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                rating: skipDetails ? nil : rating
            )
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    MarkVisitedSheet(isPresented: .constant(true), restaurant: Restaurant.mockList[0])
        .environment(AppState.preview)
}
