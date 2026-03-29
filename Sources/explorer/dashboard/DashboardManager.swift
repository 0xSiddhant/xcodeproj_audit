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
    private struct FileStats {
        let lines: Int
        let words: Int
    }
    
    private let xcodeProj: XcodeProj
    
    init(xcodeProj: XcodeProj) {
        self.xcodeProj = xcodeProj
    }
    
    /// Generates a basic dashboard output. Currently just prints a placeholder.
    func generateDashboard() throws {
        let metadata = fetchMetadata(from: xcodeProj.pbxproj)
        print(metadata)
        
        let result = generateDashboard(for: xcodeProj.pbxproj, projectRoot: xcodeProj.path!.parent())
        print(result)
    }
    
    private func generateDashboard(for project: PBXProj, projectRoot: Path, config: DashboardConfig = DashboardConfig()) -> DashboardResult {
        
        // 1. Collect all file references
        let allRefs = project.fileReferences
        
        // 2. Resolve to absolute paths and deduplicate
        var seenPaths = Set<String>()
        var resolvedPaths: [(path: Path, ext: String)] = []
        
        for ref in allRefs {
            guard
                let ext = ref.path?.split(separator: ".").last.map(String.init),
                config.includedExtensions.contains(ext)
            else { continue }
            
            guard let fullPath = resolve(fileReference: ref, projectRoot: projectRoot)
            else { continue }
            
            guard seenPaths.insert(fullPath.string).inserted else { continue }
            
            guard !config.excludedPathFragments.contains(where: {
                fullPath.string.contains($0)
            }) else { continue }
            
            resolvedPaths.append((path: fullPath, ext: ext))
        }
        
        // 3. Count lines + words across all resolved paths
        var totalLines   = 0
        var totalWords   = 0
        var totalFiles   = 0
        var skippedFiles = 0
        
        var linesByExtension: [String: Int] = [:]
        var wordsByExtension: [String: Int] = [:]
        var filesByExtension: [String: Int] = [:]
        
        for (path, ext) in resolvedPaths {
            switch analyze(file: path, config: config) {
            case .success(let stats):
                totalLines += stats.lines
                totalWords += stats.words
                totalFiles += 1
                
                linesByExtension[ext, default: 0] += stats.lines
                wordsByExtension[ext, default: 0] += stats.words
                filesByExtension[ext, default: 0] += 1
                
            case .failure:
                skippedFiles += 1
            }
        }
        
        return DashboardResult(
            totalLines:       totalLines,
            totalWords:       totalWords,
            totalFiles:       totalFiles,
            skippedFiles:     skippedFiles,
            linesByExtension: linesByExtension,
            wordsByExtension: wordsByExtension,
            filesByExtension: filesByExtension
        )
    }
    
    private func fetchMetadata(from pbxproj: PBXProj) -> ProjectMetadata {
        
        let rootProject = pbxproj.projects.first
        
        let projectName = rootProject?.name
        ?? pbxproj.nativeTargets.first?.name
        ?? "Unknown"
        
        let projectSettings = rootProject?
            .buildConfigurationList?
            .buildConfigurations
            .first { $0.name == "Release" }?
            .buildSettings ?? [:]
        
        let projectSwiftVersion     = projectSettings["SWIFT_VERSION"] as? String
        let projectDeploymentTarget = projectSettings["IPHONEOS_DEPLOYMENT_TARGET"] as? String
        ?? projectSettings["MACOSX_DEPLOYMENT_TARGET"] as? String
        
        let configurations = rootProject?
            .buildConfigurationList?
            .buildConfigurations
            .map(\.name) ?? []
        
        let targets = pbxproj.nativeTargets.map { target -> TargetMetadata in
            let settings = target
                .buildConfigurationList?
                .buildConfigurations
                .first { $0.name == "Release" }?
                .buildSettings ?? [:]
            
            let bundleID        = settings["PRODUCT_BUNDLE_IDENTIFIER"] as? String
            let deployTarget    = settings["IPHONEOS_DEPLOYMENT_TARGET"] as? String
            ?? settings["MACOSX_DEPLOYMENT_TARGET"] as? String
            let swiftVersion    = settings["SWIFT_VERSION"] as? String
            let type            = resolveTargetType(target.productType)
            let configs         = target.buildConfigurationList?
                .buildConfigurations.map(\.name) ?? []
            let dependencies    = target.dependencies.compactMap { $0.target?.name }
            let frameworks      = target.buildPhases
                .compactMap { $0 as? PBXFrameworksBuildPhase }
                .flatMap { $0.files ?? [] }
                .compactMap { $0.file?.path }
                .map { Path($0).lastComponentWithoutExtension }
            let hasSPM          = !(target.packageProductDependencies?.isEmpty ?? true)
            
            return TargetMetadata(
                name:               target.name,
                type:               type,
                bundleID:           bundleID,
                deploymentTarget:   deployTarget,
                swiftVersion:       swiftVersion,
                configurations:     configs,
                dependencies:       dependencies,
                linkedFrameworks:   frameworks,
                hasSPMDependencies: hasSPM
            )
        }
        
        // ✅ Remote SPM deps — via PBXProject.packages
        let spmDependencies = (rootProject?.remotePackages ?? [])
            .compactMap { $0.repositoryURL }
            .map { url -> String in
                Path(url).lastComponentWithoutExtension
            }
        
        // ✅ Local SPM deps — via PBXProject.localPackages
        let localSPMDependencies = (rootProject?.localPackages ?? [])
            .compactMap { $0.relativePath }
        
        return ProjectMetadata(
            projectName:          projectName,
            objectVersion:        String(pbxproj.archiveVersion),   // ✅ UInt → String
            swiftVersion:         projectSwiftVersion,
            deploymentTarget:     projectDeploymentTarget,
            configurations:       configurations,
            targets:              targets,
            spmDependencies:      spmDependencies,
            localSPMDependencies: localSPMDependencies
        )
    }
    
    // MARK: - Helper
    
    private func resolveTargetType(_ productType: PBXProductType?) -> String {
        switch productType {
        case .application:                    return "app"
        case .framework, .staticFramework:    return "framework"
        case .staticLibrary, .dynamicLibrary: return "library"
        case .unitTestBundle, .uiTestBundle:  return "test"
        case .appExtension,
                .extensionKitExtension:          return "extension"
        case .watch2App, .watch2Extension:    return "watchOS"
        case .tvExtension:                    return "tvOS"
        case .messagesExtension:              return "iMessage extension"
        case .xpcService:                     return "XPC service"
        case .commandLineTool:                return "CLI"
        default:                              return "unknown"
        }
    }
    private func analyze(
        file path: Path,
        config: DashboardConfig
    ) -> Result<FileStats, DashboardError> {
        
        guard isReachable(path) else { return .failure(.notOnDisk) }
        guard !path.isSymlink   else { return .failure(.isSymlink) }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path.string)) else {
            return .failure(.unreadable)
        }
        
        if data.contains(0x00) { return .failure(.isBinary) }
        
        let content: String
        if let utf8 = String(data: data, encoding: .utf8) {
            content = utf8
        } else if let latin1 = String(data: data, encoding: .isoLatin1) {
            content = latin1
        } else {
            return .failure(.unreadable)
        }
        
        // — Lines
        var lines = content.components(separatedBy: .newlines)
        if lines.last == "" { lines.removeLast() }  // trailing newline artifact
        
        if !config.countBlankLines {
            lines = lines.filter {
                !$0.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
        
        if !config.countComments {
            lines = lines.filter { line in
                let t = line.trimmingCharacters(in: .whitespaces)
                return !t.hasPrefix("//") && !t.hasPrefix("*") && !t.hasPrefix("/*")
            }
        }
        
        // — Words (split on any whitespace + punctuation, filter empty tokens)
        let words = content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        return .success(FileStats(lines: lines.count, words: words))
    }
    
    // MARK: - Path resolver
    
    private func resolve(
        fileReference: PBXFileReference,
        projectRoot: Path
    ) -> Path? {
        
        // XcodeProj walks the group tree for you and builds the full path
        guard let fullPath = try? fileReference.fullPath(sourceRoot: projectRoot) else {
            return nil
        }
        
        return fullPath.normalize()
    }
    
    private func isReachable(_ path: Path) -> Bool {
        // 1. Expand tilde + normalize
        let expanded = Path(
            (path.string as NSString)
                .expandingTildeInPath
        ).normalize()
        
        // 2. Use FileManager — more reliable than PathKit.exists
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: expanded.string,
            isDirectory: &isDirectory
        )
        
        return exists && !isDirectory.boolValue
    }
}
