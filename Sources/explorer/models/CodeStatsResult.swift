//
//  CodeStatsResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import Foundation

struct CodeStatsResult: CustomStringConvertible {
    let totalLines: Int
    let totalWords: Int
    let totalFiles: Int
    let skippedFiles: Int
    let linesByExtension: [String: Int]   // extension → line count
    let wordsByExtension: [String: Int]   // extension → word count
    let filesByExtension: [String: Int]   // extension → file count
    let emptyFileCount: Int
    let emptyFileList: Set<String>

    var duration: TimeInterval? = nil

    var description: String {
        let extStats = linesByExtension.keys.sorted().map { ext in
            let lines = linesByExtension[ext] ?? 0
            let words = wordsByExtension[ext] ?? 0
            let files = filesByExtension[ext] ?? 0
            return "  \(Terminal.cyan(".\(ext)")): \(Terminal.value("\(files)")) files, \(Terminal.value("\(lines)")) lines, \(Terminal.value("\(words)")) words"
        }.joined(separator: "\n")

        var emptyFilesStr = ""
        if !emptyFileList.isEmpty {
            emptyFilesStr = """
            \(Terminal.separator("-", count: 12))
            \(Terminal.label("Empty Files  :"))
                \(emptyFileList.sorted().joined(separator: "\n    "))
            """
        }

        let header = Terminal.header("CODE STATS")
        let headerLine = withTiming(header)

        return """
        \(headerLine)
        \(Terminal.label("Total files  :")) \(Terminal.value("\(totalFiles)")) (\(skippedFiles) skipped)
        \(Terminal.label("Total lines  :")) \(Terminal.value("\(totalLines)"))
        \(Terminal.label("Total words  :")) \(Terminal.value("\(totalWords)"))
        \(Terminal.label("Empty Files  :")) \(Terminal.value("\(emptyFileCount)"))
        \(Terminal.label("By extension :"))
        \(extStats)
        \(emptyFilesStr)
        """
    }

    private func withTiming(_ header: String) -> String {
        guard let duration else { return header }
        return Terminal.appendTiming(to: header, duration: duration)
    }
}

struct TopNFileResult: CustomStringConvertible {
    let file: String
    let lineCount: Int?
    let wordCount: Int?

    var description: String {
        if let lineCount {
            return "    \(Terminal.label("Lines:")) \(Terminal.bold("\(lineCount)")) \t File: \(file)"
        } else if let wordCount {
            return "    \(Terminal.label("Words:")) \(Terminal.bold("\(wordCount)")) \t File: \(file)"
        } else {
            return "Unknown: \(file)"
        }
    }
}
