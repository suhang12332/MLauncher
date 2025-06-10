//  MLauncherApp.swift
//  MLauncher
//
//  Created by su on 2025/5/30.
//

import SwiftUI

@main
struct MLauncherApp: App {
    // Instantiate PlayerListViewModel and make it available in the environment
    @StateObject private var playerListViewModel = PlayerListViewModel()
    @StateObject private var gameRepository = GameRepository()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(playerListViewModel).environmentObject(gameRepository)
            // Inject the view model into the environment
        }.windowStyle(.titleBar)
            .windowToolbarStyle(.unified(showsTitle: false))
            .windowResizability(.contentMinSize)
        
        Settings {
            SettingsView()
        }
    }
}
