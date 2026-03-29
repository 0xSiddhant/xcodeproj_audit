//
//  ProjectSource.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import PathKit
import XcodeProj

public enum ProjectSource: Equatable {
    case workspace(Path)
    case project(Path)

    public static func detect(at path: Path) throws -> ProjectSource {
        if path.extension == "xcworkspace" { return .workspace(path) }
        if path.extension == "xcodeproj"   { return .project(path) }

        // Auto-detect in directory
        if let ws = path.glob("*.xcworkspace").first  { return .workspace(ws) }
        if let proj = path.glob("*.xcodeproj").first  { return .project(proj) }

        throw ProjectError.notFound(path)
    }
    
    public static func == (lhs: ProjectSource, rhs: ProjectSource) -> Bool {
        if case let .workspace(lhsPath) = lhs, case let .workspace(rhsPath) = rhs {
            return lhsPath == rhsPath
        }
        if case let .project(lhsPath) = lhs, case let .project(rhsPath) = rhs {
            return lhsPath == rhsPath
        }
        return false
    }
    
    private var path: Path {
        switch self {
        case .workspace(let path):
            return path
        case .project(let path):
            return path
        }
    }
    // MARK: - Fetch
    /// Fetches all .xcodeproj files referenced in a .xcworkspace,
    /// optionally skipping vendored (Pods, Carthage, SPM) projects.
    ///
    /// - Parameters:
    ///   - workspacePath: Path to the `.xcworkspace` file
    ///   - skipVendored: Whether to skip auto-generated dependency projects (default: true)
    /// - Returns: Array of `LoadedProject` in the order they appear in the workspace
    func fetchProjects(
        skipVendored: Bool = true
    ) throws -> [LoadedProject] {

        var loaded: [LoadedProject] = []
        
        if case let .project(path) = self {
            let project = try XcodeProj(path: path)
            loaded.append(LoadedProject(
                path: path,
                project: project,
                isVendored: isVendored(path: path)
            ))
            return loaded
        }
        
        
        guard case let .workspace(workspacePath) = self,
            workspacePath.exists else {
            throw ProjectError.workspaceNotFound(self.path)
        }

        let workspace = try XCWorkspace(path: workspacePath)
        let workspaceDir = workspacePath.parent()

        // Flatten all file references out of the workspace
        // (workspace refs can be nested inside XCWorkspaceDataGroups)
        let fileRefs = workspace.data.children.flatMap { flatten(reference: $0) }

        for ref in fileRefs {

            // Resolve the absolute path of the referenced .xcodeproj
            let projectPath = resolve(reference: ref, relativeTo: workspaceDir)

            guard projectPath.extension == "xcodeproj" else { continue }

            let vendored = isVendored(path: projectPath)
            if skipVendored && vendored { continue }

            do {
                let project = try XcodeProj(path: projectPath)
                loaded.append(LoadedProject(
                    path: projectPath,
                    project: project,
                    isVendored: vendored
                ))
            } catch {
                throw ProjectError.failedToLoadProject(projectPath, error)
            }
        }

        return loaded
    }

    // MARK: - Helpers

    /// Recursively flattens workspace references (groups can nest file refs)
    private func flatten(reference: XCWorkspaceDataElement) -> [XCWorkspaceDataFileRef] {
        switch reference {
        case .file(let ref):
            return [ref]
        case .group(let group):
            return group.children.flatMap { flatten(reference: $0) }
        }
    }

    /// Resolves a workspace file reference to an absolute Path
    private func resolve(reference: XCWorkspaceDataFileRef, relativeTo base: Path) -> Path {
        let location = reference.location

        // XCWorkspaceDataFileRef.location format:
        // "type:relative/path"
        // "group:MyApp.xcodeproj"
        // "absolute:/Users/.../MyApp.xcodeproj"
        if location.schema.hasPrefix("absolute:") {
            return Path(String(location.path.dropFirst("absolute:".count)))
        } else if location.schema.hasPrefix("group:") {
            return base + String(location.path.dropFirst("group:".count))
        } else if location.schema.hasPrefix("container:") {
            return base + String(location.path.dropFirst("container:".count))
        } else {
            // Fallback — treat as relative
            return base + location.path
        }
    }

    /// Returns true for auto-generated dependency projects that should be skipped
    private func isVendored(path: Path) -> Bool {
        let p = path.string
        return p.contains("Pods/Pods.xcodeproj")        // CocoaPods
            || p.contains("/Pods.xcodeproj")             // CocoaPods (safety net)
            || p.contains("Carthage/Checkouts")          // Carthage
            || p.contains("SourcePackages/checkouts")    // SPM (Xcode-managed)
            || p.contains(".build/checkouts")            // SPM (CLI-managed)
    }

}
