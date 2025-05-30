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