import Foundation

class DownloadManager {
    enum ResourceType: String {
        case mod, datapack, shader, resourcepack
        
        var folderName: String {
            switch self {
            case .mod: return "mods"
            case .datapack: return "datapacks"
            case .shader: return "shaderpacks"
            case .resourcepack: return "resourcepacks"
            }
        }
        
        init?(from string: String) {
            switch string.lowercased() {
            case "mod": self = .mod
            case "datapack": self = .datapack
            case "shader": self = .shader
            case "resourcepack": self = .resourcepack
            default: return nil
            }
        }
    }
    /// 下载资源文件
    /// - Parameters:
    ///   - game: 游戏信息
    ///   - urlString: 下载地址
    ///   - resourceType: 资源类型（如 "mod", "datapack", "shader", "resourcepack"）
    /// - Returns: 下载到的本地文件 URL
    static func downloadResource(for game: GameVersionInfo, urlString: String, resourceType: String) async throws -> URL {
        Logger.shared.info("下载\(resourceType) \(urlString)")
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        guard let type = ResourceType(from: resourceType) else {
            throw NSError(domain: "DownloadManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "未知资源类型"])
        }
        let fileManager = FileManager.default
        let resourceDir: URL? = {
            switch type {
            case .mod: return AppPaths.modsDirectory(gameName: game.gameName)
            case .datapack: return AppPaths.datapacksDirectory(gameName: game.gameName)
            case .shader: return AppPaths.shaderpacksDirectory(gameName: game.gameName)
            case .resourcepack: return AppPaths.resourcepacksDirectory(gameName: game.gameName)
            }
        }()
        guard let resourceDirUnwrapped = resourceDir else {
            throw NSError(domain: "DownloadManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "资源目录获取失败"])
        }
        try fileManager.createDirectory(at: resourceDirUnwrapped, withIntermediateDirectories: true)
        let destURL = resourceDirUnwrapped.appendingPathComponent(url.lastPathComponent)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        try data.write(to: destURL)
        return destURL
    }
} 
