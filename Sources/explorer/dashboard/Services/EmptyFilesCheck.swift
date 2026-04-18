//
//  EmptyFilesResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import XcodeProj
import PathKit
import Foundation

struct EmptyFilesCheck {
    private init() { }
    
    static func detectEmptyFiles(
        in pbxproj: PBXProj,
        projectRoot: Path,
        devPodFiles: (() -> [Path])? = nil
    ) -> EmptyFilesResult {

        let allRefs = pbxproj.fileReferences.filter { ref in
            guard let ext = ref.path.flatMap({ Path($0).extension }) else { return false }
            return DashboardConfig.sourceExtensions.contains(ext)
        }

        var emptyFiles: [EmptyFile] = []
        var totalScanned = 0
        var seenPaths = Set<String>()

        for ref in allRefs {
            guard let fullPath = try? ref.fullPath(sourceRoot: projectRoot) else { continue }
            guard seenPaths.insert(fullPath.string).inserted else { continue }
            totalScanned += 1
            checkEmptiness(at: fullPath, groupPath: Utils.resolveGroupPath(for: ref, in: pbxproj), into: &emptyFiles)
        }

        // Xcode 16+ filesystem-synchronized groups — whole directories, no per-file refs
        for target in pbxproj.nativeTargets {
            for group in target.fileSystemSynchronizedGroups ?? [] {
                guard let groupPath = group.path else { continue }
                let dir = (projectRoot + groupPath).normalize()
                guard dir.isDirectory else { continue }

                let files = (try? dir.recursiveChildren()) ?? []
                for file in files {
                    guard let ext = file.extension,
                          DashboardConfig.sourceExtensions.contains(ext),
                          !file.isDirectory,
                          seenPaths.insert(file.string).inserted
                    else { continue }
                    totalScanned += 1
                    checkEmptiness(at: file, groupPath: groupPath, into: &emptyFiles)
                }
            }
        }

        // Also check Development Pods source files
        if let extra = devPodFiles?() {
            for fullPath in extra {
                guard DashboardConfig.sourceExtensions.contains(fullPath.extension ?? "") else { continue }
                totalScanned += 1
                checkEmptiness(at: fullPath, groupPath: "Development Pods", into: &emptyFiles)
            }
        }

        return EmptyFilesResult(emptyFiles: emptyFiles, totalScanned: totalScanned)
    }

    // MARK: - Private

    private static func checkEmptiness(at fullPath: Path, groupPath: String, into emptyFiles: inout [EmptyFile]) {
        // Check 1 — file doesn't exist on disk
        guard FileManager.default.fileExists(atPath: fullPath.string) else {
            emptyFiles.append(EmptyFile(path: fullPath.string, groupPath: groupPath, reason: .notOnDisk))
            return
        }

        // Check 2 — zero bytes (fastest check, no file read needed)
        let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath.string)
        let fileSize   = attributes?[.size] as? Int ?? 0

        if fileSize == 0 {
            emptyFiles.append(EmptyFile(path: fullPath.string, groupPath: groupPath, reason: .zeroBytes))
            return
        }

        // Check 3 — whitespace only (read content only if file has bytes)
        if let content = try? String(contentsOf: fullPath.url, encoding: .utf8) {
            let stripped = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if stripped.isEmpty {
                emptyFiles.append(EmptyFile(path: fullPath.string, groupPath: groupPath, reason: .whitespaceOnly))
            }
        }
    }
}
