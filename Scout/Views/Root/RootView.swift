import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: TabItem = .list
    @State private var wishlistNavigationID = UUID()
    @State private var journalNavigationID = UUID()

    private enum IncomingSheet: Identifiable {
        case restaurant(SharedRestaurantImport), invitation(CircleInviteCode)
        var id: UUID {
            switch self {
            case .restaurant(let payload): payload.id
            case .invitation(let code): code.id
            }
        }
    }
    private var incomingSheet: IncomingSheet? {
        guard appState.isAuthenticated, !appState.isPasswordRecovery else { return nil }
        if let payload = appState.pendingSharedImport { return .restaurant(payload) }
        if let code = appState.pendingCircleInvite { return .invitation(code) }
        return nil
    }

    var body: some View {
        Group {
            if appState.isLoadingAuth {
                splashView
            } else if !appState.isAuthenticated {
                SignInView()
            } else {
                mainView
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: appState.isLoadingAuth)
        .onChange(of: appState.requestedTab, initial: true) { _, tab in
            if let tab {
                selectedTab = tab
                if tab == .list { wishlistNavigationID = UUID() }
                if tab == .journal { journalNavigationID = UUID() }
                appState.requestedTab = nil
            }
        }
        .onAppear {
            appState.loadPendingSharedImport()
        }
        .sheet(item: Binding(get: { incomingSheet }, set: { value in
            if value == nil {
                switch incomingSheet {
                case .restaurant: appState.clearPendingSharedImport()
                case .invitation: appState.pendingCircleInvite = nil
                case nil: break
                }
            }
        })) { sheet in
            switch sheet {
            case .restaurant(let payload):
                ImportReviewView(pendingImport: payload)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            case .invitation(let code):
                JoinCircleSheet(initialCode: code)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
        .alert("Invalid invitation", isPresented: Binding(get: { appState.invitationLinkError }, set: { appState.invitationLinkError = $0 })) {
            Button("OK", role: .cancel) {}
        } message: { Text("Ask for a new Scout invitation link, or paste the code in Join a circle.") }
        .fullScreenCover(isPresented: Binding(
            get: { appState.isPasswordRecovery },
            set: { appState.isPasswordRecovery = $0 }
        )) {
            ResetPasswordView()
                .interactiveDismissDisabled()
        }
        .alert("Password reset failed", isPresented: Binding(
            get: { appState.passwordRecoveryError != nil },
            set: { isPresented in
                if !isPresented { appState.passwordRecoveryError = nil }
            }
        )) {
            Button("OK", role: .cancel) {
                appState.passwordRecoveryError = nil
            }
        } message: {
            Text(appState.passwordRecoveryError ?? "Request a new reset link and try again.")
        }
    }

    // MARK: - Main tabbed content

    private var mainView: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .ignoresSafeArea(edges: .bottom)

            CustomTabBar(selected: $selectedTab)
                .padding(.bottom, Atlas.tabBarBottomOffset)

            #if DEBUG
            debugImportButton
                .padding(.trailing, Atlas.screenHPad)
                .padding(.bottom, Atlas.tabBarBottomOffset + Atlas.tabBarHeight + 12)
            #endif
        }
        .ignoresSafeArea(edges: .bottom)
    }

    #if DEBUG
    private var debugImportButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    appState.loadDebugTikTokImport()
                } label: {
                    Label("Test Import", systemImage: "music.note")
                        .font(Atlas.Font.sans(12, weight: .semibold))
                        .foregroundColor(Atlas.paper)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Atlas.ink, in: Capsule())
                        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .allowsHitTesting(true)
    }
    #endif

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .list:    WishlistView().id(wishlistNavigationID)
        case .map:     MapView()
        case .pick:    PickerView()
        case .journal: JournalIndexView { selectedTab = .list }.id(journalNavigationID)
        }
    }

    // MARK: - Splash / loading

    private var splashView: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()
            VStack(spacing: 16) {
                ScoutBrandMark(size: 48)
                Text("Scout")
                    .font(Atlas.Font.serif(20))
                    .foregroundColor(Atlas.ink2)
            }
        }
    }
}

// MARK: - Placeholder tab views for Phase 2 screens

struct PlaceholderTabView: View {
    let tab: String
    let icon: String
    let phase: String

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Atlas.ink3)
                Text(tab)
                    .font(Atlas.Font.serif(20))
                    .foregroundColor(Atlas.ink2)
                Text("Coming in \(phase)")
                    .font(Atlas.Font.sans(12))
                    .foregroundColor(Atlas.ink3)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState.preview)
}
