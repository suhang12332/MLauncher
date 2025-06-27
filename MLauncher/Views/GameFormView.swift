import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

// MARK: - Download State
class DownloadState: ObservableObject {
    @Published var isDownloading = false
    @Published var coreProgress: Double = 0
    @Published var resourcesProgress: Double = 0
    @Published var currentCoreFile: String = ""
    @Published var currentResourceFile: String = ""
    @Published var coreTotalFiles: Int = 0
    @Published var resourcesTotalFiles: Int = 0
    @Published var coreCompletedFiles: Int = 0
    @Published var resourcesCompletedFiles: Int = 0
    @Published var isCancelled = false

    func reset() {
        isDownloading = false
        coreProgress = 0
        resourcesProgress = 0
        currentCoreFile = ""
        currentResourceFile = ""
        coreTotalFiles = 0
        resourcesTotalFiles = 0
        coreCompletedFiles = 0
        resourcesCompletedFiles = 0
        isCancelled = false
    }

    func startDownload(coreTotalFiles: Int, resourcesTotalFiles: Int) {
        self.coreTotalFiles = coreTotalFiles
        self.resourcesTotalFiles = resourcesTotalFiles
        self.isDownloading = true
        self.coreProgress = 0
        self.resourcesProgress = 0
        self.coreCompletedFiles = 0
        self.resourcesCompletedFiles = 0
        self.isCancelled = false
    }

    func cancel() {
        isCancelled = true
    }

    func updateProgress(
        fileName: String,
        completed: Int,
        total: Int,
        type: MinecraftFileManager.DownloadType
    ) {
        switch type {
        case .core:
            self.currentCoreFile = fileName
            self.coreCompletedFiles = completed
            self.coreTotalFiles = total
            // Clamp progress value to 0.0...1.0
            if total > 0 {
                self.coreProgress = max(
                    0.0,
                    min(1.0, Double(completed) / Double(total))
                )
            } else {
                self.coreProgress = 0.0  // Avoid division by zero
            }
        case .resources:
            self.currentResourceFile = fileName
            self.resourcesCompletedFiles = completed
            self.resourcesTotalFiles = total
            // Clamp progress value to 0.0...1.0
            if total > 0 {
                self.resourcesProgress = max(
                    0.0,
                    min(1.0, Double(completed) / Double(total))
                )
            } else {
                self.resourcesProgress = 0.0  // Avoid division by zero
            }
        }
    }
}

// MARK: - Constants
private enum Constants {
    static let formSpacing: CGFloat = 16
    static let iconSize: CGFloat = 64
    static let cornerRadius: CGFloat = 8
    static let maxImageSize: CGFloat = 1024
}

// MARK: - GameFormView
struct GameFormView: View {
    @EnvironmentObject var gameRepository: GameRepository
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @StateObject private var downloadState = DownloadState()
    @StateObject private var fabricDownloadState = DownloadState()
    @State private var gameName = ""
    @State private var gameIcon = AppConstants.defaultGameIcon
    @State private var iconImage: Image?
    @State private var showImagePicker = false
    @State private var selectedGameVersion = ""
    @State private var selectedModLoader = AppConstants.modLoaders.first ?? ""
    @State private var mojangVersions: [MojangVersionInfo] = []
    @State private var isLoadingVersions = true
    @State private var fabricLoaderVersion: String = ""
    @EnvironmentObject var playerListViewModel: PlayerListViewModel

    // Store the download task reference
    @State private var downloadTask: Task<Void, Error>? = nil
    @FocusState private var isGameNameFocused: Bool

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerView.padding(.horizontal).padding()
            Divider()
            formContentView
                .padding(.horizontal)
                .padding()
            Divider()
            footerView.padding(.horizontal)
                .padding()
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.png, .jpeg, .gif],
            allowsMultipleSelection: false
        ) { result in
            handleImagePickerResult(result)
        }
        
        .task {
            // Request notification authorization and load versions
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    Logger.shared.info("通知权限已授予")
                } else {
                    Logger.shared.warning("用户拒绝了通知权限")
                }

                // Load versions after handling notifications, within the same catch block
                await loadVersions()

            } catch {
                Logger.shared.error(
                    "初始设置过程中出错（通知或加载版本）：\(error.localizedDescription)"
                )
                // Depending on the severity of the error (e.g., versions failed to load),
                // you might want to set a state variable here to show a persistent error message to the user.
            }
        }
    }

    // MARK: - View Components
    private var headerView: some View {
        HStack {
            Text("game.form.title".localized())
                .font(.headline)
            Spacer()
            Image(systemName: "link")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private var formContentView: some View {
        VStack(spacing: Constants.formSpacing) {
            gameIconAndVersionSection
            gameNameSection
            if downloadState.isDownloading {
                downloadProgressSection
            }
        }

    }

    private var gameIconAndVersionSection: some View {
        FormSection {
            HStack(alignment: .top, spacing: Constants.formSpacing) {
                gameIconView
                gameVersionAndLoaderView
            }
        }
    }

    private var gameIconView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("game.form.icon".localized())
                .font(.subheadline)
                .foregroundColor(.primary)

            ZStack {
                if let iconImage = iconImage {
                    iconImage
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .frame(
                            width: Constants.iconSize,
                            height: Constants.iconSize
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: Constants.cornerRadius
                            )
                        )
                        .contentShape(Rectangle())
                } else {
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        .background(Color.gray.opacity(0.08))
                }
            }
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .onTapGesture {
                if !downloadState.isDownloading {
                    showImagePicker = true
                }
            }
            .onDrop(of: [UTType.image.identifier], isTargeted: nil) {
                providers in
                if !downloadState.isDownloading {
                    handleImageDrop(providers)
                } else {
                    false
                }
            }

            Text("game.form.icon.description".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .disabled(downloadState.isDownloading)
    }

    private var gameVersionAndLoaderView: some View {
        VStack(alignment: .leading, spacing: Constants.formSpacing) {
            versionPicker
            modLoaderPicker
        }
    }

    private var versionPicker: some View {
        CustomVersionPicker(
            selected: $selectedGameVersion,
            versions: mojangVersions
        )
        .disabled(downloadState.isDownloading)
    }

    private var modLoaderPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("game.form.modloader".localized())
                .font(.subheadline)
                .foregroundColor(.primary)
            Picker("", selection: $selectedModLoader) {
                ForEach(AppConstants.modLoaders, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(downloadState.isDownloading)
        }
    }

    private var gameNameSection: some View {
        FormSection {
            FormInputField(
                title: "game.form.name".localized(),
                placeholder: "game.form.name.placeholder".localized(),
                text: $gameName,
                isFocused: $isGameNameFocused
            )
            .disabled(downloadState.isDownloading)
        }
    }

    private var downloadProgressSection: some View {
        VStack {
            FormSection {
                DownloadProgressRow(
                    title: "download.core.title".localized(),
                    progress: downloadState.coreProgress,
                    currentFile: downloadState.currentCoreFile,
                    completed: downloadState.coreCompletedFiles,
                    total: downloadState.coreTotalFiles,
                    version: nil
                )
            }
            FormSection {
                DownloadProgressRow(
                    title: "download.resources.title".localized(),
                    progress: downloadState.resourcesProgress,
                    currentFile: downloadState.currentResourceFile,
                    completed: downloadState.resourcesCompletedFiles,
                    total: downloadState.resourcesTotalFiles,
                    version: nil
                )
            }
            if selectedModLoader.lowercased().contains("fabric") {
                FormSection {
                    DownloadProgressRow(
                        title: "fabric.loader.title".localized(),
                        progress: fabricDownloadState.coreProgress,
                        currentFile: fabricDownloadState.currentCoreFile,
                        completed: fabricDownloadState.coreCompletedFiles,
                        total: fabricDownloadState.coreTotalFiles,
                        version: fabricLoaderVersion
                    )
                }
            }
        }
    }

    private var footerView: some View {
        HStack {
            Spacer()
            Button("common.cancel".localized()) {
                // Cancel download task if it exists, otherwise dismiss
                if downloadState.isDownloading, let task = downloadTask {
                    task.cancel()
                    // No UI immediate feedback other than button state
                } else {
                    // If not downloading, just dismiss the form
                    dismiss()
                }
            }
            .keyboardShortcut(.cancelAction)

            Button {
                // Assign the task to the state property
                downloadTask = Task {
                    await saveGame()
                }
            } label: {
                HStack {
                    
                    if downloadState.isDownloading {
                        ProgressView()
                            .controlSize(.small)
                    }else{
                        Text("common.confirm".localized())
                    }
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!isFormValid || downloadState.isDownloading)
        }
    }

    // MARK: - Helper Methods
    private var isFormValid: Bool {
        !gameName.isEmpty
    }

    // Unified error handling for non-critical errors
    private func handleNonCriticalError(_ error: Error, message: String) {
        Logger.shared.error("\(message): \(error.localizedDescription)")
        // Optional: Add state variable here to show a non-blocking visual indicator if needed
    }

    private func loadVersions() async {
        isLoadingVersions = true
        do {
            let mojangManifest =
                try await MinecraftService.fetchVersionManifest()
            let releaseVersions = mojangManifest.versions.filter {
                $0.type == "release"
            }

            await MainActor.run {
                self.mojangVersions = releaseVersions
                if let firstVersion = releaseVersions.first {
                    self.selectedGameVersion = firstVersion.id
                }
                self.isLoadingVersions = false
            }
        } catch {
            await MainActor.run {  // Ensure state updates are on MainActor
                self.isLoadingVersions = false
                handleNonCriticalError(error, message: "加载版本数据失败")
            }
        }
    }

    private func handleImagePickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                handleNonCriticalError(
                    NSError(
                        domain: "",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "未选择文件"]
                    ),
                    message: "图片选择失败"
                )
                return
            }

            guard url.startAccessingSecurityScopedResource() else {
                handleNonCriticalError(
                    NSError(
                        domain: "",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "无法访问所选文件"]
                    ),
                    message: "图片访问失败"
                )
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            // Use asynchronous file reading
            Task { @MainActor in
                do {
                    let data = try Data(contentsOf: url)
                    setIconImage(from: data)
                } catch {
                    handleNonCriticalError(error, message: "无法读取图片文件")
                }
            }

        case .failure(let error):
            handleNonCriticalError(error, message: "选择图片失败")
        }
    }

    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            // Log error for empty provider
            Logger.shared.error("图片拖放失败：没有提供者")
            return false
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(
                forTypeIdentifier: UTType.image.identifier
            ) { data, error in
                if let error = error {
                    DispatchQueue.main.async {
                        handleNonCriticalError(error, message: "加载拖拽图片失败")
                    }
                    return
                }

                if let data = data {
                    DispatchQueue.main.async {
                        setIconImage(from: data)
                    }
                }
            }
            return true
        }
        // Log error for unsupported type
        Logger.shared.warning("图片拖放失败：不支持的类型")
        return false
    }

    private func setIconImage(from data: Data) {
        guard let nsImage = NSImage(data: data) else {
            handleNonCriticalError(
                NSError(
                    domain: "",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "无法创建图片"]
                ),
                message: "error.image.create.failed".localized()
            )
            return
        }

        guard !data.isEmpty else {
            handleNonCriticalError(
                NSError(
                    domain: "",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "图片数据为空"]
                ),
                message: "error.image.data.empty".localized()
            )
            return
        }

        let imageSize = nsImage.size
        if imageSize.width > Constants.maxImageSize
            || imageSize.height > Constants.maxImageSize
        {
            handleNonCriticalError(
                NSError(
                    domain: "",
                    code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey: "error.image.size.large"
                            .localized()
                    ]
                ),
                message: "error.image.size".localized()
            )
            return
        }

        iconImage = Image(nsImage: nsImage)
        gameIcon = "data:image/png;base64," + data.base64EncodedString()
    }

    // Main function to save game and initiate download
    private func saveGame() async {
        guard playerListViewModel.currentPlayer != nil else {
            Logger.shared.error("无法保存游戏，因为没有选择当前玩家。")
            handleNonCriticalError(
                NSError(
                    domain: "",
                    code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey: "error.no.current.player"
                            .localized()
                    ]
                ),
                message: "error.no.current.player.title".localized()
            )
            return
        }
        // 失去焦点
        await MainActor.run { isGameNameFocused = false }
        await MainActor.run { downloadState.reset() }

        guard
            let mojangVersion = mojangVersions.first(where: {
                $0.id == selectedGameVersion
            })
        else {
            Logger.shared.warning("找不到所选版本的 Mojang 版本信息：\(selectedGameVersion)")
            handleNonCriticalError(
                NSError(
                    domain: "",
                    code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey: "error.version.info.missing"
                            .localized()
                    ]
                ),
                message: "error.version.info.fetch".localized()
            )
            return
        }

        // 1. 创建一个临时的 gameInfo 用于下载过程
        var gameInfo = GameVersionInfo(
            gameName: gameName,
            gameIcon: gameIcon,
            gameVersion: selectedGameVersion,
            assetIndex: "",  // 这里先传空字符串，后续下载完成后再赋值
            modLoader: selectedModLoader,
            isUserAdded: true
        )

        Logger.shared.info("开始为游戏下载文件: \(gameInfo.gameName)")

        do {
            // 2. 设置下载所需的前置条件
            let downloadedManifest = try await fetchMojangManifest(
                from: mojangVersion.url
            )
            let fileManager = try await setupFileManager(
                manifest: downloadedManifest,
                modLoader: gameInfo.modLoader
            )

            // 3. 定义所有并发下载任务
            // 任务 1: 游戏本体和资源文件
            async let mainDownload: Void = startDownloadProcess(
                fileManager: fileManager,
                manifest: downloadedManifest
            )

            // 任务 2: Fabric 加载器
            async let fabricSetupResult:
                (loaderVersion: String, classpath: String, mainClass: String)? =
                    {
                        if await selectedModLoader.lowercased().contains(
                            "fabric"
                        ) {
                            return try await FabricLoaderService.setupFabric(
                                for: selectedGameVersion,
                                onProgressUpdate: {
                                    fileName,
                                    completed,
                                    total in
                                    Task { @MainActor in
                                        fabricDownloadState.updateProgress(
                                            fileName: fileName,
                                            completed: completed,
                                            total: total,
                                            type: .core
                                        )
                                    }
                                }
                            )
                        }
                        return nil
                    }()

            // 4. 等待所有下载任务完成
            try await mainDownload
            let fabricResult = try await fabricSetupResult

            // 5. 所有下载成功后，填充 gameInfo 并保存
            // a. 填充 Fabric 相关信息

            // b. 填充 Manifest 相关信息
            gameInfo.assetIndex = downloadedManifest.assetIndex.id
            switch selectedModLoader.lowercased() {
            case "fabric":
                if let result = fabricResult {
                    gameInfo.modVersion = result.loaderVersion
                    gameInfo.modJvm = result.classpath
                    gameInfo.mainClass = result.mainClass
                }
                // 报错
                break  // 已在上面赋值
            default:
                gameInfo.mainClass = downloadedManifest.mainClass
            }

            // c. 生成启动命令
            let username = playerListViewModel.currentPlayer?.name ?? "Player"  // 在 guard 后，这里不会是 nil
            let uuid = gameInfo.id
            let launcherBrand =
                Bundle.main.infoDictionary?["CFBundleName"] as? String
                ?? "MLauncher"
            let launcherVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                as? String ?? "1.0.0"
            gameInfo.launchCommand = MinecraftLaunchCommandBuilder.build(
                manifest: downloadedManifest,
                gameInfo: gameInfo,
                username: username,
                uuid: uuid,
                launcherBrand: launcherBrand,
                launcherVersion: launcherVersion
            )

            // d. 最终保存
            gameRepository.addGame(gameInfo)

            // 6. 发送成功通知并关闭窗口
            sendNotification(
                title: "notification.download.complete.title".localized(),
                body: String(
                    format: "notification.download.complete.body".localized(),
                    gameInfo.gameName,
                    gameInfo.gameVersion,
                    gameInfo.modLoader
                )
            )
            // 重置 Fabric Loader 状态
            await MainActor.run {
                fabricLoaderVersion = ""
            }
            await handleDownloadSuccess()

        } catch is CancellationError {
            await handleDownloadCancellation()
        } catch {
            await handleDownloadFailure(gameInfo: gameInfo, error: error)
        }
        await MainActor.run { downloadTask = nil }
    }

    // Helper method to fetch Mojang Manifest
    private func fetchMojangManifest(from url: URL) async throws
        -> MinecraftVersionManifest
    {
        Logger.shared.info("正在从以下地址获取 Mojang 版本清单：\(url.absoluteString)")
        let (manifestData, _) = try await URLSession.shared.data(from: url)
        let downloadedManifest = try JSONDecoder().decode(
            MinecraftVersionManifest.self,
            from: manifestData
        )
        Logger.shared.info("成功获取版本清单：\(downloadedManifest.id)")
        return downloadedManifest
    }

    // Helper method to set up MinecraftFileManager and directories
    private func setupFileManager(
        manifest: MinecraftVersionManifest,
        modLoader: String
    ) async throws -> MinecraftFileManager {
        // 现在 MinecraftFileManager 不再需要参数，直接初始化
        let nativesDir = AppPaths.nativesDirectory
        try FileManager.default.createDirectory(
            at: nativesDir!,
            withIntermediateDirectories: true
        )
        Logger.shared.info("创建目录：\(nativesDir!.path)")
        return MinecraftFileManager()
    }

    // Helper method to initiate the download process
    private func startDownloadProcess(
        fileManager: MinecraftFileManager,
        manifest: MinecraftVersionManifest
    ) async throws {
        // Start download with combined progress tracking
        await MainActor.run {  // Ensure state updates are on MainActor
            downloadState.startDownload(
                coreTotalFiles: 1 + manifest.libraries.count + 1,  // Client JAR + Libraries + Asset Index
                resourcesTotalFiles: 0  // Will be updated when asset index is parsed
            )
        }

        fileManager.onProgressUpdate = { fileName, completed, total, type in
            // Progress update closure - check for cancellation here too as a fallback
            Task { @MainActor in  // Ensure state updates are on MainActor
                if Task.isCancelled {  // Check task cancellation
                    // The primary cancellation signal comes from task.cancel() on the main downloadTask.
                    // Just update state and let the main task handle the CancellationError.
                }
                downloadState.updateProgress(
                    fileName: fileName,
                    completed: completed,
                    total: total,
                    type: type
                )
            }
        }

        // 执行实际的下载操作
        try await fileManager.downloadVersionFiles(manifest: manifest)
    }

    // Helper method to handle successful download completion
    private func handleDownloadSuccess() async {
        Logger.shared.info("下载和保存成功")
        await MainActor.run {  // Ensure dismiss is on MainActor
            dismiss()
        }
    }

    // Helper method to handle download cancellation
    private func handleDownloadCancellation() async {
        Logger.shared.info("游戏下载任务已取消")
        // No notification or alert on cancellation, just reset state and dismiss
        await MainActor.run {  // Ensure state updates are on MainActor
            downloadState.reset()
            dismiss()  // Dismiss the view on cancellation
        }
    }

    // Helper method to handle download failure (non-cancellation errors)
    private func handleDownloadFailure(gameInfo: GameVersionInfo, error: Error)
        async
    {
        Logger.shared.error("保存游戏或下载文件时出错：\(error)")
        // Send error notification
        sendNotification(
            title: "notification.download.failed.title".localized(),
            body: String(
                format: "notification.download.failed.body".localized(),
                gameInfo.gameName,
                gameInfo.gameVersion,
                gameInfo.modLoader,
                error.localizedDescription
            )
        )

        await MainActor.run {  // Ensure state updates are on MainActor
            downloadState.reset()
            // Keep the form open to show the error if dismissal is removed from here
            // If we want to dismiss on failure too, add dismiss() here
        }
    }

    // Helper function to send a local notification
    private func sendNotification(title: String, body: String) {
        Logger.shared.info("准备发送通知：\(title) - \(body)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.error("添加通知请求时出错：\(error.localizedDescription)")
            } else {
                Logger.shared.info("成功添加通知请求：\(request.identifier)")
            }
        }
    }

    // 监听modLoader和gameVersion变化，自动获取fabric loader版本
    private func updateFabricLoaderVersionIfNeeded() {
        guard selectedModLoader.lowercased().contains("fabric"),
            !selectedGameVersion.isEmpty
        else {
            fabricLoaderVersion = ""
            return
        }
        fabricLoaderVersion = ""
        // 不再请求 loader，等 downloadFabricResources 真正下载时再赋值
    }
}

// MARK: - Supporting Views
private struct FormSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .padding(.top,6)
                .padding(.bottom,6)
        }
    }
}

private struct FormInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.primary)
                .focused($isFocused)
        }
    }
}

private struct DownloadProgressRow: View {
    let title: String
    let progress: Double
    let currentFile: String
    let completed: Int
    let total: Int
    let version: String?
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                if let version = version, !version.isEmpty {
                    Text(version)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(
                    String(
                        format: "download.progress".localized(),
                        Int(progress * 100)
                    )
                )
                .font(.headline)
                .foregroundColor(.secondary)
            }
            ProgressView(value: progress)
            HStack {
                Text(
                    String(
                        format: "download.current.file".localized(),
                        currentFile
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)
                Spacer()
                Text(
                    String(
                        format: "download.files".localized(),
                        completed,
                        total
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

private struct CustomVersionPicker: View {
    @Binding var selected: String
    let versions: [MojangVersionInfo]
    @State private var showMenu = false

    // 分组后的大版本
    private var groupedVersions: [(String, [MojangVersionInfo])] {
        let dict = Dictionary(grouping: versions) { version in
            version.id.split(separator: ".").prefix(2).joined(separator: ".")
        }
        return dict.sorted {
            let lhs = $0.key.split(separator: ".").compactMap { Int($0) }
            let rhs = $1.key.split(separator: ".").compactMap { Int($0) }
            return lhs.lexicographicallyPrecedes(rhs)
        }.reversed()
    }

    // 固定6列
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 6
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("game.form.version".localized())
                .font(.subheadline)
                .foregroundColor(.primary)
            versionInput
        }
    }

    // 只读输入框样式
    private var versionInput: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                .background(Color(NSColor.textBackgroundColor))
            HStack {
                Text(
                    selected.isEmpty
                        ? "game.form.version.placeholder".localized() : selected
                )
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                Spacer()
            }
        }
        .frame(height: 22)
        .padding(.leading, 8)
        .onTapGesture { showMenu.toggle() }
        .popover(isPresented: $showMenu, arrowEdge: .trailing) {
            versionPopoverContent
        }
    }

    // 弹窗内容
    private var versionPopoverContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(groupedVersions, id: \.0) { (major, versions) in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(major)
                            .font(.headline)
                            .padding(.vertical, 2)
                        LazyVGrid(
                            columns: columns,
                            alignment: .leading,
                            spacing: 8
                        ) {
                            ForEach(versions, id: \.id) { version in
                                versionButton(for: version)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: 320, maxHeight: 360)
    }

    // 单个版本按钮
    private func versionButton(for version: MojangVersionInfo) -> some View {
        Button(version.id) {
            selected = version.id
            showMenu = false
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .font(.subheadline)
        .cornerRadius(4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    selected == version.id
                        ? Color.accentColor : Color.gray.opacity(0.15)
                )
        )
        .foregroundStyle(selected == version.id ? .white : .primary)
        .buttonStyle(.plain)
        .fixedSize()
    }
}

