import Foundation
import SwiftUI

/// 主题模式
public enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var localizedName: String {
        "settings.theme.\(rawValue)".localized()
    }
}

/// 主题管理器
/// 用于管理应用的主题设置和切换
public class ThemeManager: ObservableObject {
    /// 单例实例
    public static let shared = ThemeManager()
    
    /// 主题模式
    @AppStorage("themeMode") public var themeMode: ThemeMode = .system {
        didSet {
            objectWillChange.send()
        }
    }
    
    /// 获取当前主题的 ColorScheme
    public var colorScheme: ColorScheme? {
        switch themeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    private init() {}
} 