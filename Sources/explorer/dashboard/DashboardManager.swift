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
    
    init(xcodeProj: XcodeProj, root: Path) {
        self.xcodeProj = xcodeProj
        self.root = root
    }
    
    
    /// Generates and prints a consolidated dashboard for the currently loaded Xcode project.
    /// 
    /// This method performs two major tasks:
    /// - Extracts and prints high-level project metadata (name, configurations, targets, SPM dependencies, etc.).
    /// - Computes and prints code statistics across the project's tracked source files (e.g., total lines, words, file counts),
    ///   using the project root to resolve file references.
    /// 
    /// Behavior:
    /// - Uses `fetchMetadata(from:)` to collect metadata from the project's `PBXProj`.
    /// - Uses `generateDashboard(for:projectRoot:)` to analyze source files and aggregate statistics.
    /// - Outputs both the metadata and the analysis result to standard output.
    /// 
    /// Throws:
    /// - Rethrows any errors that may occur from upstream operations if they are added in the future,
    ///   though the current implementation does not explicitly throw within this method.
    /// 
    /// Notes:
    /// - The method is side-effectful (it prints to the console).
    /// - The analysis respects the default `DashboardConfig` used by `generateDashboard(for:projectRoot:)`.
    /// - Files are resolved via XcodeProj’s path resolution and filtered/deduplicated before analysis.
    /// 
    /// See also:
    /// - `fetchMetadata(from:)`
    /// - `generateDashboard(for:projectRoot:config:)`
    func generateDashboard() throws {
        let metadata = ProjectMeta.fetchMetadata(from: xcodeProj.pbxproj)
        print(metadata)
        
        let fileStats = CodeStats.generateCodeStats(for: xcodeProj.pbxproj, projectRoot: root, config: DashboardConfig())
        print(fileStats)
        
        let orphanFiles = OrphanFileDetector.detectOrphanedFiles(in: xcodeProj.pbxproj)
        print(orphanFiles)
    }
    
    func generateMeta() {
        let metadata = ProjectMeta.fetchMetadata(from: xcodeProj.pbxproj)
        print(metadata)
    }
    
    func generateCodeStats() {
        let result = CodeStats.generateCodeStats(for: xcodeProj.pbxproj, projectRoot: root, config: DashboardConfig())
        print(result)
    }
    
    func fetchOrphansFileReport() {
        let orphanFiles = OrphanFileDetector.detectOrphanedFiles(in: xcodeProj.pbxproj)
        print(orphanFiles)
    }
    
    func fetchTopNFilesByLines(_ lines: Int) throws {
        let topNFiles = try CodeStats.generateTopNLargestFiles(for: xcodeProj.pbxproj, in: root, config: DashboardConfig(topNCountFor: .line(lines)))
        topNFiles.forEach { print($0) }
    }
    
    func fetchTopNFilesByWords(_ words: Int) throws {
        let topNFiles = try CodeStats.generateTopNLargestFiles(for: xcodeProj.pbxproj, in: root, config: DashboardConfig(topNCountFor: .word(words)))
        topNFiles.forEach { print($0) }
    }
}
