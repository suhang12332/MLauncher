import SwiftUI

struct ResourceContentView: View {
    let resourceType: ResourceType
    
    var body: some View {
        VStack {
            Text(resourceType.localizedName)
                .font(.title)
            
            // 根据资源类型显示不同的内容
            switch resourceType {
            case .mod:
                ModListView()
            case .datapack:
                DataPackListView()
            case .shader:
                ShaderListView()
            case .resourcepack:
                ResourcePackListView()
            case .modpack:
                ModpackListView()
            }
        }
        .padding()
    }
}

// 各种资源列表视图
struct ModListView: View {
    var body: some View {
        Text(NSLocalizedString("resource.mod.list", comment: "模组列表"))
    }
}

struct DataPackListView: View {
    var body: some View {
        Text(NSLocalizedString("resource.datapack.list", comment: "数据包列表"))
    }
}

struct ShaderListView: View {
    var body: some View {
        Text(NSLocalizedString("resource.shader.list", comment: "光影列表"))
    }
}

struct ResourcePackListView: View {
    var body: some View {
        Text(NSLocalizedString("resource.resourcepack.list", comment: "资源包列表"))
    }
}

struct ModpackListView: View {
    var body: some View {
        Text(NSLocalizedString("resource.modpack.list", comment: "整合包列表"))
    }
}

#Preview {
    ResourceContentView(resourceType: .mod)
} 