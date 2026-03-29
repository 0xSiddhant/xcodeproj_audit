//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import XcodeProj
import PathKit
import Foundation

struct CodeStats {
    private struct FileStats {
        let lines: Int
        let words: Int
    }
    
    private init() { }
    /// Generates aggregated code statistics for the given Xcode project.
    /// 
    /// Analyzes text files, filters by config, resolves paths, traverses project file references, and returns aggregate and per-extension stats.
    /// 
    /// Process overview:
    /// - Collects all `PBXFileReference` entries from the project.
    /// - Resolves each reference to an absolute `Path` using `projectRoot`.
    /// - Deduplicates paths and excludes any whose string path contains fragments
    ///   listed in `config.excludedPathFragments`.
    /// - Filters files by extension using `config.includedExtensions`.
    /// - Safely reads each file, skipping symlinks, non-existent, unreadable, or
    ///   binary files.
    /// - Counts lines and words per file, with line counting behavior controlled by:
    ///   - `config.countBlankLines`: whether to include empty/whitespace-only lines
    ///   - `config.countComments`: whether to include comment-only lines (simple
    ///     single-line and block-start heuristics)
    /// - Aggregates totals and per-extension counts (lines, words, files).
    /// 
    /// Parameters:
    /// - for: The loaded `PBXProj` to analyze (from XcodeProj).
    /// - projectRoot: The root directory (`Path`) used to resolve file references
    ///   to absolute paths (typically the directory containing the `.xcodeproj`).
    /// - config: Optional `DashboardConfig` controlling which files to include and
    ///   how lines are counted. Defaults to `DashboardConfig()`.
    /// 
    /// Returns:
    /// A `DashboardResult` containing:
    /// - `totalLines`: Total counted lines across all analyzed files.
    /// - `totalWords`: Total word count across all analyzed files.
    /// - `totalFiles`: Number of files successfully analyzed.
    /// - `skippedFiles`: Number of files that were skipped due to being missing,
    ///   unreadable, symlinks, or binary.
    /// - `linesByExtension`: Mapping of file extension to total line count.
    /// - `wordsByExtension`: Mapping of file extension to total word count.
    /// - `filesByExtension`: Mapping of file extension to number of files analyzed.
    /// 
    /// Notes:
    /// - Paths are normalized and deduplicated to avoid double-counting the same file.
    /// - Comment detection is heuristic (lines starting with `//`, `*`, or `/*`).
    /// - Word counting splits on whitespace and newlines; tokens are not further
    ///   normalized.
    ///
    /// - Returns: A populated `DashboardResult` with aggregate statistics.
    static func generateCodeStats(
        for project: PBXProj,
        projectRoot: Path,
        config: DashboardConfig
    ) -> CodeStatsResult {
        // 1. Collect all file references
        // 2. Resolve to absolute paths and deduplicate
        let resolvedPaths = generatePaths(for: project.fileReferences, in: projectRoot, config: config)
        
        // 3. Count lines + words across all resolved paths
        var totalLines   = 0
        var totalWords   = 0
        var totalFiles   = 0
        var skippedFiles = 0
        
        var linesByExtension: [String: Int] = [:]
        var wordsByExtension: [String: Int] = [:]
        var filesByExtension: [String: Int] = [:]
        
        for (path, ext) in resolvedPaths {
            switch analyze(file: path, config: config) {
            case .success(let stats):
                totalLines += stats.lines
                totalWords += stats.words
                totalFiles += 1
                
                linesByExtension[ext, default: 0] += stats.lines
                wordsByExtension[ext, default: 0] += stats.words
                filesByExtension[ext, default: 0] += 1
                
            case .failure:
                skippedFiles += 1
            }
        }
        
        return CodeStatsResult(
            totalLines:       totalLines,
            totalWords:       totalWords,
            totalFiles:       totalFiles,
            skippedFiles:     skippedFiles,
            linesByExtension: linesByExtension,
            wordsByExtension: wordsByExtension,
            filesByExtension: filesByExtension
        )
    }
    
    static func generateTopNLargestFiles(
        for project: PBXProj,
        in projectRoot: Path,
        config: DashboardConfig
    ) throws -> [TopNFileResult] {
        guard let topNFilter = config.topNCountFor else {
            throw ProjectError.topNFileFailedProcessing
        }
        var result = [TopNFileResult]()
        
        let resolvedPaths = generatePaths(for: project.fileReferences, in: projectRoot, config: config)
        
        for (path, _) in resolvedPaths {
            switch analyze(file: path, config: config) {
            case .success(let fileStat):
                switch topNFilter {
                case .line:
                    result.append(
                        .init(file: path.lastComponent, lineCount: fileStat.lines, wordCount: nil)
                    )
                case .word:
                    result.append(
                        .init(file: path.lastComponent, lineCount: nil, wordCount: fileStat.words)
                    )
                }
            case .failure:
                continue
            }
        }
        
        switch topNFilter {
        case .line(let n):
            result = result
                .sorted { ($0.lineCount ?? 0) > ($1.lineCount ?? 0) }
                .prefix(n)
                .map { $0 }

        case .word(let n):
            result = result
                .sorted { ($0.wordCount ?? 0) > ($1.wordCount ?? 0) }
                .prefix(n)
                .map { $0 }
        }
        
        return result
    }
    
    // MARK: - Helper
    /// Resolves and filters project file references into unique, analyzable file paths.
    ///
    /// This helper:
    /// - Iterates over all PBXFileReference entries from the project.
    /// - Extracts the file extension and filters by `config.includedExtensions`.
    /// - Resolves each reference to an absolute, normalized `Path` using `projectRoot`.
    /// - Deduplicates paths to avoid double-counting the same file.
    /// - Excludes any paths whose string contains fragments listed in `config.excludedPathFragments`.
    ///
    /// Notes:
    /// - Only files with extensions explicitly included in the config are returned.
    /// - Paths are normalized and compared by their string representation for deduplication.
    /// - Exclusion is a substring match against the full path string.
    ///
    /// Parameters:
    /// - allRefs: The array of file references (`PBXFileReference`) gathered from the project.
    /// - projectRoot: The source root used by XcodeProj to resolve full paths (typically the directory containing the `.xcodeproj`).
    /// - config: The dashboard configuration controlling which extensions to include and which path fragments to exclude.
    ///
    /// Returns:
    /// An array of tuples `(path: Path, ext: String)` containing the resolved absolute path and its file extension for each included file.
    static private func generatePaths(
        for allRefs: [PBXFileReference],
        in projectRoot: Path,
        config: DashboardConfig
    ) -> [(path: Path, ext: String)] {
        var seenPaths = Set<String>()
        var resolvedPaths: [(path: Path, ext: String)] = []
        
        for ref in allRefs {
            guard
                let ext = ref.path?.split(separator: ".").last.map(String.init),
                config.includedExtensions.contains(ext)
            else { continue }
            
            guard let fullPath = resolve(fileReference: ref, projectRoot: projectRoot)
            else { continue }
            
            guard seenPaths.insert(fullPath.string).inserted else { continue }
            
            guard !config.excludedPathFragments.contains(where: {
                fullPath.string.contains($0)
            }) else { continue }
            
            resolvedPaths.append((path: fullPath, ext: ext))
        }
        return resolvedPaths
    }
    
    
    // MARK: - Path resolver
    static private func resolve(
        fileReference: PBXFileReference,
        projectRoot: Path
    ) -> Path? {
        
        // XcodeProj walks the group tree for you and builds the full path
        guard let fullPath = try? fileReference.fullPath(sourceRoot: projectRoot) else {
            return nil
        }
        
        return fullPath.normalize()
    }
    
    static private func analyze(
        file path: Path,
        config: DashboardConfig
    ) -> Result<FileStats, DashboardError> {
        
        guard isReachable(path) else { return .failure(.notOnDisk) }
        guard !path.isSymlink   else { return .failure(.isSymlink) }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path.string)) else {
            return .failure(.unreadable)
        }
        
        if data.contains(0x00) { return .failure(.isBinary) }
        
        let content: String
        if let utf8 = String(data: data, encoding: .utf8) {
            content = utf8
        } else if let latin1 = String(data: data, encoding: .isoLatin1) {
            content = latin1
        } else {
            return .failure(.unreadable)
        }
        
        // — Lines
        var lines = content.components(separatedBy: .newlines)
        if lines.last == "" { lines.removeLast() }  // trailing newline artifact
        
        if !config.countBlankLines {
            lines = lines.filter {
                !$0.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
        
        if !config.countComments {
            lines = lines.filter { line in
                let t = line.trimmingCharacters(in: .whitespaces)
                return !t.hasPrefix("//") && !t.hasPrefix("*") && !t.hasPrefix("/*")
            }
        }
        
        // — Words (split on any whitespace + punctuation, filter empty tokens)
        let words = content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        return .success(FileStats(lines: lines.count, words: words))
    }
    
    /// Checks whether a given file path points to a reachable, non-directory file on disk.
    ///
    /// This helper performs a couple of normalization steps and then queries the file system:
    /// - Expands a leading tilde (~) to the current user's home directory.
    /// - Normalizes the path to remove redundant components.
    /// - Uses FileManager to verify that the path exists and is not a directory.
    ///
    /// Notes:
    /// - Symlinks are not resolved here; use `Path.isSymlink` separately if you need to exclude them.
    /// - This function intentionally avoids PathKit's `exists` in favor of `FileManager` for reliability.
    ///
    /// - Parameter path: The PathKit `Path` to validate.
    /// - Returns: `true` if the path exists on disk and is a regular file (not a directory); otherwise, `false`.
    static private func isReachable(
        _ path: Path
    ) -> Bool {
        // 1. Expand tilde + normalize
        let expanded = Path(
            (path.string as NSString)
                .expandingTildeInPath
        ).normalize()
        
        // 2. Use FileManager — more reliable than PathKit.exists
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: expanded.string,
            isDirectory: &isDirectory
        )
        
        return exists && !isDirectory.boolValue
    }
}

