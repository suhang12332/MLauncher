import Foundation

struct MinecraftLaunchCommandBuilder {
    static func build(
        manifest: MinecraftVersionManifest,
        gameInfo: GameVersionInfo,
        username: String,
        uuid: String,
        launcherBrand: String,
        launcherVersion: String
    ) -> String {
        // 1. 路径常量
        guard let nativesDir = AppPaths.nativesDirectory?.path,
              let librariesDir = AppPaths.librariesDirectory,
              let assetsDir = AppPaths.assetsDirectory?.path,
              let gameDir = AppPaths.profileDirectory(gameName: gameInfo.gameName)?.path,
              let versionsDir = AppPaths.versionsDirectory else {
            fatalError("AppPaths 路径获取失败")
        }
        let quotedNativesDir = "\"\(nativesDir)\""
        let quotedAssetsDir = "\"\(assetsDir)\""
        let quotedGameDir = "\"\(gameDir)\""
        let clientJarPath = versionsDir.appendingPathComponent(manifest.id).appendingPathComponent("\(manifest.id).jar").path

        // 2. 生成 Classpath，modJvm 优先生效，按 group/artifact 去重
        let libraryPaths = manifest.libraries
            .filter { libraryIsApplicable($0.rules) }
            .compactMap { $0.downloads?.artifact.map { librariesDir.appendingPathComponent($0.path).path } }
        let modJvmJars = gameInfo.modJvm
            .split(separator: ":")
            .map { String($0) }
            .filter { !$0.isEmpty }
        let allJarPaths = [clientJarPath] + libraryPaths
        let classpathJars = allJarPaths
        func extractGroupArtifact(from path: String) -> String? {
            // 例: .../org/ow2/asm/asm/9.8/asm-9.8.jar
            // groupArtifact = org/ow2/asm/asm
            let parts = path.split(separator: "/")
            guard parts.count >= 4 else { return nil }
            // 倒数第3个是 artifact，倒数第4个及之前是 group
            let artifact = parts[parts.count - 3]
            let group = parts[0..<(parts.count - 3)].joined(separator: "/")
            return "\(group)/\(artifact)"
        }
        var seenKeys = Set<String>()
        var finalJars: [String] = []
        for jar in modJvmJars {
            if let key = extractGroupArtifact(from: jar) {
                seenKeys.insert(key)
            }
            finalJars.append(jar)
        }
        for jar in classpathJars {
            if let key = extractGroupArtifact(from: jar), !seenKeys.contains(key) {
                finalJars.append(jar)
            }
        }
        let classpathString = finalJars.map { "\"\($0)\"" }.joined(separator: ":")

        // 3. JVM 参数
        let jvmArgs: [String] = [
            "-Djava.library.path=\(quotedNativesDir)",
            "-Djna.tmpdir=\(quotedNativesDir)",
            "-Dorg.lwjgl.system.SharedLibraryExtractPath=\(quotedNativesDir)",
            "-Dio.netty.native.workdir=\(quotedNativesDir)",
            "-Dminecraft.launcher.brand=\(launcherBrand)",
            "-Dminecraft.launcher.version=\(launcherVersion)",
            "-Xmx\(gameInfo.runningMemorySize)M",
            "-Xms\(gameInfo.runningMemorySize)M",
            "-XstartOnFirstThread",
            "-cp", classpathString
        ]

        // 4. Minecraft 启动参数
        let mcArgs: [String] = [
            gameInfo.mainClass,
            "--username", username,
            "--version", gameInfo.gameVersion,
            "--gameDir", quotedGameDir,
            "--assetsDir", quotedAssetsDir,
            "--assetIndex", gameInfo.assetIndex,
            "--uuid", uuid,
            "--accessToken",
            "--clientId",
            "--xuid",
            "--userType", "msa",
            "--versionType", "release"
        ]

        // 5. 拼接最终命令
        return (jvmArgs + mcArgs).joined(separator: " ")
    }

    /// 判断库是否适用当前平台
    private static func libraryIsApplicable(_ rules: [Rule]?) -> Bool {
        guard let rules = rules else { return true }
        var finalAction = "allow"
        for rule in rules {
            let applies: Bool = {
                guard let osRule = rule.os else { return true }
                #if os(macOS)
                return osRule.name == nil || osRule.name == "osx"
                #elseif os(Linux)
                return osRule.name == nil || osRule.name == "linux"
                #elseif os(Windows)
                return osRule.name == nil || osRule.name == "windows"
                #else
                return false
                #endif
            }()
            if applies {
                finalAction = rule.action
            }
        }
        return finalAction == "allow"
    }
} 
