//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import PathKit
import XcodeProj
import Foundation

final class DashboardManager {
    private let xcodeProj: XcodeProj
    private let root: Path
    private let config: DashboardConfig

    /// - isWorkspace: Pass `true` only when the source is a `.xcworkspace`.
    ///   Dev pod scanning via podspecs is skipped for standalone `.xcodeproj` inputs
    ///   since CocoaPods always generates a workspace.
    init(xcodeProj: XcodeProj, root: Path, config: DashboardConfig = DashboardConfig(), isWorkspace: Bool = false) {
        self.xcodeProj = xcodeProj
        self.root = root
        self.config = config
        self.isWorkspace = isWorkspace
    }

    private let isWorkspace: Bool

    // Resolved once on first use, then cached. Returns nil when dev pods are
    // disabled, source is not a workspace, or no podspecs are found.
    private lazy var devPodFilesProvider: (() -> [Path])? = makeDevPodFilesProvider()

    private func makeDevPodFilesProvider() -> (() -> [Path])? {
        guard isWorkspace, !config.skipDevelopmentPods else { return nil }
        let specs = PodspecReader.findDevelopmentPodspecs(projectRoot: root)
        guard !specs.isEmpty else { return nil }
        let capturedConfig = config
        return { specs.flatMap { PodspecReader.resolveSourceFiles(podspecPath: $0, config: capturedConfig) } }
    }

    func generateDashboard() throws {
        generateMeta()
        generateCodeStats()
        fetchOrphansFileReport()
        fetchEmptyFiles()
    }
    
    func generateMeta() {
        let metadata = ProjectMeta.fetchMetadata(from: xcodeProj.pbxproj)
        print(metadata)
    }
    
    func generateCodeStats() {
        let result = CodeStats.generateCodeStats(
            for: xcodeProj.pbxproj,
            projectRoot: root,
            config: config,
            devPodFiles: devPodFilesProvider
        )
        print(result)
    }

    func fetchOrphansFileReport() {
        let orphanFiles = OrphanFileDetector.detectOrphanedFiles(in: xcodeProj.pbxproj)
        print(orphanFiles)
    }

    func fetchTopNFilesByLines(_ lines: Int) throws {
        var topNConfig = config
        topNConfig.topNCountFor = .line(lines)
        let topNFiles = try CodeStats.generateTopNLargestFiles(
            for: xcodeProj.pbxproj,
            in: root,
            config: topNConfig,
            devPodFiles: devPodFilesProvider
        )
        topNFiles.forEach { print($0) }
    }

    func fetchTopNFilesByWords(_ words: Int) throws {
        var topNConfig = config
        topNConfig.topNCountFor = .word(words)
        let topNFiles = try CodeStats.generateTopNLargestFiles(
            for: xcodeProj.pbxproj,
            in: root,
            config: topNConfig,
            devPodFiles: devPodFilesProvider
        )
        topNFiles.forEach { print($0) }
    }

    func fetchEmptyFiles() {
        let emptyFiles = EmptyFilesCheck.detectEmptyFiles(
            in: xcodeProj.pbxproj,
            projectRoot: root,
            devPodFiles: devPodFilesProvider
        )
        print(emptyFiles)
    }

    func generateMissingFileReport() {
        let missingFilesResult = CodeStats.detectMissingFiles(in: xcodeProj.pbxproj, projectRoot: root)
        print(missingFilesResult)
    }
}
