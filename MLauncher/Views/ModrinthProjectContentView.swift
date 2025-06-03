//
//  ModrinthProjectContentView.swift
//  MLauncher
//
//  Created by su on 2025/6/2.
//
import SwiftUI

struct ModrinthProjectContentView: View {
    @State private var isLoading = false
    @State private var error: Error?
    // 示例数据（实际应用中应从API获取）
    @Binding var projectDetail: ModrinthProjectDetail?
    let projectId: String
    var body: some View {
        VStack {
            if let error = error {
                ErrorView(error)
            } else if let project = projectDetail {
                // 兼容性信息
                compatibilitySection(project)
                
                // 链接
                linksSection(project)
                
                // 创建者
                creatorsSection(project)
                
                // 详情
                detailsSection(project)
            }
        }.task(id: projectId) {
            await loadProjectDetails()
        }
    }
    
    
    
    private func compatibilitySection(_ project: ModrinthProjectDetail)-> some View {
        SectionView(title: "project.info.compatibility".localized()) {
            VStack(alignment: .leading, spacing: 12) {
                // Minecraft版本
                HStack {
                    Text("project.info.minecraft".localized()).font(.headline)
                    Text("project.info.minecraft.edition".localized()).foregroundStyle(.secondary).font(.caption.bold())
                }
                
                // 游戏版本
                if !project.gameVersions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("project.info.versions".localized()).font(.headline)
                        FlowLayout(spacing: 6) {
                            ForEach(project.gameVersions.filter { version in
                                // 过滤出纯数字版本（如 1.20.4, 1.19.4 等）
                                let components = version.split(separator: ".")
                                return components.allSatisfy { $0.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil }
                            }, id: \.self) { version in
                                Text(version)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.top,4)
                    }
                }
                
                // 平台/加载器
                if !project.loaders.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("project.info.platforms".localized()).font(.headline)
                        FlowLayout(spacing: 6) {
                            ForEach(project.loaders, id: \.self) { version in
                                Text(version)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.top,4)
                    }
                }
                
                // 平台支持
                HStack {
                    Text("platform.support".localized()+":").font(.headline)
                    HStack(spacing: 8) {
                        // 客户端支持
                        HStack(spacing: 2) {
                            Image(systemName:  "laptopcomputer")
                                .foregroundColor(.secondary)
                            Text("platform.client.\(project.clientSide)".localized())
                                .foregroundColor(.secondary).font(.caption)
                        }
                        
                        // 服务器端支持
                        HStack(spacing: 2) {
                            Image(systemName: "server.rack")
                                .foregroundColor(.secondary)
                            Text("platform.server.\(project.serverSide)".localized())
                                .foregroundColor(.secondary).font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    
    
    private func linksSection(_ project: ModrinthProjectDetail)-> some View {
        SectionView(title: "project.info.links".localized()) {
            FlowLayout(spacing: 6) {
                if let url = project.issuesUrl {
                    Link(destination: URL(string: url)!) {
                        Text("project.info.links.issues".localized())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                if let url = project.sourceUrl {
                    Link(destination: URL(string: url)!) {
                        Text("project.info.links.source".localized())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                if let url = project.wikiUrl {
                    Link(destination: URL(string: url)!) {
                        Text("project.info.links.wiki".localized())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                if let url = project.discordUrl {
                    Link(destination: URL(string: url)!) {
                        Text("project.info.links.discord".localized())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                if let donationUrls = project.donationUrls, !donationUrls.isEmpty {
                    ForEach(donationUrls, id: \.id) { donation in
                        Link(destination: URL(string: donation.url)!) {
                            Text("project.info.links.donate".localized())
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }
    
    private func creatorsSection(_ project: ModrinthProjectDetail)-> some View {
        SectionView(title: "project.info.creators".localized()) {
            // 这里需要根据实际API返回的团队信息调整
            // 示例数据
            VStack(alignment: .leading, spacing: 8) {
                CreatorRow(name: "Kichura", role: "project.info.creators.moderator".localized())
                CreatorRow(name: "osfanbuff63", role: "project.info.creators.moderator".localized())
                CreatorRow(name: "TheBossMagnus", role: "project.info.creators.moderator".localized())
                CreatorRow(name: "robotkoer", role: "project.info.creators.owner".localized())
            }
        }
    }
    
    private func detailsSection(_ project: ModrinthProjectDetail)-> some View {
        SectionView(title: "project.info.details".localized()) {
            VStack(alignment: .leading, spacing: 8) {
                if let license = project.license {
                    DetailRow(label: "project.info.details.licensed".localized(), value: license.name)
                }
                
                DetailRow(label: "project.info.details.published".localized(), value: project.published.formattedDate())
                DetailRow(label: "project.info.details.updated".localized(), value: project.updated.formattedDate())
            }
        }
    }
    // MARK: - Data Loading
    private func loadProjectDetails() async {
        isLoading = true
        error = nil
        
        Logger.shared.info("Loading project details for ID: \(projectId)")
        
        do {
            let fetchedProject = try await ModrinthService.fetchProjectDetails(id: projectId)
            await MainActor.run {
                projectDetail = fetchedProject
                isLoading = false
            }
            Logger.shared.info("Successfully loaded project details for ID: \(projectId)")
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
            Logger.shared.error("Failed to load project details for ID: \(projectId), error: \(error)")
        }
    }
}

// MARK: - 辅助视图

private struct SectionView<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .padding(.top, 10)
            
            content()
        }
    }
}

private struct LinkButton: View {
    let text: String
    let url: String
    
    var body: some View {
        if let url = URL(string: url) {
            Link(destination: url) {
                HStack {
                    Text(text)
                    Spacer()
                }
                .foregroundColor(.secondary).font(.callout)
            }
        }
    }
}

private struct CreatorRow: View {
    let name: String
    let role: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.callout.bold())
            Spacer()
            Text(role)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label).font(.callout.bold())
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}



extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}


