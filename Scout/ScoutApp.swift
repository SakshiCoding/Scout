//
//  ScoutApp.swift
//  Scout
//
//  Created by Sakshi Sangani on 5/12/26.
//

import SwiftUI
import AppIntents

@main
struct ScoutApp: App {
    @State private var appState: AppState

    init() {
        let state = AppState()
        _appState = State(initialValue: state)
        AppDependencyManager.shared.add(dependency: state)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .onOpenURL { url in
                    appState.handleOpenURL(url)
                }
        }
    }
}
