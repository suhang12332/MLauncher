import Foundation
import SwiftUI

/// 语言管理器
/// 用于管理应用的语言设置和切换
public class LanguageManager: ObservableObject {
    /// 单例实例
    public static let shared = LanguageManager()
    
    /// 当前选中的语言
    @AppStorage("selectedLanguage") public var selectedLanguage: String = Locale.preferredLanguages.first ?? "zh-Hans" {
        didSet {
            objectWillChange.send()
        }
    }
    
    /// Minecraft 版本资源文件地址
    @AppStorage("minecraftVersionManifestURL") public var minecraftVersionManifestURL: String = "https://launchermeta.mojang.com/mc/game/version_manifest.json"
    
    /// Modrinth API 基础地址
    @AppStorage("modrinthAPIBaseURL") public var modrinthAPIBaseURL: String = "https://api.modrinth.com/v2"
    
    /// 默认 Java 路径
    @AppStorage("defaultJavaPath") public var defaultJavaPath: String = "/usr/bin/java"
    
    /// 默认内存分配 (MB)
    @AppStorage("defaultMemoryAllocation") public var defaultMemoryAllocation: Int = 512
    
    /// 下载资源的并发数
    @AppStorage("concurrentDownloads") public var concurrentDownloads: Int = 4
    
    /// 支持的语言列表
    public let languages: [(String, String)] = [
        ("简体中文", "zh-Hans"),
        ("繁體中文", "zh-Hant"),
        ("English", "en"),
    ]
    
    /// 获取当前语言的 Bundle
    public var bundle: Bundle {
        if let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
    
    private init() {}
}

// MARK: - String Localization Extension

public extension String {
    /// 获取本地化字符串
    /// - Parameter bundle: 语言包，默认使用当前语言
    /// - Returns: 本地化后的字符串
    func localized(_ bundle: Bundle = LanguageManager.shared.bundle) -> String {
        NSLocalizedString(self, bundle: bundle, comment: "")
    }
} 