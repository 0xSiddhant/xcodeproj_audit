//
//  EmptyFilesResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import Foundation

struct EmptyFilesResult: CustomStringConvertible {
    let emptyFiles: [EmptyFile]
    let totalScanned: Int

    var duration: TimeInterval? = nil

    var description: String {
        let separator = Terminal.separator()

        guard !emptyFiles.isEmpty else {
            let header = Terminal.header("EMPTY FILES")
            return """
            \(separator)
            \(withTiming(header))
            \(separator)
            \(Terminal.success("✅ No empty files found."))
            \(Terminal.label("Total scanned :")) \(totalScanned)
            \(separator)
            """
        }

        let fileLines = emptyFiles
            .map { "  \(Terminal.warning("⚠")) \(Terminal.yellow($0.path))\n     \(Terminal.label("reason :")) \(Terminal.dim($0.reason.description))" }
            .joined(separator: "\n")

        let countText = "\(emptyFiles.count) found"
        let header = "\(Terminal.header("EMPTY FILES")) (\(Terminal.warning(countText)))"

        return """
        \(separator)
        \(withTiming(header))
        \(separator)
        \(Terminal.label("Total scanned :")) \(totalScanned)
        \(Terminal.label("Empty         :")) \(emptyFiles.count)

        \(fileLines)
        \(separator)
        """
    }

    private func withTiming(_ header: String) -> String {
        guard let duration else { return header }
        return Terminal.appendTiming(to: header, duration: duration)
    }
}

struct EmptyFile {
    let path: String
    let groupPath: String
    let reason: EmptyReason
}

enum EmptyReason {
    case zeroBytes              // file size is literally 0
    case whitespaceOnly         // has bytes but only spaces/newlines
    case notOnDisk              // referenced in project but missing on disk

    var description: String {
        switch self {
        case .zeroBytes:     return "zero bytes"
        case .whitespaceOnly: return "whitespace only"
        case .notOnDisk:     return "not found on disk"
        }
    }
}
