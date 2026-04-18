//
//  DashboardConfig.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//


struct DashboardConfig {
    enum CountType {
        case line(Int)
        case word(Int)
    }

    // MARK: - Shared Extension Sets

    /// Compilable source file extensions (used by CodeStats, EmptyFilesCheck, PodspecReader).
    static let sourceExtensions: Set<String> = [
        "swift", "m", "mm", "cpp", "cc", "c", "h", "hpp", "metal"
    ]

    /// Broader project file extensions including resources and scripts
    /// (used by OrphanFileDetector, MissingFilesCheck).
    static let projectFileExtensions: Set<String> = sourceExtensions.union([
        "storyboard", "xib", "xcdatamodeld", "xcassets", "js", "ts", "py"
    ])

    /// Extensions excluded from orphan detection (metadata, config, docs).
    static let orphanSkipExtensions: Set<String> = [
        "xcodeproj", "xcworkspace", "json", "md", "txt", "pdf", "resolved", "xcconfig"
    ]

    // MARK: - Instance Configuration

    /// Source file extensions to include in analysis.
    /// Matches `sourceExtensions` by default — override to narrow the scope.
    var includedExtensions: Set<String> = [
        "swift", "m", "mm", "cpp", "cc", "c", "h", "hpp", "metal"
    ]

    /// Path fragments to skip (generated/vendor files)
    var excludedPathFragments: [String] = [
        "Pods/", "Carthage/", ".build/", "DerivedData/",
        ".generated.swift", "R.swift", "Mocks.generated"
    ]

    /// When true, skips source files discovered via Development Pods podspecs.
    /// Default is false — dev pods are included in analysis by default.
    var skipDevelopmentPods: Bool = false

    /// Whether to count blank lines
    var countBlankLines: Bool = true

    /// Whether to count comment-only lines
    var countComments: Bool = true
    
    var topNCountFor: CountType?
}
