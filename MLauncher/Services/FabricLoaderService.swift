import Foundation

enum FabricSetupError: LocalizedError {
    case loaderInfoNotFound
    case appSupportDirectoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .loaderInfoNotFound:
            return "error.fabric.loader.info.missing".localized()
        case .appSupportDirectoryNotFound:
            return "error.app.support.missing".localized()
        }
    }
}

class FabricLoaderService {
//    static func fetchLoaders(for minecraftVersion: String) async throws -> [FabricLoaderResponse] {
//        let url = URLConfig.API.Fabric.loader.appendingPathComponent(minecraftVersion)
//        let (data, response) = try await URLSession.shared.data(from: url)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw URLError(.badServerResponse)
//        }
//        let decoder = JSONDecoder()
//        return try decoder.decode([FabricLoaderResponse].self, from: data)
//    }
//    /// 获取最新的稳定版Loader版本号
//    static func fetchLatestStableLoaderVersion(for minecraftVersion: String) async throws -> FabricLoaderResponse? {
//        let loaders = try await fetchLoaders(for: minecraftVersion)
//        return loaders.first(where: { $0.loader.stable })
//    }
    /// 直接操作 JSON 获取最新的稳定版 Loader 版本
    static func fetchLatestStableLoaderVersion(for minecraftVersion: String) async throws -> FabricLoader? {
        let url = URLConfig.API.Fabric.loader.appendingPathComponent(minecraftVersion)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // 直接解析 JSON，查找 stable == true 的第一个 loader
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                if let loader = item["loader"] as? [String: Any],
                   let stable = loader["stable"] as? Bool, stable {
                    // 用 JSONDecoder 解析为 FabricLoaderResponse
                    let singleData = try JSONSerialization.data(withJSONObject: item)
                    let decoder = JSONDecoder()
                    return try decoder.decode(FabricLoader.self, from: singleData)
                }
            }
        }
        return nil
    }
    /// 将 Maven 坐标转换为 FabricMC Maven 仓库的 URL
    static func mavenCoordinateToURL(_ coordinate: String) -> URL? {
        // 例: net.fabricmc:fabric-loader:0.16.14
        let parts = coordinate.split(separator: ":")
        guard parts.count == 3 else { return nil }
        let group = parts[0].replacingOccurrences(of: ".", with: "/")
        let artifact = parts[1]
        let version = parts[2]
        let path = "\(group)/\(artifact)/\(version)/\(artifact)-\(version).jar"
        
        let url = URLConfig.API.Fabric.maven.appendingPathComponent(path)
        return url
    }
    
    /// 根据 FabricLoaderResponse 生成 classpath 字符串
    /// - Parameters:
    ///   - loader: Fabric loader 响应对象
    ///   - librariesDir: 库文件根目录
    /// - Returns: 拼接好的 classpath 字符串
    static func generateClasspath(from loader: FabricLoader, librariesDir: URL) -> String {
        var mavenCoords: [String] = []

        // 1. 添加 loader 和 intermediary
        mavenCoords.append(loader.loader.maven)
        mavenCoords.append(loader.intermediary.maven)

        // 2. 添加所有依赖库
        let libs = loader.launcherMeta.libraries
        mavenCoords.append(contentsOf: libs.common.map { $0.name })
        mavenCoords.append(contentsOf: libs.client.map { $0.name })
        // server 和 development 库通常在客户端启动时不需要，故不添加

        // 3. 将 Maven 坐标转换为本地文件路径
        let jarPaths = mavenCoords.compactMap { coordinate -> String? in
            let parts = coordinate.split(separator: ":")
            guard parts.count == 3 else { return nil }
            let group = parts[0].replacingOccurrences(of: ".", with: "/")
            let artifact = parts[1]
            let version = parts[2]
            let path = "\(group)/\(artifact)/\(version)/\(artifact)-\(version).jar"
            return librariesDir.appendingPathComponent(path).path
        }
        
        // 4. 拼接成 classpath 字符串
        return jarPaths.joined(separator: ":")
    }
    
    /// 封装完整的 Fabric 设置流程：获取版本信息、下载、生成 Classpath
    /// - Parameters:
    ///   - gameVersion: Minecraft 游戏版本
    ///   - onProgressUpdate: 下载进度回调
    /// - Returns: 包含 loader 版本号和 classpath 的元组
    static func setupFabric(
        for gameVersion: String,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String) {
        // 1. 获取最新的稳定版 Loader 信息
        guard let loader = try await fetchLatestStableLoaderVersion(for: gameVersion) else {
            throw FabricSetupError.loaderInfoNotFound
        }

        // 2. 收集所有需要下载的 jar 的 URL
        var mavenCoords: [String] = []
        mavenCoords.append(loader.loader.maven)
        mavenCoords.append(loader.intermediary.maven)
        let libs = loader.launcherMeta.libraries
        mavenCoords.append(contentsOf: libs.common.map { $0.name })
        mavenCoords.append(contentsOf: libs.client.map { $0.name })
        let jarUrls = mavenCoords.compactMap { mavenCoordinateToURL($0) }
        
        // 3. 下载所有 Jar 文件
        guard let librariesDirectory = AppPaths.librariesDirectory else {
            throw FabricSetupError.appSupportDirectoryNotFound
        }
        
        let fabricManager = FabricFileManager(librariesDir: librariesDirectory)
        fabricManager.onProgressUpdate = onProgressUpdate
        try await fabricManager.downloadFabricJars(urls: jarUrls)

        // 4. 生成 Classpath
        let classpathString = generateClasspath(from: loader, librariesDir: librariesDirectory)
        let mainClass = loader.launcherMeta.mainClass.client
        return (loaderVersion: loader.loader.version, classpath: classpathString, mainClass: mainClass)
    }
} 
