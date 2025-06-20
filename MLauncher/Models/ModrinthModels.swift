import Foundation

// Modrinth 项目模型
struct ModrinthProject: Codable {
    let projectId: String
    let projectType: String
    let slug: String
    let author: String
    let title: String
    let description: String
    let categories: [String]
    let displayCategories: [String]
    let versions: [String]
    let downloads: Int
    let follows: Int
    let iconUrl: String?
    let dateCreated: String
    let dateModified: String
    let latestVersion: String
    let license: String
    let clientSide: String
    let serverSide: String
    let gallery: [String]?
    let featuredGallery: String?
    let type: String?
    let color: Int?

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case projectType = "project_type"
        case slug, author, title, description, categories
        case displayCategories = "display_categories"
        case versions, downloads, follows
        case iconUrl = "icon_url"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case latestVersion = "latest_version"
        case license
        case clientSide = "client_side"
        case serverSide = "server_side"
        case gallery
        case featuredGallery = "featured_gallery"
        case color
        case type
    }
}

struct ModrinthProjectDetail: Codable {
    let slug: String
    let title: String
    let description: String
    let categories: [String]
    let clientSide: String
    let serverSide: String
    let body: String
    let status: String
    let requestedStatus: String?
    let additionalCategories: [String]?
    let issuesUrl: String?
    let sourceUrl: String?
    let wikiUrl: String?
    let discordUrl: String?
    let donationUrls: [DonationUrl]?
    let projectType: String
    let downloads: Int
    let iconUrl: String?
    let color: Int?
    let threadId: String?
    let monetizationStatus: String?
    let id: String
    let team: String
    let bodyUrl: String?
    let moderatorMessage: ModeratorMessage?
    let published: Date
    let updated: Date
    let approved: Date?
    let queued: Date?
    let followers: Int
    let license: License?
    let versions: [String]
    let gameVersions: [String]
    let loaders: [String]
    let gallery: [GalleryImage]?
    
    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case description
        case categories
        case clientSide = "client_side"
        case serverSide = "server_side"
        case body
        case status
        case requestedStatus = "requested_status"
        case additionalCategories = "additional_categories"
        case issuesUrl = "issues_url"
        case sourceUrl = "source_url"
        case wikiUrl = "wiki_url"
        case discordUrl = "discord_url"
        case donationUrls = "donation_urls"
        case projectType = "project_type"
        case downloads
        case iconUrl = "icon_url"
        case color
        case threadId = "thread_id"
        case monetizationStatus = "monetization_status"
        case id
        case team
        case bodyUrl = "body_url"
        case moderatorMessage = "moderator_message"
        case published
        case updated
        case approved
        case queued
        case followers
        case license
        case versions
        case gameVersions = "game_versions"
        case loaders
        case gallery
    }
}

struct DonationUrl: Codable {
    let id: String
    let platform: String
    let url: String
}

struct ModeratorMessage: Codable {
    let message: String
    let body: String?
}

struct GalleryImage: Codable {
    let url: String
    let featured: Bool
    let title: String?
    let description: String?
    let created: Date
    let ordering: Int
}

// Modrinth 版本模型
struct ModrinthVersion: Codable {
    let id: String
    let projectId: String
    let name: String
    let versionNumber: String
    let changelog: String?
    let files: [ModrinthFile]
    let dependencies: [ModrinthDependency]
    let gameVersions: [String]
    let loaders: [String]
    let featured: Bool
    let status: String
    let requestedStatus: String?
    let published: String
}

// Modrinth 文件模型
struct ModrinthFile: Codable {
    let hashes: [String: String]
    let url: String
    let filename: String
    let primary: Bool
    let size: Int
}

// Modrinth 依赖模型
struct ModrinthDependency: Codable {
    let versionId: String?
    let projectId: String?
    let dependencyType: String
}

// Modrinth 许可证模型
struct ModrinthLicense: Codable {
    let id: String
    let name: String
    let url: String?
}

// Modrinth 搜索结果模型
struct ModrinthResult: Codable {
    let hits: [ModrinthProject]
    let offset: Int
    let limit: Int
    let totalHits: Int

    enum CodingKeys: String, CodingKey {
        case hits, offset, limit
        case totalHits = "total_hits"
    }
}

// 游戏版本
struct GameVersion: Codable, Identifiable,Hashable {
    let version: String
    let version_type: String
    let date: String
    let major: Bool

    var id: String { version }
}

// 加载器
struct Loader: Codable, Identifiable {
    let name: String
    let icon: String
    let supported_project_types: [String]

    var id: String { name }
}

// 分类
struct Category: Codable, Identifiable,Hashable {
    let name: String
    let project_type: String
    let header: String

    var id: String { name }
}

// 许可证
struct License: Codable {
    let id: String
    let name: String
    let url: String?
}

/// Modrinth version model
public struct ModrinthProjectDetailVersion: Codable, Identifiable {
    /// Game versions this version supports
    public let gameVersions: [String]
    
    /// Loaders this version supports
    public let loaders: [String]
    
    /// Version ID
    public let id: String
    
    /// Project ID
    public let projectId: String
    
    /// Author ID
    public let authorId: String
    
    /// Whether this version is featured
    public let featured: Bool
    
    /// Version name
    public let name: String
    
    /// Version number
    public let versionNumber: String
    
    /// Version changelog
    public let changelog: String?
    
    /// URL to changelog
    public let changelogUrl: String?
    
    /// Date published
    public let datePublished: Date
    
    /// Number of downloads
    public let downloads: Int
    
    /// Version type (release, beta, alpha)
    public let versionType: String
    
    /// Version status
    public let status: String
    
    /// Requested status
    public let requestedStatus: String?
    
    /// Version files
    public let files: [ModrinthVersionFile]
    
    /// Version dependencies
    public let dependencies: [ModrinthVersionDependency]
    
    enum CodingKeys: String, CodingKey {
        case gameVersions = "game_versions"
        case loaders
        case id
        case projectId = "project_id"
        case authorId = "author_id"
        case featured
        case name
        case versionNumber = "version_number"
        case changelog
        case changelogUrl = "changelog_url"
        case datePublished = "date_published"
        case downloads
        case versionType = "version_type"
        case status
        case requestedStatus = "requested_status"
        case files
        case dependencies
    }
}

/// Modrinth version file model
public struct ModrinthVersionFile: Codable {
    /// File hashes
    public let hashes: ModrinthVersionFileHashes
    
    /// File URL
    public let url: String
    
    /// File name
    public let filename: String
    
    /// Whether this is the primary file
    public let primary: Bool
    
    /// File size in bytes
    public let size: Int
    
    /// File type
    public let fileType: String?
    
    enum CodingKeys: String, CodingKey {
        case hashes
        case url
        case filename
        case primary
        case size
        case fileType = "file_type"
    }
}

/// Modrinth version file hashes model
public struct ModrinthVersionFileHashes: Codable {
    /// SHA512 hash
    public let sha512: String
    
    /// SHA1 hash
    public let sha1: String
}

/// Modrinth version dependency model
public struct ModrinthVersionDependency: Codable {
    /// Project ID
    public let projectId: String?
    
    /// Version ID
    public let versionId: String?
    
    /// Dependency type
    public let dependencyType: String
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case versionId = "version_id"
        case dependencyType = "dependency_type"
    }
}
