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
        generateMeta(showTiming: true)
        generateCodeStats(showTiming: true)
        let missing = generateMissingFileReport(showTiming: true)
        let orphans = fetchOrphansFileReport(showTiming: true)
        let empty = fetchEmptyFiles(showTiming: true)

        let badge = SummaryBadge(
            orphanedCount: orphans.orphanedFiles.count,
            emptyCount: empty.emptyFiles.count,
            missingCount: missing.missingFiles.count,
            hasHardMissing: missing.hasHardMissing
        )
        print(badge)
    }

    @discardableResult
    func generateMeta(showTiming: Bool = false) -> ProjectMetadata {
        let start = Date()
        var metadata = ProjectMeta.fetchMetadata(from: xcodeProj.pbxproj)
        if showTiming { metadata.duration = Date().timeIntervalSince(start) }
        print(metadata)
        return metadata
    }

    @discardableResult
    func generateCodeStats(showTiming: Bool = false) -> CodeStatsResult {
        let start = Date()
        var result = CodeStats.generateCodeStats(
            for: xcodeProj.pbxproj,
            projectRoot: root,
            config: config,
            devPodFiles: devPodFilesProvider
        )
        if showTiming { result.duration = Date().timeIntervalSince(start) }
        print(result)
        return result
    }

    @discardableResult
    func fetchOrphansFileReport(showTiming: Bool = false) -> OrphanedFilesResult {
        let start = Date()
        var orphanFiles = OrphanFileDetector.detectOrphanedFiles(in: xcodeProj.pbxproj)
        if showTiming { orphanFiles.duration = Date().timeIntervalSince(start) }
        print(orphanFiles)
        return orphanFiles
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

    @discardableResult
    func fetchEmptyFiles(showTiming: Bool = false) -> EmptyFilesResult {
        let start = Date()
        var emptyFiles = EmptyFilesCheck.detectEmptyFiles(
            in: xcodeProj.pbxproj,
            projectRoot: root,
            devPodFiles: devPodFilesProvider
        )
        if showTiming { emptyFiles.duration = Date().timeIntervalSince(start) }
        print(emptyFiles)
        return emptyFiles
    }

    @discardableResult
    func generateMissingFileReport(showTiming: Bool = false) -> MissingFilesResult {
        let start = Date()
        var result = CodeStats.detectMissingFiles(in: xcodeProj.pbxproj, projectRoot: root)
        if showTiming { result.duration = Date().timeIntervalSince(start) }
        print(result)
        return result
    }
}
