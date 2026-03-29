// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import PathKit
import XcodeProj

@main
struct xcproj_explorer: ParsableCommand {
    @Option(transform: { argument in Path.current + argument })
    var path: Path
    
    mutating func run() throws {
        let source = try ProjectSource.detect(at: path)
        let projects = try source.fetchProjects()
        
        try projects.forEach {
            print($0.path, $0.isVendored)
            let dashboard = DashboardManager(xcodeProj: $0.project)
            try dashboard.generateDashboard()
        }
    }
}
