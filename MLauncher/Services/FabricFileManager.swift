import Foundation

class FabricFileManager {
    let librariesDir: URL
    let session: URLSession
    var onProgressUpdate: ((String, Int, Int) -> Void)?
    private let fileManager = FileManager.default
    private let retryCount = 3
    private let retryDelay: TimeInterval = 2
    
    init(librariesDir: URL) {
        self.librariesDir = librariesDir
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = GameSettingsManager.shared.concurrentDownloads
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    actor Counter {
        private var value = 0
        func increment() -> Int {
            value += 1
            return value
        }
    }
    
    func downloadFabricJars(urls: [URL], sha1s: [String?]? = nil) async throws {
        let total = urls.count
        let counter = Counter()
        guard let metaLibrariesDir = AppPaths.metaDirectory?.appendingPathComponent("libraries") else { return }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let fileName = url.lastPathComponent
                    let mavenPath = FabricFileManager.mavenURLToMavenPath(url: url)
                    let destinationURL = metaLibrariesDir.appendingPathComponent(mavenPath)
                    try self.fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    let expectedSha1 = sha1s?.count ?? 0 > index ? sha1s?[index] : nil
                    do {
                        _ = try await DownloadManager.downloadFile(urlString: url.absoluteString, destinationURL: destinationURL, expectedSha1: expectedSha1)
                    } catch {
                        throw error
                    }
                    let currentCompleted = await counter.increment()
                    await MainActor.run {
                        self.onProgressUpdate?(fileName, currentCompleted, total)
                    }
                }
            }
            try await group.waitForAll()
        }
    }

    static func mavenURLToMavenPath(url: URL) -> String {
        let components = url.path.split(separator: "/")
        return components.joined(separator: "/")
    }
} 