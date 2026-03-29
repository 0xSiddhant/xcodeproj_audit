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
    /// Source file extensions to include
    var includedExtensions: Set<String> = [
        "swift", "m", "mm", "cpp", "cc", "c", "h", "hpp", "metal"
    ]

    /// Path fragments to skip (generated/vendor files)
    var excludedPathFragments: [String] = [
        "Pods/", "Carthage/", ".build/", "DerivedData/",
        ".generated.swift", "R.swift", "Mocks.generated"
    ]

    /// Whether to count blank lines
    var countBlankLines: Bool = true

    /// Whether to count comment-only lines
    var countComments: Bool = true
    
    var topNCountFor: CountType?
}
