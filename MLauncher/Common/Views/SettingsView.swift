import SwiftUI
import Foundation

/// 通用设置视图
/// 用于显示应用程序的设置选项
public struct SettingsView: View {
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    /// 计算最大允许的内存分配 (MB)
    private var maximumMemoryAllocation: Int {
        let physicalMemoryBytes = ProcessInfo.processInfo.physicalMemory
        let physicalMemoryMB = physicalMemoryBytes / 1048576 // 将字节转换为 MB
        // 计算总内存的 70%，并确保至少为 512MB
        let calculatedMax = Int(Double(physicalMemoryMB) * 0.7)
        // 确保最大值也是 512 的倍数
        let roundedMax = (calculatedMax / 512) * 512
        return max(roundedMax, 512)
    }
    
    public init() {}
    
    public var body: some View {
        TabView {
            // 通用设置标签页
            Form {
                Section(header: Text("settings.general.title".localized())) {
                    HStack {
                        Text("settings.language.picker".localized())
                        Spacer()
                        Picker("", selection: $lang.selectedLanguage) {
                            ForEach(lang.languages, id: \.1) { name, code in
                                Text(name).tag(code)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("settings.theme.picker".localized())
                        Spacer()
                        Picker("", selection: $theme.themeMode) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Text(mode.localizedName).tag(mode)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("settings.minecraft_versions_url.label".localized())
                        Spacer()
                         TextField("settings.minecraft_versions_url.placeholder".localized(), text: $lang.minecraftVersionManifestURL)
                            .frame(minWidth: 200) // Give text field some width
                    }
                    
                    HStack {
                        Text("settings.modrinth_api_url.label".localized())
                        Spacer()
                         TextField("settings.modrinth_api_url.placeholder".localized(), text: $lang.modrinthAPIBaseURL)
                             .frame(minWidth: 200) // Give text field some width
                    }
                }
            }
            .padding()
            .tabItem {
                Label("settings.general.tab".localized(), systemImage: "gearshape")
            }
            
            // 玩家设置标签页
            Form {
                Section(header: Text("settings.player.title".localized())) {
                    Text("settings.player.placeholder".localized())
                }
            }
            .padding()
            .tabItem {
                Label("settings.player.tab".localized(), systemImage: "person.crop.circle")
            }
            
            // 游戏设置标签页
            Form {
                Section(header: Text("settings.game.title".localized())) {
                    HStack {
                        Text("settings.default_java_path.label".localized())
                        Spacer()
                        TextField("settings.default_java_path.placeholder".localized(), text: $lang.defaultJavaPath)
                            .frame(minWidth: 200) // Give text field some width
                    }
                    
                    HStack(alignment: .top) {
                        Text("settings.default_memory_allocation.label".localized())
                         Spacer()
                        VStack(alignment: .leading) {
                            Text("\(lang.defaultMemoryAllocation) MB")
                            Slider(value: Binding(get: { Double(lang.defaultMemoryAllocation) }, set: { lang.defaultMemoryAllocation = Int($0 / 512) * 512 }), in: 512...Double(maximumMemoryAllocation), step: 512)
                        }
                        .frame(minWidth: 150)
                    }
                    
                     HStack(alignment: .top) {
                         Text("settings.concurrent_downloads.label".localized())
                         Spacer()
                         VStack(alignment: .leading) {
                             Text("\(lang.concurrentDownloads)")
                             Slider(value: Binding(get: { Double(lang.concurrentDownloads) }, set: { lang.concurrentDownloads = Int($0) }), in: 1...10, step: 1)
                         }
                          .frame(minWidth: 150)
                     }
                }
            }
            .padding()
            .tabItem {
                Label("settings.game.tab".localized(), systemImage: "gamecontroller")
            }
        }
        .frame(minWidth: 500, minHeight: 350)
    }
}

#Preview {
    SettingsView()
} 
