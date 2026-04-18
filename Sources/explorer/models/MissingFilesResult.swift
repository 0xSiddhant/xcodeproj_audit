//
//  MissingFilesResult.swift
//  xcodeproj_audit
//
//  Created by Siddhant Kumar on 18/04/26.
//

struct MissingFilesResult: CustomStringConvertible {
    let missingFiles: [MissingFile]
    let totalScanned: Int

    var description: String {
        let separator = String(repeating: "─", count: 50)

        guard !missingFiles.isEmpty else {
            return """
            \(separator)
            MISSING FILES
            \(separator)
            ✅ No missing files found.
            Total scanned : \(totalScanned)
            \(separator)
            """
        }

        let fileLines = missingFiles.map { file in
            """
              ⚠ \(file.fileName)
                expected at : \(file.expectedPath)
                group       : \(file.groupPath)
                in targets  : \(file.targetNames.isEmpty ? "— not in any build phase" : file.targetNames.joined(separator: ", "))
                reason      : \(file.reason.description)
            """
        }.joined(separator: "\n\n")

        return """
        \(separator)
        MISSING FILES (\(missingFiles.count) found)
        \(separator)
        Total scanned : \(totalScanned)
        Missing       : \(missingFiles.count)

        \(fileLines)
        \(separator)
        """
    }
}

struct MissingFile {
    let fileName:     String
    let expectedPath: String
    let groupPath:    String
    let targetNames:  [String]
    let reason:       MissingReason
}

enum MissingReason {
    case notOnDisk          // path resolved but file simply doesn't exist
    case brokenSymlink      // path exists as symlink but target is missing

    var description: String {
        switch self {
        case .notOnDisk:      return "file not found on disk"
        case .brokenSymlink:  return "broken symlink"
        }
    }
}
