import Foundation

/// Minecraft 启动命令生成器
struct MinecraftLaunchCommand {
    let player: Player?
    let game: GameVersionInfo
    let gameRepository: GameRepository
    // MARK: - 常量
    private enum Constants {
        static let mainClass = "net.minecraft.client.main.Main"
        static let launcherBrand = "minecraft.launcher.brand"
        static let launcherVersion = "minecraft.launcher.version"
        static let javaLibraryPath = "java.library.path"
        static let jnaTmpdir = "jna.tmpdir"
        static let lwjglSystemPath = "org.lwjgl.system.SharedLibraryExtractPath"
        static let nettyWorkdir = "io.netty.native.workdir"
    }
    
    // MARK: - 系统信息
    private static var systemArchitecture: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "x86_64"
        #endif
    }
    
    // MARK: - JVM 参数生成
    private static func generateJvmArgs(
        nativesDirectory: String,
        classpath: String,
        launcherName: String,
        launcherVersion: String,
        memorySize: Int,
        customJvmArgs: String
    ) -> [String] {
        // 处理路径中的空格，使用引号而不是反斜杠
        let escapedNativesDirectory = "\"\(nativesDirectory)\""
        let escapedClasspath = "\"\(classpath)\""
        
        var args = [
            "-D\(Constants.javaLibraryPath)=\(escapedNativesDirectory)",
            "-D\(Constants.jnaTmpdir)=\(escapedNativesDirectory)",
            "-D\(Constants.lwjglSystemPath)=\(escapedNativesDirectory)",
            "-D\(Constants.nettyWorkdir)=\(escapedNativesDirectory)",
            "-D\(Constants.launcherBrand)=\(launcherName)",
            "-D\(Constants.launcherVersion)=\(launcherVersion)",
            "-Xmx\(memorySize)M",
            "-Xms\(memorySize)M",
            "-XstartOnFirstThread", // macOS 特定参数
            "-cp", escapedClasspath
        ]
        
        // 添加自定义 JVM 参数
        if !customJvmArgs.isEmpty {
            args.append(contentsOf: customJvmArgs.split(separator: " ").map(String.init))
        }
        
        return args
    }
    
    // MARK: - 游戏参数生成
    private static func generateGameArgs(
        username: String,
        versionName: String,
        gameDirectory: String,
        assetsRoot: String,
        assetsIndex: String,
        uuid: String,
        accessToken: String,
        clientId: String,
        xuid: String,
        userType: String,
        versionType: String
    ) -> [String] {
        // 处理路径中的空格，使用引号而不是反斜杠
        let escapedGameDirectory = "\"\(gameDirectory)\""
        let escapedAssetsRoot = "\"\(assetsRoot)\""
        let escapedAssetsIndex = "\"\(assetsIndex)\""
        
        return [
            "--username", username,
            "--version", versionName,
            "--gameDir", escapedGameDirectory,
            "--assetsDir", escapedAssetsRoot,
            "--assetIndex", escapedAssetsIndex,
            "--uuid", uuid,
            "--accessToken", accessToken,
            "--clientId", clientId,
            "--xuid", xuid,
            "--userType", userType,
            "--versionType", versionType
        ]
    }
    
    // MARK: - 获取所有 jar 文件
    private static func getAllJarFiles(in directory: String, version: String) -> [String] {
        let fileManager = FileManager.default
        var jarFiles: [String] = []
        
        guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: directory),
                                                    includingPropertiesForKeys: [.isRegularFileKey],
                                                    options: [.skipsHiddenFiles]) else {
            return []
        }
        
        // 首先添加 Minecraft 客户端 jar
        let metaPath = directory.replacingOccurrences(of: "/libraries", with: "")
        let clientJarPath = "\(metaPath)/versions/\(version)/\(version).jar"
        if fileManager.fileExists(atPath: clientJarPath) {
            jarFiles.append(clientJarPath)
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "jar" {
                let path = fileURL.path
                
                // 处理 natives 文件
                if path.contains("-natives-") {
                    if path.contains("-natives-macos") {
                        // 根据系统架构选择正确的 natives 文件
                        if systemArchitecture == "arm64" && path.contains("-arm64") {
                            jarFiles.append(path)
                        } else if systemArchitecture == "x86_64" && !path.contains("-arm64") {
                            jarFiles.append(path)
                        }
                    }
                } else if !path.contains("-natives-") && !path.contains("netty-transport-native-epoll") {
                    // 非 natives 文件且不是 Linux 的 netty natives 文件
                    jarFiles.append(path)
                }
            }
        }
        
        return jarFiles
    }
    
    // MARK: - 生成完整的启动命令
    static func generate(
        gameInfo: GameVersionInfo,
        nativesDirectory: String,
        classpath: String,
        gameDirectory: String,
        assetsRoot: String,
        assetsIndex: String,
        username: String,
        uuid: String,
        accessToken: String,
        clientId: String,
        xuid: String,
        userType: String,
        versionType: String,
        launcherName: String,
        launcherVersion: String
    ) -> String {
        // 获取所有 jar 文件并构建 classpath
        let jarFiles = getAllJarFiles(in: classpath, version: gameInfo.gameVersion)
        let classpathString = jarFiles.joined(separator: ":")
        
        // 处理路径中的空格
        let escapedNativesDirectory = nativesDirectory.replacingOccurrences(of: " ", with: "\\ ")
        let escapedClasspath = classpathString.replacingOccurrences(of: " ", with: "\\ ")
        let escapedGameDirectory = gameDirectory.replacingOccurrences(of: " ", with: "\\ ")
        let escapedAssetsRoot = assetsRoot.replacingOccurrences(of: " ", with: "\\ ")
        
        // 构建命令数组
        var command = [
            gameInfo.javaPath,
            "-D\(Constants.javaLibraryPath)=\(escapedNativesDirectory)",
            "-D\(Constants.jnaTmpdir)=\(escapedNativesDirectory)",
            "-D\(Constants.lwjglSystemPath)=\(escapedNativesDirectory)",
            "-D\(Constants.nettyWorkdir)=\(escapedNativesDirectory)",
            "-D\(Constants.launcherBrand)=\(launcherName)",
            "-D\(Constants.launcherVersion)=\(launcherVersion)",
            "-Xmx\(gameInfo.runningMemorySize)M",
            "-Xms\(gameInfo.runningMemorySize)M",
            "-XstartOnFirstThread",
            "-cp", escapedClasspath,
            Constants.mainClass,
            "--username", username,
            "--version", gameInfo.gameVersion,
            "--gameDir", escapedGameDirectory,
            "--assetsDir", escapedAssetsRoot,
            "--assetIndex", assetsIndex,
            "--uuid", uuid,
            "--accessToken", accessToken,
            "--clientId", clientId,
            "--xuid", xuid,
            "--userType", userType,
            "--versionType", versionType
        ]
        
        // 添加自定义 JVM 参数
        if !gameInfo.jvmArguments.isEmpty {
            command.insert(contentsOf: gameInfo.jvmArguments.split(separator: " ").map(String.init), at: 1)
        }
        
        return command.joined(separator: " ")
    }
    // MARK: - 启动游戏
    public func launchGame() async {
        do {
            // 1. 准备路径
            let paths = try preparePaths()
            
            // 2. 生成启动命令
            let command = generateLaunchCommand(paths: paths)
            
            // 3. 启动游戏进程
            try await launchGameProcess(command: command, paths: paths)
            
        } catch {
            await handleLaunchError(error)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 准备所有必要的路径
    private func preparePaths() throws -> GamePaths {
        guard let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw LaunchError.appSupportDirectoryNotFound
        }
        
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "MLauncher"
        let launcherSupportDirectory = applicationSupportDirectory.appendingPathComponent(appName)
        
        return GamePaths(
            nativesDirectory: launcherSupportDirectory.appendingPathComponent("meta").appendingPathComponent("natives").path,
            classpath: launcherSupportDirectory.appendingPathComponent("meta").appendingPathComponent("libraries").path,
            gameDirectory: launcherSupportDirectory.appendingPathComponent("profiles").appendingPathComponent(game.gameName).path,
            assetsRoot: launcherSupportDirectory.appendingPathComponent("meta").appendingPathComponent("assets").path,
            assetsIndex: game.assetIndex
        )
    }
    
    /// 生成启动命令
    private func generateLaunchCommand(paths: GamePaths) -> String {
        
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "MLauncher"
        
        let command = MinecraftLaunchCommand.generate(
            gameInfo: game,
            nativesDirectory: paths.nativesDirectory,
            classpath: paths.classpath,
            gameDirectory: paths.gameDirectory,
            assetsRoot: paths.assetsRoot,
            assetsIndex: paths.assetsIndex,
            username: player?.name ?? "",
            uuid: player?.id ?? "",
            accessToken: "", // TODO: 从用户配置中获取
            clientId: "", // TODO: 从用户配置中获取
            xuid: "", // TODO: 从用户配置中获取
            userType: "msa", // TODO: 从用户配置中获取
            versionType: "release",
            launcherName: appName,
            launcherVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        )
        
        // 记录启动信息
        logLaunchInfo(command: command, paths: paths)
        
        return command
    }
    
    /// 启动游戏进程
    private func launchGameProcess(command: String, paths: GamePaths) async throws {
        // 处理路径中的空格
        let escapedGameDirectory = paths.gameDirectory.replacingOccurrences(of: " ", with: "\\ ")
        Logger.shared.info(escapedGameDirectory)
        // 创建临时脚本文件
        let scriptContent = """
        #!/bin/bash
        /usr/bin/java \(command)
        """
        
        // 获取临时目录
        let tempDir = FileManager.default.temporaryDirectory
        Logger.shared.info(tempDir)
        let scriptURL = tempDir.appendingPathComponent("launch_\(game.id).sh")
        
        // 写入脚本内容
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        
        // 设置脚本权限
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        // 创建进程
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        
        // 更新游戏状态为运行中
        _ = gameRepository.updateGameStatus(id: game.id, isRunning: true)
        
        // 启动进程
        try process.run()
        
        // 监听进程结束
        let gameId = game.id
        process.terminationHandler = { process in
            Task { @MainActor in
                _ = self.gameRepository.updateGameStatus(id: gameId, isRunning: false)
                // 清理临时脚本文件
                try? FileManager.default.removeItem(at: scriptURL)
            }
        }
    }
    
    /// 处理启动错误
    private func handleLaunchError(_ error: Error) async {
        Logger.shared.error("启动游戏失败：\(error.localizedDescription)")
        // 更新游戏状态为未运行
        _ = gameRepository.updateGameStatus(id: game.id, isRunning: false)
        // TODO: 显示错误提示
    }
    
    /// 记录启动信息
    private func logLaunchInfo(command: String, paths: GamePaths) {
        Logger.shared.info("启动命令：")
        Logger.shared.info("Java 路径：\(game.javaPath)")
        Logger.shared.info("工作目录：\(paths.gameDirectory)")
        Logger.shared.info("完整命令：\(command)")
    }

    
}

// MARK: - 辅助类型

/// 游戏路径信息
private struct GamePaths {
    let nativesDirectory: String
    let classpath: String
    let gameDirectory: String
    let assetsRoot: String
    let assetsIndex: String
}

/// 启动错误类型
private enum LaunchError: LocalizedError {
    case appSupportDirectoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .appSupportDirectoryNotFound:
            return NSLocalizedString("error.app.support.missing", comment: "无法找到应用程序支持目录")
        }
    }
}
 
