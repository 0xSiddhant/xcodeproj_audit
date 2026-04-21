//
//  MissingFilesResult.swift
//  xcodeproj_audit
//
//  Created by Siddhant Kumar on 18/04/26.
//

import Foundation

struct MissingFilesResult: CustomStringConvertible {
    let missingFiles: [MissingFile]
    let totalScanned: Int

    var duration: TimeInterval? = nil

    var hasHardMissing: Bool { missingFiles.contains { $0.reason == .notOnDisk } }

    var description: String {
        let separator = Terminal.separator()

        guard !missingFiles.isEmpty else {
            let header = Terminal.header("MISSING FILES")
            return """
            \(separator)
            \(withTiming(header))
            \(separator)
            \(Terminal.success("✅ No missing files found."))
            \(Terminal.label("Total scanned :")) \(totalScanned)
            \(separator)
            """
        }

        let fileLines = missingFiles.map { file in
            let icon: String
            let name: String
            switch file.reason {
            case .notOnDisk:
                icon = Terminal.problem("⚠")
                name = Terminal.problem(Terminal.bold(file.fileName))
            case .brokenSymlink:
                icon = Terminal.warning("⚠")
                name = Terminal.warning(Terminal.bold(file.fileName))
            }
            let targets = file.targetNames.isEmpty
                ? Terminal.dim("— not in any build phase")
                : file.targetNames.joined(separator: ", ")
            return """
              \(icon) \(name)
                \(Terminal.label("expected at :")) \(file.expectedPath)
                \(Terminal.label("group       :")) \(file.groupPath)
                \(Terminal.label("in targets  :")) \(targets)
                \(Terminal.label("reason      :")) \(file.reason.description)
            """
        }.joined(separator: "\n\n")

        let countText = "\(missingFiles.count) found"
        let styledCount = hasHardMissing ? Terminal.problem(countText) : Terminal.warning(countText)
        let header = "\(Terminal.header("MISSING FILES")) (\(styledCount))"

        return """
        \(separator)
        \(withTiming(header))
        \(separator)
        \(Terminal.label("Total scanned :")) \(totalScanned)
        \(Terminal.label("Missing       :")) \(missingFiles.count)

        \(fileLines)
        \(separator)
        """
    }

    private func withTiming(_ header: String) -> String {
        guard let duration else { return header }
        return Terminal.appendTiming(to: header, duration: duration)
    }
}

struct MissingFile {
    let fileName:     String
    let expectedPath: String
    let groupPath:    String
    let targetNames:  [String]
    let reason:       MissingReason
}

enum MissingReason: Equatable {
    case notOnDisk          // path resolved but file simply doesn't exist
    case brokenSymlink      // path exists as symlink but target is missing

    var description: String {
        switch self {
        case .notOnDisk:      return "file not found on disk"
        case .brokenSymlink:  return "broken symlink"
        }
    }
}
