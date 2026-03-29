//
//  TargetMetadata.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//


import XcodeProj
import PathKit
import Foundation

// MARK: - Target Metadata

struct TargetMetadata {
    let name: String
    let type: String                        // app, framework, tests, extension, etc.
    let bundleID: String?
    let deploymentTarget: String?
    let swiftVersion: String?
    let configurations: [String]            // Debug, Release, ...
    let dependencies: [String]              // other target names this depends on
    let linkedFrameworks: [String]
    let hasSPMDependencies: Bool
}

// MARK: - Project Metadata

struct ProjectMetadata: CustomStringConvertible {
    let projectName: String
    let objectVersion: String
    let swiftVersion: String?               // from project-level build settings
    let deploymentTarget: String?           // from project-level build settings
    let configurations: [String]            // project-level config names
    let targets: [TargetMetadata]
    let spmDependencies: [String]           // XCRemoteSwiftPackageReference names
    let localSPMDependencies: [String]      // XCLocalSwiftPackageReference paths

    // Derived
    var targetCount: Int        { targets.count }
    var testTargets: [TargetMetadata]  { targets.filter { $0.type == "test" } }
    var appTargets: [TargetMetadata]   { targets.filter { $0.type == "app" } }

    var description: String {
        let separator = String(repeating: "─", count: 50)

        let targetLines = targets.map { t in
            """
              ◆ \(t.name) [\(t.type)]
                Bundle ID   : \(t.bundleID        ?? "—")
                Deploy      : \(t.deploymentTarget ?? "—")
                Swift       : \(t.swiftVersion     ?? "—")
                Configs     : \(t.configurations.joined(separator: ", "))
                Depends on  : \(t.dependencies.isEmpty ? "—" : t.dependencies.joined(separator: ", "))
                Frameworks  : \(t.linkedFrameworks.isEmpty ? "—" : t.linkedFrameworks.joined(separator: ", "))
            """
        }.joined(separator: "\n\n")

        let spmLines = spmDependencies.isEmpty
            ? "  —"
            : spmDependencies.map { "  • \($0)" }.joined(separator: "\n")

        let localSPMLines = localSPMDependencies.isEmpty
            ? "  —"
            : localSPMDependencies.map { "  • \($0)" }.joined(separator: "\n")

        return """
        \(separator)
        PROJECT METADATA
        \(separator)
        Name              : \(projectName)
        Object version    : \(objectVersion)
        Swift version     : \(swiftVersion     ?? "—")
        Deployment target : \(deploymentTarget ?? "—")
        Configurations    : \(configurations.joined(separator: ", "))
        Targets           : \(targetCount) total (\(appTargets.count) app, \(testTargets.count) test)

        \(separator)
        TARGETS
        \(separator)
        \(targetLines)

        \(separator)
        SPM DEPENDENCIES (remote)
        \(separator)
        \(spmLines)

        \(separator)
        SPM DEPENDENCIES (local)
        \(separator)
        \(localSPMLines)
        \(separator)
        """
    }
}
