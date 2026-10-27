import SwiftUI

struct JoinCircleSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    var initialCode: CircleInviteCode?
    var onJoined: () -> Void = {}
    @State private var input = ""
    @State private var preview: CircleInvitePreview?
    @State private var checkedCode: CircleInviteCode?
    @State private var isBusy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScoutBrandMark(size: 60)
                    Text("Join their atlas").font(Atlas.Font.serif(32)).foregroundStyle(Atlas.ink)
                    Text("Paste an invitation link or code from someone in the circle.")
                        .font(Atlas.Font.sans(15)).foregroundStyle(Atlas.ink2)
                    TextField("Invitation link or code", text: $input, axis: .vertical)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .font(Atlas.Font.sans(14)).padding(16).background(Atlas.paper2, in: RoundedRectangle(cornerRadius: 16))
                        .disabled(isBusy)
                        .onChange(of: input) { _, _ in preview = nil; checkedCode = nil; error = nil }
                    Button("Check invitation") { Task { await check() } }
                        .buttonStyle(.bordered).controlSize(.large).tint(Atlas.burnt).disabled(isBusy || input.isEmpty)
                    if let preview {
                        Text(preview.circleName).font(Atlas.Font.serif(28)).foregroundStyle(Atlas.ink)
                        Text("Members share this circle's wishlist and journal. Only join people you trust.")
                            .font(Atlas.Font.sans(14)).foregroundStyle(Atlas.ink2)
                        Text("Expires \(preview.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink3)
                        Button(preview.isMember ? "Open circle" : "Join circle") { Task { await join() } }
                            .buttonStyle(AtlasPrimaryButtonStyle()).disabled(isBusy)
                    }
                    if isBusy { ProgressView().tint(Atlas.burnt) }
                    if let error { Text(error).font(Atlas.Font.sans(13)).foregroundStyle(Atlas.burnt) }
                }.padding(Atlas.screenHPad)
            }
            .background(Atlas.paper.ignoresSafeArea())
            .navigationTitle("Join a circle").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(isBusy) } }
        }.task {
            if let initialCode { input = initialCode.url.absoluteString; await check() }
        }
        .interactiveDismissDisabled(isBusy)
    }

    private func check() async {
        guard !isBusy else { return }
        guard let code = CircleInviteCode(input) else {
            error = "Paste a valid Scout invitation link or its 32-character code."
            return
        }
        isBusy = true
        error = nil
        defer { isBusy = false }
        do {
            let result = try await appState.supabase.previewInvitation(code)
            guard !Task.isCancelled, CircleInviteCode(input)?.value == code.value else { return }
            preview = result
            checkedCode = code
        } catch {
            preview = nil
            checkedCode = nil
            self.error = "Couldn't check this invitation. It may be expired or revoked. Check your connection and try again."
        }
    }

    private func join() async {
        guard !isBusy, let code = checkedCode else { return }
        isBusy = true
        error = nil
        defer { isBusy = false }
        do {
            try await appState.joinCircle(using: code)
            onJoined()
            dismiss()
        } catch { self.error = "Couldn't confirm joining. Check your connection and try again." }
    }
}
