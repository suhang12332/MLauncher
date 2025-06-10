import SwiftUI

struct GameInfoContentView: View {
    let game: GameVersionInfo?
    
    var body: some View {
        if let gameInfo = game {
            VStack {
                Text("game.content.title".localized())
                    .font(.title)
                
                // 这里添加游戏详情内容
                Text("Game ID: \(gameInfo.gameName)")
                    .padding()
                
                // 可以添加更多游戏相关的信息
                // 例如：版本信息、启动按钮、设置等
            }
            .padding()
        }
    }
}

