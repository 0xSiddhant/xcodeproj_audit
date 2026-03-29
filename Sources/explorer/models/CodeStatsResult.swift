//
//  CodeStatsResult.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//


struct CodeStatsResult: CustomStringConvertible {
    let totalLines: Int
    let totalWords: Int
    let totalFiles: Int
    let skippedFiles: Int
    let linesByExtension: [String: Int]   // extension → line count
    let wordsByExtension: [String: Int]   // extension → word count
    let filesByExtension: [String: Int]   // extension → file count

    var description: String {
        let extStats = linesByExtension.keys.sorted().map { ext in
            let lines = linesByExtension[ext] ?? 0
            let words = wordsByExtension[ext] ?? 0
            let files = filesByExtension[ext] ?? 0
            return "  .\(ext): \(files) files, \(lines) lines, \(words) words"
        }.joined(separator: "\n")

        return """
        Total files  : \(totalFiles) (\(skippedFiles) skipped)
        Total lines  : \(totalLines)
        Total words  : \(totalWords)
        By extension :
        \(extStats)
        """
    }
}

struct TopNFileResult: CustomStringConvertible {
    let file: String
    let lineCount: Int?
    let wordCount: Int?
    
    var description: String {
        if let lineCount {
            return """
                Lines: \(lineCount) \t File: \(file)
                """
        } else if let wordCount {
            return """
                Words: \(wordCount) \t File: \(file)
                """
        } else {
            return "Unknown: \(file)"
        }
    }
}
