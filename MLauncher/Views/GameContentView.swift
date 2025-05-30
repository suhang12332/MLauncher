import SwiftUI

struct GameContentView: View {
    let gameId: String
    
    var body: some View {
        VStack {
            Text(NSLocalizedString("game.content.title", comment: "游戏内容标题"))
                .font(.title)
            
            // 这里添加游戏详情内容
            Text("Game ID: \(gameId)")
                .padding()
            
            // 可以添加更多游戏相关的信息
            // 例如：版本信息、启动按钮、设置等
        }
        .padding()
    }
}

#Preview {
    GameContentView(gameId: "minecraft")
} 