import Foundation

class FabricFileManager {
    let librariesDir: URL
    let session: URLSession
    var onProgressUpdate: ((String, Int, Int) -> Void)?
    private let fileManager = FileManager.default
    private let maxConcurrentDownloads = 8
    private let retryCount = 3
    private let retryDelay: TimeInterval = 2
    
    init(librariesDir: URL) {
        self.librariesDir = librariesDir
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
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
    
    func downloadFabricJars(urls: [URL]) async throws {
        let total = urls.count
        let counter = Counter()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let fileName = url.lastPathComponent
                    let urlPath = url.path
                    let relativePath = urlPath.hasPrefix("/") ? String(urlPath.dropFirst()) : urlPath
                    let destURL = self.librariesDir.appendingPathComponent(relativePath)
                    let destDir = destURL.deletingLastPathComponent()
                    try self.fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
                    if self.fileManager.fileExists(atPath: destURL.path) {
                        let currentCompleted = await counter.increment()
                        await MainActor.run {
                            self.onProgressUpdate?(fileName, currentCompleted, total)
                        }
                        return
                    }
                    var lastError: Error?
                    for attempt in 0..<self.retryCount {
                        do {
                            let (data, response) = try await self.session.data(from: url)
                            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                                throw URLError(.badServerResponse)
                            }
                            try data.write(to: destURL)
                            break
                        } catch {
                            lastError = error
                            if attempt < self.retryCount - 1 {
                                try await Task.sleep(nanoseconds: UInt64(self.retryDelay * 1_000_000_000))
                                continue
                            } else {
                                throw lastError ?? URLError(.unknown)
                            }
                        }
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
} 