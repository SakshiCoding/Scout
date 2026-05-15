import SwiftUI

struct BulkImportView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    @State private var rawText      = ""
    @State private var parsedNames: [String] = []
    @State private var showPreview  = false
    @State private var isImporting  = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Atlas.paper.ignoresSafeArea()

                if showPreview {
                    previewStage
                } else {
                    inputStage
                }
            }
            .navigationTitle("Bulk import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .font(Atlas.Font.sans(15))
                        .foregroundColor(Atlas.ink2)
                }
                if showPreview {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") { showPreview = false }
                            .font(Atlas.Font.sans(15))
                            .foregroundColor(Atlas.ink2)
                    }
                }
            }
        }
    }

    // MARK: - Input stage

    private var inputStage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Paste your list")
                    .font(Atlas.Font.serif(28))
                    .foregroundColor(Atlas.ink)

                Text("One restaurant per line, or separated by commas.")
                    .font(Atlas.Font.sans(14))
                    .foregroundColor(Atlas.ink2)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 28)

            ZStack(alignment: .topLeading) {
                if rawText.isEmpty {
                    Text("Kismet\nSunshine Laundry\nOtto's…")
                        .font(Atlas.Font.sans(15))
                        .foregroundColor(Atlas.ink3)
                        .padding(16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $rawText)
                    .font(Atlas.Font.sans(15))
                    .foregroundColor(Atlas.ink)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .padding(12)
            }
            .frame(minHeight: 200)
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 16)

            Spacer()

            if let err = errorMessage {
                Text(err)
                    .font(Atlas.Font.sans(13))
                    .foregroundColor(Atlas.burnt)
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.bottom, 8)
            }

            Button {
                parsedNames = parseNames(rawText)
                if !parsedNames.isEmpty { showPreview = true }
            } label: {
                Text("Preview import")
                    .font(Atlas.Font.sans(14.5, weight: .semibold))
                    .foregroundColor(Atlas.paper)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Atlas.ink)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.bottom, 32)
            .disabled(rawText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Preview stage

    private var previewStage: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(parsedNames.count) places to add")
                    .font(Atlas.Font.serif(22))
                    .foregroundColor(Atlas.ink)
                Spacer()
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.vertical, 16)

            Divider().background(Atlas.rule)

            List(parsedNames, id: \.self) { name in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Atlas.rule)
                        .frame(width: 6, height: 6)
                    Text(name)
                        .font(Atlas.Font.serif(17))
                        .foregroundColor(Atlas.ink)
                }
                .listRowBackground(Atlas.paper)
                .listRowSeparatorTint(Atlas.rule)
            }
            .listStyle(.plain)
            .background(Atlas.paper)

            Divider().background(Atlas.rule)

            HStack(spacing: 12) {
                Button("Back") { showPreview = false }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .font(Atlas.Font.sans(14))
                    .foregroundColor(Atlas.ink2)
                    .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))

                Button {
                    Task { await importAll() }
                } label: {
                    if isImporting {
                        ProgressView().tint(Atlas.paper)
                    } else {
                        Text("Add \(parsedNames.count) places")
                            .font(Atlas.Font.sans(14, weight: .semibold))
                            .foregroundColor(Atlas.paper)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Atlas.ink)
                .clipShape(Capsule())
                .disabled(isImporting)
            }
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Helpers

    private func parseNames(_ text: String) -> [String] {
        let lines = text
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var seen  = Set<String>()
        return lines.filter { seen.insert($0.lowercased()).inserted }
    }

    private func importAll() async {
        guard appState.activeCircle != nil else {
            errorMessage = "Create a circle first before importing restaurants."
            return
        }
        isImporting  = true
        errorMessage = nil
        do {
            try await appState.bulkImport(names: parsedNames)
            isPresented = false
        } catch {
            errorMessage = "Import failed. Please try again."
        }
        isImporting = false
    }
}

#Preview {
    BulkImportView(isPresented: .constant(true))
        .environment(AppState.preview)
}
