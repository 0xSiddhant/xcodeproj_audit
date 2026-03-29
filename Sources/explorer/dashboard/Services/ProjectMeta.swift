//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import XcodeProj
import PathKit
import Foundation

struct ProjectMeta {
    private init() { }
    
    /// Gathers high-level metadata about an Xcode project from a loaded PBXProj model.
    /// 
    /// This method inspects the PBXProj to extract:
    /// - Project-level details such as the project name, object/archive version, Swift version,
    ///   deployment target, and available build configurations.
    /// - Per-target details including target type, bundle identifier, deployment target, Swift version,
    ///   configurations, target dependencies, linked frameworks, and whether the target uses SPM.
    /// - Project-wide Swift Package Manager dependencies, both remote (by repository URL) and local (by relative path).
    ///
    /// Behavior and assumptions:
    /// - The "root" PBXProject is taken as the first entry in `pbxproj.projects`.
    /// - The project name falls back to the first native target's name, and finally "Unknown" if none is found.
    /// - Project- and target-level settings are read from the "Release" build configuration when available.
    /// - Deployment target is resolved by checking iOS first (`IPHONEOS_DEPLOYMENT_TARGET`) and then macOS (`MACOSX_DEPLOYMENT_TARGET`).
    /// - Linked frameworks are derived from PBXFrameworksBuildPhase entries and reported without file extensions.
    /// - Remote SPM dependencies are derived from `PBXProject.remotePackages` (repository URLs),
    ///   and local SPM dependencies from `PBXProject.localPackages` (relative paths).
    ///
    /// - Parameter pbxproj: The in-memory representation of an Xcode project, typically loaded via XcodeProj.
    /// - Returns: A ProjectMetadata value that summarizes project-wide and per-target metadata for display or analysis.
    /// - Note: All optional values (e.g., Swift version, deployment target) may be nil if not specified in the project.
    ///         The function is resilient to missing configurations or phases and will provide sensible defaults where possible.
    static func fetchMetadata(
        from pbxproj: PBXProj
    ) -> ProjectMetadata {
        
        let rootProject = pbxproj.projects.first
        
        let projectName = rootProject?.name
        ?? pbxproj.nativeTargets.first?.name
        ?? "Unknown"
        
        let projectSettings = rootProject?
            .buildConfigurationList?
            .buildConfigurations
            .first { $0.name == "Release" }?
            .buildSettings ?? [:]
        
        let projectSwiftVersion     = projectSettings["SWIFT_VERSION"] as? String
        let projectDeploymentTarget = projectSettings["IPHONEOS_DEPLOYMENT_TARGET"] as? String
        ?? projectSettings["MACOSX_DEPLOYMENT_TARGET"] as? String
        
        let configurations = rootProject?
            .buildConfigurationList?
            .buildConfigurations
            .map(\.name) ?? []
        
        let targets = pbxproj.nativeTargets.map { target -> TargetMetadata in
            let settings = target
                .buildConfigurationList?
                .buildConfigurations
                .first { $0.name == "Release" }?
                .buildSettings ?? [:]
            
            let bundleID        = settings["PRODUCT_BUNDLE_IDENTIFIER"] as? String
            let deployTarget    = settings["IPHONEOS_DEPLOYMENT_TARGET"] as? String
            ?? settings["MACOSX_DEPLOYMENT_TARGET"] as? String
            let swiftVersion    = settings["SWIFT_VERSION"] as? String
            let type            = Utils.resolveTargetType(target.productType)
            let configs         = target.buildConfigurationList?
                .buildConfigurations.map(\.name) ?? []
            let dependencies    = target.dependencies.compactMap { $0.target?.name }
            let frameworks      = target.buildPhases
                .compactMap { $0 as? PBXFrameworksBuildPhase }
                .flatMap { $0.files ?? [] }
                .compactMap { $0.file?.path }
                .map { Path($0).lastComponentWithoutExtension }
            let hasSPM          = !(target.packageProductDependencies?.isEmpty ?? true)
            
            return TargetMetadata(
                name:               target.name,
                type:               type,
                bundleID:           bundleID,
                deploymentTarget:   deployTarget,
                swiftVersion:       swiftVersion,
                configurations:     configs,
                dependencies:       dependencies,
                linkedFrameworks:   frameworks,
                hasSPMDependencies: hasSPM
            )
        }
        
        let spmDependencies = (rootProject?.remotePackages ?? [])
            .compactMap { $0.repositoryURL }
            .map { url -> String in
                Path(url).lastComponentWithoutExtension
            }
        
        let localSPMDependencies = (rootProject?.localPackages ?? [])
            .compactMap { $0.relativePath }
        
        return ProjectMetadata(
            projectName:          projectName,
            objectVersion:        String(pbxproj.archiveVersion),
            swiftVersion:         projectSwiftVersion,
            deploymentTarget:     projectDeploymentTarget,
            configurations:       configurations,
            targets:              targets,
            spmDependencies:      spmDependencies,
            localSPMDependencies: localSPMDependencies
        )
    }
}
