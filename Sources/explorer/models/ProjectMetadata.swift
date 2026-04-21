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

    var duration: TimeInterval? = nil

    // Derived
    var targetCount: Int        { targets.count }
    var testTargets: [TargetMetadata]  { targets.filter { $0.type == "test" } }
    var appTargets: [TargetMetadata]   { targets.filter { $0.type == "app" } }

    var description: String {
        let separator = Terminal.separator()
        let dash = Terminal.dim("—")

        let targetLines = targets.map { t in
            let head = "  \(Terminal.cyan("◆")) \(Terminal.bold(t.name)) [\(t.type)]"
            let rows = [
                "    \(Terminal.label("Bundle ID   :")) \(t.bundleID        ?? dash)",
                "    \(Terminal.label("Deploy      :")) \(t.deploymentTarget ?? dash)",
                "    \(Terminal.label("Swift       :")) \(t.swiftVersion     ?? dash)",
                "    \(Terminal.label("Configs     :")) \(t.configurations.joined(separator: ", "))",
                "    \(Terminal.label("Depends on  :")) \(t.dependencies.isEmpty ? dash : t.dependencies.joined(separator: ", "))",
                "    \(Terminal.label("Frameworks  :")) \(t.linkedFrameworks.isEmpty ? dash : t.linkedFrameworks.joined(separator: ", "))"
            ]
            return ([head] + rows).joined(separator: "\n")
        }.joined(separator: "\n\n")

        let spmLines = spmDependencies.isEmpty
            ? "  \(dash)"
            : spmDependencies.map { "  \(Terminal.cyan("•")) \($0)" }.joined(separator: "\n")

        let localSPMLines = localSPMDependencies.isEmpty
            ? "  \(dash)"
            : localSPMDependencies.map { "  \(Terminal.cyan("•")) \($0)" }.joined(separator: "\n")

        let header = Terminal.header("PROJECT METADATA")
        return """
        \(separator)
        \(withTiming(header))
        \(separator)
        \(Terminal.label("Name              :")) \(projectName)
        \(Terminal.label("Object version    :")) \(objectVersion)
        \(Terminal.label("Swift version     :")) \(swiftVersion     ?? dash)
        \(Terminal.label("Deployment target :")) \(deploymentTarget ?? dash)
        \(Terminal.label("Configurations    :")) \(configurations.joined(separator: ", "))
        \(Terminal.label("Targets           :")) \(targetCount) total (\(appTargets.count) app, \(testTargets.count) test)

        \(separator)
        \(Terminal.header("TARGETS"))
        \(separator)
        \(targetLines)

        \(separator)
        \(Terminal.header("SPM DEPENDENCIES (remote)"))
        \(separator)
        \(spmLines)

        \(separator)
        \(Terminal.header("SPM DEPENDENCIES (local)"))
        \(separator)
        \(localSPMLines)
        \(separator)
        """
    }

    private func withTiming(_ header: String) -> String {
        guard let duration else { return header }
        return Terminal.appendTiming(to: header, duration: duration)
    }
}
