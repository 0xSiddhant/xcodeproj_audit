import Foundation
import PathKit

struct PodspecReader {
    private init() {}

    // MARK: - Public API

    /// Finds all .podspec files inside `{projectRoot}/Pods/Development Pods/`
    static func findDevelopmentPodspecs(projectRoot: Path) -> [Path] {
        let devPodsDir = projectRoot + "Pods" + "Development Pods"
        guard devPodsDir.exists, devPodsDir.isDirectory else { return [] }

        return (try? devPodsDir.children())?.flatMap { podDir -> [Path] in
            guard podDir.isDirectory else { return [] }
            return (try? podDir.children())?.filter { $0.extension == "podspec" } ?? []
        } ?? []
    }

    /// Parses `source_files` from a podspec and returns resolved absolute file paths.
    static func resolveSourceFiles(podspecPath: Path, config: DashboardConfig) -> [Path] {
        guard let content = try? podspecPath.read(.utf8) else { return [] }
        let podDir = podspecPath.parent()

        return extractSourceFilePatterns(from: content).flatMap { pattern in
            expandBraces(pattern).flatMap { expanded in
                globFiles(pattern: expanded, base: podDir)
                    .filter { path in
                        guard let ext = path.extension else { return false }
                        return config.includedExtensions.contains(ext)
                    }
            }
        }
    }

    // MARK: - Podspec Parsing

    /// Extracts raw source_files glob patterns from podspec Ruby DSL.
    /// Handles both single string and array forms.
    private static func extractSourceFilePatterns(from content: String) -> [String] {
        // Array form: s.source_files = ['pattern1', 'pattern2']
        if let arrayContent = firstMatch(
            pattern: #"(?:s|spec)\.source_files\s*=\s*\[([^\]]+)\]"#,
            in: content, group: 1
        ) {
            return allMatches(pattern: #"['"]([^'"]+)['"]"#, in: arrayContent, group: 1)
        }

        // Single string form: s.source_files = 'pattern'
        if let single = firstMatch(
            pattern: #"(?:s|spec)\.source_files\s*=\s*['"]([^'"]+)['"]"#,
            in: content, group: 1
        ) {
            return [single]
        }

        return []
    }

    // MARK: - Glob Expansion

    /// Expands `{a,b,c}` brace patterns into separate glob strings.
    /// e.g. `**/*.{swift,h}` → [`**/*.swift`, `**/*.h`]
    private static func expandBraces(_ pattern: String) -> [String] {
        guard let range = pattern.range(of: #"\{([^}]+)\}"#, options: .regularExpression) else {
            return [pattern]
        }
        let braceContent = String(pattern[range]).dropFirst().dropLast()
        let prefix = String(pattern[pattern.startIndex..<range.lowerBound])
        let suffix = String(pattern[range.upperBound...])
        return braceContent.split(separator: ",")
            .map(String.init)
            .flatMap { expandBraces(prefix + $0 + suffix) }
    }

    /// Resolves a glob pattern relative to `base`, handling `**` recursive patterns.
    private static func globFiles(pattern: String, base: Path) -> [Path] {
        guard pattern.contains("**") else {
            // PathKit's glob handles simple patterns including {a,b} via GLOB_BRACE
            return base.glob(pattern)
        }

        // Split on /**/ to get the root dir and the filename pattern
        let parts = pattern.components(separatedBy: "/**/")
        let filePattern = parts.last ?? "*"
        let searchRoot: Path = {
            let prefix = parts.dropLast().joined(separator: "/**/")
            return prefix.isEmpty ? base : base + prefix
        }()

        guard searchRoot.exists else { return [] }

        return allRegularFiles(under: searchRoot)
            .filter { matchesSimpleGlob(filePattern, filename: $0.lastComponent) }
    }

    /// Recursively enumerates all regular files under a directory.
    private static func allRegularFiles(under dir: Path) -> [Path] {
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: dir.string),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return enumerator.compactMap { item -> Path? in
            guard let url = item as? URL,
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
            else { return nil }
            return Path(url.path)
        }
    }

    /// Matches a filename against a simple glob pattern (no recursion, supports `*` and `?`).
    private static func matchesSimpleGlob(_ pattern: String, filename: String) -> Bool {
        let regexStr = "^" + pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".") + "$"
        return (try? NSRegularExpression(pattern: regexStr))
            .flatMap { $0.firstMatch(in: filename, range: NSRange(filename.startIndex..., in: filename)) } != nil
    }

    // MARK: - Regex Helpers

    private static func firstMatch(pattern: String, in string: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(string.startIndex..., in: string)
        guard let match = regex.firstMatch(in: string, range: nsRange),
              let range = Range(match.range(at: group), in: string) else { return nil }
        return String(string[range])
    }

    private static func allMatches(pattern: String, in string: String, group: Int) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(string.startIndex..., in: string)
        return regex.matches(in: string, range: nsRange).compactMap { match in
            guard let range = Range(match.range(at: group), in: string) else { return nil }
            return String(string[range])
        }
    }
}
