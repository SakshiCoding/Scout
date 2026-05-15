//
//  ScoutApp.swift
//  Scout
//
//  Created by Sakshi Sangani on 5/12/26.
//

import SwiftUI

@main
struct ScoutApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
