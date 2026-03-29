//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import XcodeProj
import Foundation

final class DashboardManager {
    private let xcodeProj: XcodeProj
    
    init(xcodeProj: XcodeProj) {
        self.xcodeProj = xcodeProj
    }
    
    /// Generates a basic dashboard output. Currently just prints a placeholder.
    func generateDashboard() throws {
        for project in xcodeProj.pbxproj.projects {
            try analyzeProjectTargets(project.targets)
            
            print("Project \(project.name):")
            print("\t・\(project.remotePackages.count) remote package(s)")
            print("\t・\(project.localPackages.count) local package(s)")
                print()
        }
    }
    
    private func countLines() { }
    private func countWords() { }
    private func countFiles() { }
    
    private func analyzeProjectTargets(_ targets: [PBXTarget]) throws {
        try targets.forEach { target in
            print("\t・Target \(target.name) \((target.productType?.fileExtension ?? "")):")
            print("\t\t・\(try target.sourceFiles().count) source file(s)")
            print("\t\t・\(try target.resourcesBuildPhase()?.files?.count ?? 0) resource(s)")
            print("\t\t・\(target.packageProductDependencies?.count ?? 0) package dependencies")
            print("\t\t・\(target.dependencies.count) dependencies")
            print("")
        }
    }
}
