//
//  EmptyFilesResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//


struct EmptyFilesResult: CustomStringConvertible {
    let emptyFiles: [EmptyFile]
    let totalScanned: Int

    var description: String {
        let separator = String(repeating: "─", count: 50)

        guard !emptyFiles.isEmpty else {
            return """
            \(separator)
            EMPTY FILES
            \(separator)
            ✅ No empty files found.
            Total scanned : \(totalScanned)
            \(separator)
            """
        }

        let fileLines = emptyFiles
            .map { "  ⚠ \($0.path)\n     reason : \($0.reason.description)" }
            .joined(separator: "\n")

        return """
        \(separator)
        EMPTY FILES (\(emptyFiles.count) found)
        \(separator)
        Total scanned : \(totalScanned)
        Empty         : \(emptyFiles.count)

        \(fileLines)
        \(separator)
        """
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
