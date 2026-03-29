// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import PathKit
import XcodeProj

@main
struct XCProjExplorer: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "xcproj-explorer",
        abstract: "Explore and analyse Xcode project files.",
        discussion: """
           Analyse an .xcodeproj or .xcworkspace and generate reports.
           
           EXAMPLES:
             swift run xcproj-explorer --path ./MyApp.xcodeproj --generate-dashboard
             swift run xcproj-explorer --path ./MyApp.xcworkspace --generate-meta
             swift run xcproj-explorer --path ./MyApp.xcodeproj --generate-dashboard --generate-meta
           """,
        version: "1.0.0"
    )
    
    // MARK: - Path (required for most operations)
    
    @Option(
        name: .shortAndLong,                        // accepts both -p and --path
        help: "Path to .xcodeproj or .xcworkspace",
        transform: { Path.current + $0 }
    )
    var path: Path?                                  // optional so --help works standalone
    
    // MARK: - Flags (standalone or combined with --path)
    
    @Flag(
        name: .long,
        help: "Print project metadata (name, targets, SPM dependencies, build settings)"
    )
    var generateMeta: Bool = false
    
    @Flag(
        name: .long,
        help: "Generate full code stats dashboard (lines, words, files by type)"
    )
    var generateCodeStats: Bool = false
    
    @Flag(
        name: .long,
        help: "Generate full dashboard report (metadata, code stats, etc.)"
    )
    var generateDashboardReport: Bool = false
    
    @Flag(
        name: .long,
        help: "Detect missing files referenced in project but absent on disk"
    )
    var detectMissingFiles: Bool = false
    
    @Flag(
        name: .long,
        help: "List all orphaned files on disk not referenced by any target"
    )
    var detectOrphanedFiles: Bool = false
    
    @Flag(
        name: .long,
        help: "Show full target dependency graph"
    )
    var dependencyGraph: Bool = false
    
    
    mutating func run() throws {
        // Flags that don't need --path
        // (--help and --version are handled automatically by ArgumentParser)
        
        // All other operations require --path
        let operations: [Bool] = [
            generateMeta,
            generateCodeStats,
            generateDashboardReport,
            detectMissingFiles,
            detectOrphanedFiles,
            dependencyGraph
        ]
        
        // No flags passed at all — print help
        guard operations.contains(true) else {
            print(XCProjExplorer.helpMessage())
            return
        }
        
        // --path is required if any operation flag is passed
        guard let projectPath = path else {
            throw ValidationError(
                "--path is required. Provide a path to .xcodeproj or .xcworkspace"
            )
        }
        guard projectPath.exists else {
            throw ValidationError("No file found at path: \(projectPath.string)")
        }
        
        // Load project once — reuse across all operations
        let source = try ProjectSource.detect(at: projectPath)
        let projectRoot = try source.fetchRootPath()
        let projects = try source.fetchProjects()
        
        try projects.forEach {
            let dashboard = DashboardManager(xcodeProj: $0.project, root: projectRoot)
            
            if generateMeta {
                try dashboard.generateMeta()
            }
            
            if generateCodeStats {
                try dashboard.generateCodeStats()
            }
            
            if generateDashboardReport {
                try dashboard.generateDashboard()
            }
        }
    }
}
