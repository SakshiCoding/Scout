import SwiftUI

struct InviteCircleSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let circle: ScoutCircle
    @State private var invitation: CircleInvitation?
    @State private var code: CircleInviteCode?
    @State private var isBusy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    CircleSwitcherPill(circle: circle, onTap: {})
                    Text("An atlas to share").font(Atlas.Font.serif(32)).foregroundStyle(Atlas.ink)
                    Text("Anyone with this invitation can join \(circle.name) and see its wishlist and journal. Share it with people you trust.")
                        .font(Atlas.Font.sans(15)).foregroundStyle(Atlas.ink2)
                    if let code, invitation?.isActive == true {
                        Text(code.value).font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled).padding(16)
                            .frame(maxWidth: .infinity).background(Atlas.paper2, in: RoundedRectangle(cornerRadius: 16))
                        ShareLink(item: code.url, subject: Text("Join \(circle.name) on Scout"),
                                  message: Text("Install Scout, then open this link or paste it in Join a circle.")) {
                            Label("Share invitation", systemImage: "square.and.arrow.up")
                        }.buttonStyle(AtlasPrimaryButtonStyle()).disabled(isBusy)
                        Button("Copy code") { UIPasteboard.general.string = code.value }
                            .foregroundStyle(Atlas.burnt).frame(minHeight: 44).disabled(isBusy)
                    } else {
                        Text(invitation?.isActive == true ? "An invitation is already active. Create a replacement to share a new link." : "No active invitation.")
                            .font(Atlas.Font.sans(14)).foregroundStyle(Atlas.ink2)
                    }
                    if let expiry = invitation?.expiresAt, invitation?.isActive == true {
                        Text("Expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
                            .font(Atlas.Font.sans(12)).foregroundStyle(Atlas.ink3)
                    }
                    Text("Invitations last seven days. Replacing or revoking a link stops future joins; people who already joined stay in the circle.")
                        .font(Atlas.Font.sans(13)).foregroundStyle(Atlas.ink2)
                    if let error { Text(error).font(Atlas.Font.sans(13)).foregroundStyle(Atlas.burnt) }
                    if isBusy { ProgressView().tint(Atlas.burnt) }
                    Button(invitation?.isActive == true ? "Replace invitation" : "Create invitation") {
                        Task { await update("create") }
                    }.buttonStyle(AtlasPrimaryButtonStyle(fill: Atlas.ink))
                        .disabled(isBusy || invitation == nil)
                    if invitation?.isActive == true {
                        Button("Revoke invitation", role: .destructive) { Task { await update("revoke") } }
                            .disabled(isBusy).frame(minHeight: 44)
                    }
                    Button("Refresh") { Task { await refresh() } }.foregroundStyle(Atlas.burnt).disabled(isBusy).frame(minHeight: 44)
                }.padding(Atlas.screenHPad)
            }
            .background(Atlas.paper.ignoresSafeArea())
            .navigationTitle("Invite to circle").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }.task { await refresh() }
    }

    private func refresh() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let current = try await appState.supabase.circleInvitation(action: "status", circleId: circle.id)
            guard !Task.isCancelled else { return }
            if current.id != invitation?.id { code = nil }
            invitation = current
            error = nil
        } catch { self.error = "Couldn't load this invitation. Check your connection and refresh." }
    }

    private func update(_ action: String) async {
        guard !isBusy else { return }
        isBusy = true
        error = nil
        defer { isBusy = false }
        do {
            let current = try await appState.supabase.circleInvitation(action: action, circleId: circle.id, inviteId: invitation?.id)
            guard !Task.isCancelled else { return }
            invitation = current
            code = current.code.flatMap(CircleInviteCode.init)
        } catch {
            code = nil
            self.error = "Couldn't update this invitation. It may have changed on another device. Refresh and try again."
        }
    }
}
