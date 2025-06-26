import Foundation

struct AppPaths {
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? AppConstants.appName
    }
    static var launcherSupportDirectory: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent(appName)
    }
    static var metaDirectory: URL? {
        launcherSupportDirectory?.appendingPathComponent("meta")
    }
    static var librariesDirectory: URL? {
        metaDirectory?.appendingPathComponent("libraries")
    }
    static var nativesDirectory: URL? {
        metaDirectory?.appendingPathComponent("natives")
    }
    static var assetsDirectory: URL? {
        metaDirectory?.appendingPathComponent("assets")
    }
    static var versionsDirectory: URL? {
        metaDirectory?.appendingPathComponent("versions")
    }
    static func profileDirectory(gameName: String) -> URL? {
        launcherSupportDirectory?.appendingPathComponent("profiles").appendingPathComponent(gameName)
    }
    static func modsDirectory(gameName: String) -> URL? {
        profileDirectory(gameName: gameName)?.appendingPathComponent("mods")
    }
    static func datapacksDirectory(gameName: String) -> URL? {
        profileDirectory(gameName: gameName)?.appendingPathComponent("datapacks")
    }
    static func shaderpacksDirectory(gameName: String) -> URL? {
        profileDirectory(gameName: gameName)?.appendingPathComponent("shaderpacks")
    }
    static func resourcepacksDirectory(gameName: String) -> URL? {
        profileDirectory(gameName: gameName)?.appendingPathComponent("resourcepacks")
    }
} 
