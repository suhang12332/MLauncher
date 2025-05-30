//
//  ContentView.swift
//  MLauncher
//
//  Created by su on 2025/5/30.
//

import SwiftUI

struct ContentView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var selectedItem: SidebarItem?
    @State private var games: [String] = [] // 这里应该从数据源获取游戏列表
    @ObservedObject private var lang = LanguageManager.shared
    
    /// 支持的语言列表
    private let languages = [
        ("简体中文", "zh-Hans"),
        ("繁體中文", "zh-Hant"),
        ("English", "en")
    ]
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            SidebarView(selectedItem: $selectedItem, games: games)
        } content: {
            // 内容区
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .game(let gameId):
                    GameContentView(gameId: gameId)
                case .resource(let type):
                    ResourceContentView(resourceType: type)
                }
            } else {
                Text("sidebar.select_item".localized())
                    .foregroundColor(.secondary)
            }
        } detail: {
            // 详情区
            Text("detail.select_item".localized())
                .navigationTitle("detail.title".localized())
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Picker("", selection: $lang.selectedLanguage) {
                            ForEach(languages, id: \.1) { name, code in
                                Text(name).tag(code)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            // 编辑详情
                        }) {
                            Image(systemName: "pencil")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            // 分享详情
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            // 收藏详情
                        }) {
                            Image(systemName: "star")
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
