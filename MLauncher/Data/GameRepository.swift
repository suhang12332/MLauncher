import Combine
import Foundation

/// 游戏版本信息仓库
/// 负责游戏版本信息的持久化存储和管理
class GameRepository: ObservableObject {
    // MARK: - Properties

    /// 已保存的游戏列表
    @Published private(set) var games: [GameVersionInfo] = []

    /// UserDefaults 存储键
    private let gamesKey = "savedGames"

    // MARK: - Initialization

    init() {
        loadGames()
    }

    // MARK: - Public Methods

    /// 添加新游戏
    /// - Parameter game: 要添加的游戏版本信息
    func addGame(_ game: GameVersionInfo) {
        games.append(game)
        saveGames()
    }

    /// 删除游戏
    /// - Parameter id: 要删除的游戏ID
    func deleteGame(id: String) {
        games.removeAll { $0.id == id }
        saveGames()
    }

    /// 根据游戏ID查找游戏版本信息
    /// - Parameter id: 游戏ID
    /// - Returns: 匹配的 GameVersionInfo 对象，如果找不到则返回 nil
    func getGame(by id: String) -> GameVersionInfo? {
        return games.first { $0.id == id }
    }

    /// 根据 ID 更新游戏信息
    /// - Parameter game: 新的游戏信息
    /// - Returns: 是否更新成功
    func updateGame(_ game: GameVersionInfo) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else {
            Logger.shared.warning("找不到要更新的游戏：\(game.id)")
            return false
        }
        
        games[index] = game
        saveGames()
        return true
    }
    
    /// 根据 ID 更新游戏状态
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - isRunning: 是否正在运行
    ///   - lastPlayed: 最后游玩时间
    /// - Returns: 是否更新成功
    func updateGameStatus(id: String, isRunning: Bool, lastPlayed: Date = Date()) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要更新状态的游戏：\(id)")
            return false
        }
        
        var game = games[index]
        game.isRunning = isRunning
        game.lastPlayed = lastPlayed
        games[index] = game
        saveGames()
        return true
    }

    /// 更新 Java 路径
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - javaPath: 新的 Java 路径
    /// - Returns: 是否更新成功
    func updateJavaPath(id: String, javaPath: String) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要更新 Java 路径的游戏：\(id)")
            return false
        }
        
        var game = games[index]
        game.javaPath = javaPath
        games[index] = game
        saveGames()
        return true
    }
    
    /// 更新 JVM 启动参数
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - jvmArguments: 新的 JVM 参数
    /// - Returns: 是否更新成功
    func updateJvmArguments(id: String, jvmArguments: String) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要更新 JVM 参数的游戏：\(id)")
            return false
        }
        
        var game = games[index]
        game.jvmArguments = jvmArguments
        games[index] = game
        saveGames()
        return true
    }
    
    /// 更新运行内存大小
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - memorySize: 新的内存大小（MB）
    /// - Returns: 是否更新成功
    func updateMemorySize(id: String, memorySize: Int) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要更新内存大小的游戏：\(id)")
            return false
        }
        
        var game = games[index]
        game.runningMemorySize = memorySize
        games[index] = game
        saveGames()
        return true
    }
    
    /// 更新游戏资源列表
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - resources: 新的资源列表
    /// - Returns: 是否更新成功
    func updateResources(id: String, resources: [ModrinthProjectDetail]) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要更新资源列表的游戏：\(id)")
            return false
        }
        var game = games[index]
        game.resources = resources
        games[index] = game
        saveGames()
        return true
    }
    
    /// 添加单个游戏资源
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - resource: 要添加的资源
    /// - Returns: 是否添加成功
    func addResource(id: String, resource: ModrinthProjectDetail) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要添加资源的游戏：\(id)")
            return false
        }
        var game = games[index]
        if !game.resources.contains(where: { $0.id == resource.id }) {
            game.resources.append(resource)
            games[index] = game
            saveGames()
            return true
        }
        return false
    }
    
    /// 移除单个游戏资源
    /// - Parameters:
    ///   - id: 游戏 ID
    ///   - projectId: 要移除的资源 projectId
    /// - Returns: 是否移除成功
    func removeResource(id: String, projectId: String) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            Logger.shared.warning("找不到要移除资源的游戏：\(id)")
            return false
        }
        var game = games[index]
        if let resourceIndex = game.resources.firstIndex(where: { $0.id == projectId }) {
            let resource = game.resources[resourceIndex]
            // 删除本地文件
            ResourceFileManager.deleteResourceFile(for: game, resource: resource)
            // 移除元数据
            game.resources.remove(at: resourceIndex)
            games[index] = game
            saveGames()
            return true
        }
        return false
    }

    // MARK: - Private Methods

    /// 从 UserDefaults 加载游戏列表
    private func loadGames() {
        guard let savedGamesData = UserDefaults.standard.data(forKey: gamesKey)
        else {
            games = []
            return
        }

        do {
            let decoder = JSONDecoder()
            games = try decoder.decode(
                [GameVersionInfo].self,
                from: savedGamesData
            )
        } catch {
            Logger.shared.error(
                "加载游戏列表失败：\(error.localizedDescription)"
            )
            games = []
        }
    }

    /// 保存游戏列表到 UserDefaults
    private func saveGames() {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(games)
            UserDefaults.standard.set(encodedData, forKey: gamesKey)
        } catch {
            Logger.shared.error(
                "保存游戏列表失败：\(error.localizedDescription)"
            )
        }
    }
}
