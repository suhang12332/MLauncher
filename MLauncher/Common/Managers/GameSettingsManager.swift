import Foundation
import SwiftUI

class GameSettingsManager: ObservableObject {
    static let shared = GameSettingsManager()
    
    @AppStorage("defaultJavaPath") public var defaultJavaPath: String = "/usr/bin/java" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("defaultMemoryAllocation") public var defaultMemoryAllocation: Int = 512 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("concurrentDownloads") public var concurrentDownloads: Int = 4 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("autoDownloadDependencies") public var autoDownloadDependencies: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("minecraftVersionManifestURL") public var minecraftVersionManifestURL: String = "https://launchermeta.mojang.com/mc/game/version_manifest.json" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("modrinthAPIBaseURL") public var modrinthAPIBaseURL: String = "https://api.modrinth.com/v2" {
        didSet { objectWillChange.send() }
    }
    private init() {}
}
