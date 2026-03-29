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
        Pass --generate-dashboard-report for a full report, or
        pick individual operations to run selectively.
        
        EXAMPLES:
          swift run xcproj-explorer --path ./MyApp.xcodeproj --generate-dashboard-report
          swift run xcproj-explorer --path ./MyApp.xcodeproj --generate-meta --empty-files
          swift run xcproj-explorer --path ./MyApp.xcodeproj --n-largest-files-by-lines 10
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
    
    @Option(
        name: .long,
        help: "List N largest file by lines count",
        transform: { Int($0)}
    )
    var NLargestFilesByLines: Int?
    
    @Option(
        name: .long,
        help: "List N largest file by words count",
        transform: { Int($0) }
    )
    var NLargestFilesByWords: Int?
    
    // MARK: - Flags (standalone or combined with --path)
    @Flag(
        name: .long,
        help: "Generate full dashboard report — runs all operations in one shot"
    )
    var generateDashboardReport: Bool = false
    
    @Flag(help: "Select individual operations to run")
    var operations: [Operation] = []
    
    mutating func validate() throws {
        // --generate-dashboard-report and individual ops are mutually exclusive
        if generateDashboardReport && !operations.isEmpty {
            throw ValidationError(
                "--generate-dashboard-report already includes all operations. " +
                "Remove individual operation flags when using it."
            )
        }
        
        // Any operation requires --path
        let needsPath = generateDashboardReport
        || !operations.isEmpty
        || NLargestFilesByLines != nil
        || NLargestFilesByWords != nil
        
        if needsPath && path == nil {
            throw ValidationError(
                "--path is required. Provide a path to .xcodeproj or .xcworkspace."
            )
        }
    }
    
    mutating func run() throws {
        // Flags that don't need --path
        // (--help and --version are handled automatically by ArgumentParser)
        
        guard generateDashboardReport
                || !operations.isEmpty
                || NLargestFilesByLines != nil
                || NLargestFilesByWords != nil
        else {
            // No flags passed at all — print help
            print(XCProjExplorer.helpMessage())
            return
        }
        
        
        guard let projectPath = path,
              projectPath.exists else {
            throw ValidationError("No file found at path: \(path?.string ?? "")")
        }
        
        // Load project once — reuse across all operations
        let source = try ProjectSource.detect(at: projectPath)
        let projectRoot = try source.fetchRootPath()
        let projects = try source.fetchProjects()
        
        try projects.forEach {
            let dashboard = DashboardManager(xcodeProj: $0.project, root: projectRoot)
            
            if generateDashboardReport {
                try dashboard.generateDashboard()
                return
            }
            
            // Individual operations
            for operation in operations {
                try runOperation(
                    operation,
                    dashboard: dashboard
                )
            }
            
            if let NLargestFilesByLines {
                try dashboard.fetchTopNFilesByLines(NLargestFilesByLines)
            }
            
            if let NLargestFilesByWords {
                try dashboard.fetchTopNFilesByWords(NLargestFilesByWords)
            }
        }
    }
    
    private func runOperation(
        _ operation: Operation,
        dashboard: DashboardManager,
    ) throws {
        switch operation {
        case .generateMeta:
            dashboard.generateMeta()
            
        case .generateCodeStats:
            dashboard.generateCodeStats()
            
        case .detectMissingFiles:
            break
            
        case .detectOrphanedFiles:
            dashboard.fetchOrphansFileReport()
            
        case .dependencyGraph:
            break
            
        case .emptyFiles:
            dashboard.fetchEmptyFiles()
        }
    }
}
