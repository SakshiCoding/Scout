import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: TabItem = .list

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
        .onAppear {
            appState.loadPendingSharedImport()
        }
        .sheet(
            isPresented: Binding(
                get: { appState.isAuthenticated && appState.pendingSharedImport != nil },
                set: { isPresented in
                    if !isPresented {
                        appState.clearPendingSharedImport()
                    }
                }
            )
        ) {
            if let pendingImport = appState.pendingSharedImport {
                ImportReviewView(pendingImport: pendingImport)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(Atlas.sheetTopRadius)
            }
        }
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
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .list:    WishlistView()
        case .map:     MapView()
        case .pick:    PickerView()
        case .journal: JournalIndexView { selectedTab = .list }
        }
    }

    // MARK: - Splash / loading

    private var splashView: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()
            VStack(spacing: 16) {
                // Compass-inspired mark
                ZStack {
                    Circle()
                        .stroke(Atlas.burnt.opacity(0.2), lineWidth: 1)
                        .frame(width: 48, height: 48)
                    Text("S")
                        .font(Atlas.Font.serif(28))
                        .foregroundColor(Atlas.burnt)
                }
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
