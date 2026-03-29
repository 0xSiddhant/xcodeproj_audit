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
        projectRoot: Path
    ) -> EmptyFilesResult {
        
        let codeExtensions: Set<String> = [
            "swift", "m", "mm", "cpp", "c", "h", "hpp", "metal"
        ]
        
        let allRefs = pbxproj.fileReferences.filter { ref in
            guard let ext = ref.path.flatMap({ Path($0).extension }) else { return false }
            return codeExtensions.contains(ext)
        }
        
        var emptyFiles: [EmptyFile] = []
        var totalScanned = 0
        
        for ref in allRefs {
            // Resolve full path on disk
            guard let fullPath = try? ref.fullPath(sourceRoot: projectRoot) else { continue }
            
            totalScanned += 1
            let groupPath = Utils.resolveGroupPath(for: ref, in: pbxproj)
            
            // Check 1 — file doesn't exist on disk
            guard FileManager.default.fileExists(atPath: fullPath.string) else {
                emptyFiles.append(EmptyFile(
                    path:      fullPath.string,
                    groupPath: groupPath,
                    reason:    .notOnDisk
                ))
                continue
            }
            
            // Check 2 — zero bytes (fastest check, no file read needed)
            let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath.string)
            let fileSize   = attributes?[.size] as? Int ?? 0
            
            if fileSize == 0 {
                emptyFiles.append(EmptyFile(
                    path:      fullPath.string,
                    groupPath: groupPath,
                    reason:    .zeroBytes
                ))
                continue
            }
            
            // Check 3 — whitespace only (read content only if file has bytes)
            if let content = try? String(contentsOf: fullPath.url, encoding: .utf8) {
                let stripped = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if stripped.isEmpty {
                    emptyFiles.append(EmptyFile(
                        path:      fullPath.string,
                        groupPath: groupPath,
                        reason:    .whitespaceOnly
                    ))
                }
            }
        }
        
        return EmptyFilesResult(
            emptyFiles:   emptyFiles,
            totalScanned: totalScanned
        )
    }
}
