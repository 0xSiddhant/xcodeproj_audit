//
//  SummaryBadge.swift
//  xcodeproj_audit
//
//  Final roll-up printed at the end of `--generate-dashboard-report`.
//

struct SummaryBadge: CustomStringConvertible {
    let orphanedCount: Int
    let emptyCount: Int
    let missingCount: Int
    let hasHardMissing: Bool

    var totalIssues: Int { orphanedCount + emptyCount + missingCount }

    var description: String {
        let separator = Terminal.separator()

        let title: String
        if totalIssues == 0 {
            title = Terminal.success(Terminal.bold("AUDIT COMPLETE  ·  No issues found"))
        } else {
            let word = totalIssues == 1 ? "issue" : "issues"
            let count = "\(totalIssues) \(word) found"
            let styled = hasHardMissing ? Terminal.problem(count) : Terminal.warning(count)
            title = "\(Terminal.bold("AUDIT COMPLETE"))  ·  \(styled)"
        }

        var lines: [String] = []
        lines.append(line(icon: orphanedCount > 0 ? "⚠" : "✅",
                          color: orphanedCount > 0 ? Terminal.warning : Terminal.success,
                          text: orphanedCount > 0
                                ? "\(orphanedCount) \(pluralize("orphaned file", orphanedCount))"
                                : "No orphaned files"))

        lines.append(line(icon: emptyCount > 0 ? "⚠" : "✅",
                          color: emptyCount > 0 ? Terminal.warning : Terminal.success,
                          text: emptyCount > 0
                                ? "\(emptyCount) \(pluralize("empty file", emptyCount))"
                                : "No empty files"))

        let missingColor: (String) -> String =
            missingCount == 0 ? Terminal.success : (hasHardMissing ? Terminal.problem : Terminal.warning)
        lines.append(line(icon: missingCount > 0 ? "⚠" : "✅",
                          color: missingColor,
                          text: missingCount > 0
                                ? "\(missingCount) \(pluralize("missing file", missingCount))"
                                : "No missing files"))

        return """
        \(separator)
        \(title)
        \(lines.joined(separator: "\n"))
        \(separator)
        """
    }

    private func line(icon: String, color: (String) -> String, text: String) -> String {
        "  \(color(icon))  \(color(text))"
    }

    private func pluralize(_ word: String, _ n: Int) -> String {
        n == 1 ? word : word + "s"
    }
}
