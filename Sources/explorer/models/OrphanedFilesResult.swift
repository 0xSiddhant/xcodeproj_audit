//
//  OrphanedFilesResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

struct OrphanedFile {
    let path: String        // file path
    let groupPath: String   // logical group path in navigator
}

struct OrphanedFilesResult: CustomStringConvertible {
    let orphanedFiles: [OrphanedFile]
    let totalReferenced: Int       // all PBXFileReferences
    let totalInBuildPhase: Int     // files that ARE in a build phase

    var description: String {
        let separator = String(repeating: "─", count: 50)

        guard !orphanedFiles.isEmpty else {
            return """
            \(separator)
            ORPHANED FILES
            \(separator)
            ✅ No orphaned files found.
            Total referenced : \(totalReferenced)
            In build phases  : \(totalInBuildPhase)
            \(separator)
            """
        }

        let fileLines = orphanedFiles
            .map { "  ⚠ \($0.path)\n     group: \($0.groupPath)" }
            .joined(separator: "\n")

        return """
        \(separator)
        ORPHANED FILES (\(orphanedFiles.count) found)
        \(separator)
        Total referenced : \(totalReferenced)
        In build phases  : \(totalInBuildPhase)
        Orphaned         : \(orphanedFiles.count)

        \(fileLines)
        \(separator)
        """
    }
}
