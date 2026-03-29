//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import Foundation
import XcodeProj
import PathKit

struct OrphanFileDetector {
    private init() { }
    
    /// Scans an Xcode project (PBXProj) to find file references that are not included in any build phase,
    /// commonly referred to as "orphaned files".
    ///
    /// Overview:
    /// - Collects all PBXFileReference entries (everything visible in the Xcode navigator).
    /// - Collects all PBXFileReference UUIDs that are referenced by PBXBuildFile entries
    ///   (i.e., files actually used in build phases such as Sources, Resources, Frameworks, Copy Files).
    /// - Determines orphans by subtracting referenced UUIDs from the full set of file references.
    /// - Filters out non-meaningful items (e.g., folders, project/workspace files, configs, docs).
    /// - Resolves a human-readable group path for each orphan by walking PBXGroup parents.
    ///
    /// Parameters:
    /// - pbxproj: The loaded PBXProj model from XcodeProj representing the project to analyze.
    ///
    /// Returns:
    /// - An `OrphanedFilesResult` containing:
    ///   - `orphanedFiles`: An array of `OrphanedFile` with file path and group path for display.
    ///   - `totalReferenced`: The total number of PBXFileReference entries in the project.
    ///   - `totalInBuildPhase`: The number of file references that are actually referenced by build files.
    ///
    /// Notes:
    /// - Only files with meaningful extensions (e.g., swift, m, mm, cpp, c, h, storyboard, xib, xcassets, etc.)
    ///   are considered; container/metadata/doc files and folders are skipped.
    /// - This function does not check whether files exist on disk; it only inspects project graph references.
    /// - Useful for identifying files present in the navigator but not compiled or copied in any target.
    static func detectOrphanedFiles(
        in pbxproj: PBXProj
    ) -> OrphanedFilesResult {
        
        // Step 1 — collect ALL PBXFileReference UUIDs in the project
        // These are every file visible in the Xcode navigator
        let allFileRefs = pbxproj.fileReferences
        
        // Step 2 — collect all UUIDs that ARE referenced by a PBXBuildFile
        // PBXBuildFile.file → points to a PBXFileReference
        // This covers all build phases: Sources, Resources, Frameworks, CopyFiles
        let referencedUUIDs: Set<String> = Set(
            pbxproj.buildFiles
                .compactMap { $0.file?.uuid }
        )
        
        // Step 3 — any PBXFileReference whose UUID is NOT in referencedUUIDs = orphan
        let orphaned = allFileRefs.filter { ref in
            !referencedUUIDs.contains(ref.uuid)
        }
        
        // Step 4 — filter to code/resource files only
        // skip folders, localization containers, xcassets roots etc.
        let meaningfulOrphans = orphaned.filter { ref in
            guard let path = ref.path else { return false }
            return isMeaningfulFile(path: path)
        }
        
        // Step 5 — resolve group path for each orphan (for display)
        let orphanedFiles = meaningfulOrphans.compactMap { ref -> OrphanedFile? in
            guard let filePath = ref.path else { return nil }
            
            let groupPath = resolveGroupPath(for: ref, in: pbxproj)
            
            return OrphanedFile(
                path:      filePath,
                groupPath: groupPath
            )
        }
        
        return OrphanedFilesResult(
            orphanedFiles:    orphanedFiles,
            totalReferenced:  allFileRefs.count,
            totalInBuildPhase: referencedUUIDs.count
        )
    }
    
    // MARK: - Helpers
    
    /// Files worth flagging as orphaned — skip containers and metadata files
    static private func isMeaningfulFile(
        path: String
    ) -> Bool {
        let ext = Path(path).extension ?? ""
        
        // Types that should always be in a build phase
        let codeExtensions: Set<String> = [
            "swift", "m", "mm", "cpp", "c", "h", "hpp", "metal",
            "storyboard", "xib", "xcdatamodeld", "xcassets",
            "js", "ts", "py"
        ]
        
        // Skip: folders, project files, config files, docs
        let skipExtensions: Set<String> = [
            "xcodeproj", "xcworkspace", "json", "md",
            "txt", "pdf", "resolved", "xcconfig"
        ]
        
        if skipExtensions.contains(ext) { return false }
        if ext.isEmpty { return false }             // likely a folder ref
        return codeExtensions.contains(ext)
    }
    
    /// Walks PBXGroups to build a human-readable path like "NewsApp/Coordinators"
    static private func resolveGroupPath(
        for fileRef: PBXFileReference,
        in pbxproj: PBXProj
    ) -> String {
        
        // Build a lookup: child UUID → parent group
        var parentMap: [String: PBXGroup] = [:]
        for group in pbxproj.groups {
            for child in group.children {
                parentMap[child.uuid] = group
            }
        }
        
        // Walk up the parent chain collecting group names
        var segments: [String] = []
        var current: PBXFileElement = fileRef
        
        while let parent = parentMap[current.uuid] {
            if let name = parent.name ?? parent.path, !name.isEmpty {
                segments.append(name)
            }
            current = parent
        }
        
        return segments.reversed().joined(separator: "/")
    }
}
