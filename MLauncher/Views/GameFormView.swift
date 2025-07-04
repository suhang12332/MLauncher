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
            updateCoreProgress(fileName: fileName, completed: completed, total: total)
        case .resources:
            updateResourcesProgress(fileName: fileName, completed: completed, total: total)
        }
    }
    
    private func updateCoreProgress(fileName: String, completed: Int, total: Int) {
        currentCoreFile = fileName
        coreCompletedFiles = completed
        coreTotalFiles = total
        coreProgress = calculateProgress(completed: completed, total: total)
    }
    
    private func updateResourcesProgress(fileName: String, completed: Int, total: Int) {
        currentResourceFile = fileName
        resourcesCompletedFiles = completed
        resourcesTotalFiles = total
        resourcesProgress = calculateProgress(completed: completed, total: total)
    }
    
    private func calculateProgress(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0.0 }
        return max(0.0, min(1.0, Double(completed) / Double(total)))
    }
}

// MARK: - Constants
private enum Constants {
    static let formSpacing: CGFloat = 16
    static let iconSize: CGFloat = 64
    static let cornerRadius: CGFloat = 8
    static let maxImageSize: CGFloat = 1024
    static let versionGridColumns = 6
    static let versionPopoverMinWidth: CGFloat = 320
    static let versionPopoverMaxHeight: CGFloat = 360
    static let versionButtonPadding: CGFloat = 6
    static let versionButtonVerticalPadding: CGFloat = 3
}

// MARK: - GameFormView
struct GameFormView: View {
    @EnvironmentObject var gameRepository: GameRepository
    @EnvironmentObject var playerListViewModel: PlayerListViewModel
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
    @State private var downloadTask: Task<Void, Error>? = nil
    @FocusState private var isGameNameFocused: Bool

    // MARK: - Body
    var body: some View {
        CommonSheetView(header: {headerView}, body: {formContentView}, footer: {footerView})
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.png, .jpeg, .gif],
            allowsMultipleSelection: false
        ) { result in
            handleImagePickerResult(result)
        }
        .task {
            await initializeView()
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

            iconContainer
                .onTapGesture {
                    if !downloadState.isDownloading {
                        showImagePicker = true
                    }
                }
                .onDrop(of: [UTType.image.identifier], isTargeted: nil) { providers in
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
    
    private var iconContainer: some View {
        ZStack {
            if let iconImage = iconImage {
                iconImage
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                    .contentShape(Rectangle())
            } else {
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    .background(Color.gray.opacity(0.08))
            }
        }
        .frame(width: Constants.iconSize, height: Constants.iconSize)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
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
        VStack(spacing: 24) {
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
            cancelButton
            Spacer()
            confirmButton
        }
    }
    
    private var cancelButton: some View {
        Button("common.cancel".localized()) {
            if downloadState.isDownloading, let task = downloadTask {
                task.cancel()
            } else {
                dismiss()
            }
        }
        .keyboardShortcut(.cancelAction)
    }
    
    private var confirmButton: some View {
        Button {
            downloadTask = Task {
                await saveGame()
            }
        } label: {
            HStack {
                if downloadState.isDownloading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("common.confirm".localized())
                }
            }
        }
        .keyboardShortcut(.defaultAction)
        .disabled(!isFormValid || downloadState.isDownloading)
    }

    // MARK: - Helper Methods
    private var isFormValid: Bool {
        !gameName.isEmpty
    }

    private func initializeView() async {
        await NotificationManager.requestAuthorizationIfNeeded()
        await loadVersions()
    }

    private func handleNonCriticalError(_ error: Error, message: String) {
        Logger.shared.error("\(message): \(error.localizedDescription)")
    }

    private func loadVersions() async {
        isLoadingVersions = true
        do {
            let mojangManifest = try await MinecraftService.fetchVersionManifest()
            let releaseVersions = mojangManifest.versions.filter { $0.type == "release" }

            await MainActor.run {
                self.mojangVersions = releaseVersions
                if let firstVersion = releaseVersions.first {
                    self.selectedGameVersion = firstVersion.id
                }
                self.isLoadingVersions = false
            }
        } catch {
            await MainActor.run {
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
                    NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "未选择文件"]),
                    message: "图片选择失败"
                )
                return
            }

            guard url.startAccessingSecurityScopedResource() else {
                handleNonCriticalError(
                    NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法访问所选文件"]),
                    message: "图片访问失败"
                )
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

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
            Logger.shared.error("图片拖放失败：没有提供者")
            return false
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
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
        Logger.shared.warning("图片拖放失败：不支持的类型")
        return false
    }

    private func setIconImage(from data: Data) {
        guard let nsImage = NSImage(data: data) else {
            handleNonCriticalError(
                NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法创建图片"]),
                message: "error.image.create.failed".localized()
            )
            return
        }

        guard !data.isEmpty else {
            handleNonCriticalError(
                NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "图片数据为空"]),
                message: "error.image.data.empty".localized()
            )
            return
        }

        let imageSize = nsImage.size
        if imageSize.width > Constants.maxImageSize || imageSize.height > Constants.maxImageSize {
            handleNonCriticalError(
                NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "error.image.size.large".localized()]),
                message: "error.image.size".localized()
            )
            return
        }

        iconImage = Image(nsImage: nsImage)
        gameIcon = "data:image/png;base64," + data.base64EncodedString()
    }

    // MARK: - Game Save Methods
    private func saveGame() async {
        guard playerListViewModel.currentPlayer != nil else {
            Logger.shared.error("无法保存游戏，因为没有选择当前玩家。")
            handleNonCriticalError(
                NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "error.no.current.player".localized()]),
                message: "error.no.current.player.title".localized()
            )
            return
        }
        
        await MainActor.run { 
            isGameNameFocused = false 
            downloadState.reset() 
        }

        guard let mojangVersion = mojangVersions.first(where: { $0.id == selectedGameVersion }) else {
            Logger.shared.warning("找不到所选版本的 Mojang 版本信息：\(selectedGameVersion)")
            handleNonCriticalError(
                NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "error.version.info.missing".localized()]),
                message: "error.version.info.fetch".localized()
            )
            return
        }

        var gameInfo = GameVersionInfo(
            gameName: gameName,
            gameIcon: gameIcon,
            gameVersion: selectedGameVersion,
            assetIndex: "",
            modLoader: selectedModLoader,
            isUserAdded: true
        )

        Logger.shared.info("开始为游戏下载文件: \(gameInfo.gameName)")

        do {
            let downloadedManifest = try await fetchMojangManifest(from: mojangVersion.url)
            let fileManager = try await setupFileManager(manifest: downloadedManifest, modLoader: gameInfo.modLoader)

            async let mainDownload: Void = startDownloadProcess(fileManager: fileManager, manifest: downloadedManifest)
            async let fabricSetupResult: (loaderVersion: String, classpath: String, mainClass: String)? = setupFabricIfNeeded()

            try await mainDownload
            let fabricResult = await fabricSetupResult

            gameInfo = await finalizeGameInfo(gameInfo: gameInfo, manifest: downloadedManifest, fabricResult: fabricResult)
            gameRepository.addGame(gameInfo)

            NotificationManager.send(
                title: "notification.download.complete.title".localized(),
                body: String(format: "notification.download.complete.body".localized(), gameInfo.gameName, gameInfo.gameVersion, gameInfo.modLoader)
            )
            
            await MainActor.run { fabricLoaderVersion = "" }
            await handleDownloadSuccess()

        } catch is CancellationError {
            await handleDownloadCancellation()
        } catch {
            await handleDownloadFailure(gameInfo: gameInfo, error: error)
        }
        await MainActor.run { downloadTask = nil }
    }

    private func fetchMojangManifest(from url: URL) async throws -> MinecraftVersionManifest {
        Logger.shared.info("正在从以下地址获取 Mojang 版本清单：\(url.absoluteString)")
        let (manifestData, _) = try await URLSession.shared.data(from: url)
        let downloadedManifest = try JSONDecoder().decode(MinecraftVersionManifest.self, from: manifestData)
        Logger.shared.info("成功获取版本清单：\(downloadedManifest.id)")
        return downloadedManifest
    }

    private func setupFileManager(manifest: MinecraftVersionManifest, modLoader: String) async throws -> MinecraftFileManager {
        let nativesDir = AppPaths.nativesDirectory
        try FileManager.default.createDirectory(at: nativesDir!, withIntermediateDirectories: true)
        Logger.shared.info("创建目录：\(nativesDir!.path)")
        return MinecraftFileManager()
    }

    private func startDownloadProcess(fileManager: MinecraftFileManager, manifest: MinecraftVersionManifest) async throws {
        await MainActor.run {
            downloadState.startDownload(
                coreTotalFiles: 1 + manifest.libraries.count + 1,
                resourcesTotalFiles: 0
            )
        }

        fileManager.onProgressUpdate = { fileName, completed, total, type in
            Task { @MainActor in
                downloadState.updateProgress(fileName: fileName, completed: completed, total: total, type: type)
            }
        }

        try await fileManager.downloadVersionFiles(manifest: manifest,gameName: gameName)
    }
    
    private func setupFabricIfNeeded() async -> (loaderVersion: String, classpath: String, mainClass: String)? {
        guard selectedModLoader.lowercased().contains("fabric") else { return nil }
        
        do {
            guard let gameInfo = mojangVersions.first(where: { $0.id == selectedGameVersion }).map({_ in 
                GameVersionInfo(
                    gameName: gameName,
                    gameIcon: gameIcon,
                    gameVersion: selectedGameVersion,
                    assetIndex: "",
                    modLoader: selectedModLoader,
                    isUserAdded: true
                )
            }) else { return nil }
            return try await FabricLoaderService.setupFabric(
                for: selectedGameVersion,
                gameInfo: gameInfo,
                onProgressUpdate: { fileName, completed, total in
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
        } catch {
            Logger.shared.error("Fabric 加载器设置失败: \(error.localizedDescription)")
            handleNonCriticalError(error, message: "Fabric 加载器设置失败")
            return nil
        }
    }
    
    private func finalizeGameInfo(
        gameInfo: GameVersionInfo,
        manifest: MinecraftVersionManifest,
        fabricResult: (loaderVersion: String, classpath: String, mainClass: String)?
    ) async -> GameVersionInfo {
        var updatedGameInfo = gameInfo
        updatedGameInfo.assetIndex = manifest.assetIndex.id
        
        switch selectedModLoader.lowercased() {
        case "fabric":
            if let result = fabricResult {
                updatedGameInfo.modVersion = result.loaderVersion
                updatedGameInfo.modJvm = result.classpath
                updatedGameInfo.mainClass = result.mainClass
            }
        default:
            updatedGameInfo.mainClass = manifest.mainClass
        }

        let username = playerListViewModel.currentPlayer?.name ?? "Player"
        let uuid = gameInfo.id
        let launcherBrand = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "MLauncher"
        let launcherVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        updatedGameInfo.launchCommand = MinecraftLaunchCommandBuilder.build(
            manifest: manifest,
            gameInfo: updatedGameInfo,
            username: username,
            uuid: uuid,
            launcherBrand: launcherBrand,
            launcherVersion: launcherVersion
        )
        
        return updatedGameInfo
    }

    private func handleDownloadSuccess() async {
        Logger.shared.info("下载和保存成功")
        await MainActor.run { dismiss() }
    }

    private func handleDownloadCancellation() async {
        Logger.shared.info("游戏下载任务已取消")
        await MainActor.run {
            downloadState.reset()
            dismiss()
        }
    }

    private func handleDownloadFailure(gameInfo: GameVersionInfo, error: Error) async {
        Logger.shared.error("保存游戏或下载文件时出错：\(error)")
        NotificationManager.send(
            title: "notification.download.failed.title".localized(),
            body: String(format: "notification.download.failed.body".localized(), gameInfo.gameName, gameInfo.gameVersion, gameInfo.modLoader, error.localizedDescription)
        )
        await MainActor.run { downloadState.reset() }
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
                .padding(.top, 6)
                .padding(.bottom, 6)
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
                Text(String(format: "download.progress".localized(), Int(progress * 100)))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: progress)
            HStack {
                Text(String(format: "download.current.file".localized(), currentFile))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "download.files".localized(), completed, total))
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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: Constants.versionGridColumns)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("game.form.version".localized())
                .font(.subheadline)
                .foregroundColor(.primary)
            versionInput
        }
    }

    private var versionInput: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                .background(Color(NSColor.textBackgroundColor))
            HStack {
                Text(selected.isEmpty ? "game.form.version.placeholder".localized() : selected)
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

    private var versionPopoverContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(groupedVersions, id: \.0) { (major, versions) in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(major)
                            .font(.headline)
                            .padding(.vertical, 2)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(versions, id: \.id) { version in
                                versionButton(for: version)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: Constants.versionPopoverMinWidth, maxHeight: Constants.versionPopoverMaxHeight)
    }

    private func versionButton(for version: MojangVersionInfo) -> some View {
        Button(version.id) {
            selected = version.id
            showMenu = false
        }
        .padding(.horizontal, Constants.versionButtonPadding)
        .padding(.vertical, Constants.versionButtonVerticalPadding)
        .font(.subheadline)
        .cornerRadius(4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(selected == version.id ? Color.accentColor : Color.gray.opacity(0.15))
        )
        .foregroundStyle(selected == version.id ? .white : .primary)
        .buttonStyle(.plain)
        .fixedSize()
    }
}

