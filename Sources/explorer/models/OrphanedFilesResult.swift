//
//  OrphanedFilesResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import Foundation

struct OrphanedFile {
    let path: String        // file path
    let groupPath: String   // logical group path in navigator
}

struct OrphanedFilesResult: CustomStringConvertible {
    let orphanedFiles: [OrphanedFile]
    let totalReferenced: Int       // all PBXFileReferences
    let totalInBuildPhase: Int     // files that ARE in a build phase

    var duration: TimeInterval? = nil

    var description: String {
        let separator = Terminal.separator()

        guard !orphanedFiles.isEmpty else {
            let header = Terminal.header("ORPHANED FILES")
            return """
            \(separator)
            \(withTiming(header))
            \(separator)
            \(Terminal.success("✅ No orphaned files found."))
            \(Terminal.label("Total referenced :")) \(totalReferenced)
            \(Terminal.label("In build phases  :")) \(totalInBuildPhase)
            \(separator)
            """
        }

        let fileLines = orphanedFiles
            .map { "  \(Terminal.warning("⚠")) \(Terminal.yellow($0.path))\n     \(Terminal.label("group:")) \($0.groupPath)" }
            .joined(separator: "\n")

        let countText = "\(orphanedFiles.count) found"
        let header = "\(Terminal.header("ORPHANED FILES")) (\(Terminal.warning(countText)))"

        return """
        \(separator)
        \(withTiming(header))
        \(separator)
        \(Terminal.label("Total referenced :")) \(totalReferenced)
        \(Terminal.label("In build phases  :")) \(totalInBuildPhase)
        \(Terminal.label("Orphaned         :")) \(orphanedFiles.count)

        \(fileLines)
        \(separator)
        """
    }

    private func withTiming(_ header: String) -> String {
        guard let duration else { return header }
        return Terminal.appendTiming(to: header, duration: duration)
    }
}
