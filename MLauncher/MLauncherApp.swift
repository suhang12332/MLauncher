//
//  MLauncherApp.swift
//  MLauncher
//
//  Created by su on 2025/5/30.
//

import SwiftUI

@main
struct MLauncherApp: App {
    /// 当前语言
    @AppStorage("appLanguage") private var language = "en"
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.locale, Locale(identifier: language))
        }.windowStyle(.automatic)
    }
}
