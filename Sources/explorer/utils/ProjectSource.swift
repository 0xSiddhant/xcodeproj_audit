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

    /// Detects whether the given path refers to an Xcode workspace or project, or contains one.
    ///
    /// This method inspects the provided path in two steps:
    /// 1. If the path itself has a recognized extension, it immediately returns the corresponding case:
    ///    - `.xcworkspace` → `.workspace(path)`
    ///    - `.xcodeproj`   → `.project(path)`
    /// 2. Otherwise, it attempts to auto-detect by searching the directory at `path` for the first matching bundle:
    ///    - Looks for `*.xcworkspace` and returns `.workspace` if found
    ///    - Looks for `*.xcodeproj` and returns `.project` if found
    ///
    /// If neither condition is satisfied, the method throws `ProjectError.notFound` with the original path.
    ///
    /// - Parameter path: The file system `Path` to a workspace/project bundle, or a directory to scan.
    /// - Returns: A `ProjectSource` representing either a workspace or project found at or within `path`.
    /// - Throws: `ProjectError.notFound(path)` if no `.xcworkspace` or `.xcodeproj` can be identified.
    /// - Note:
    ///   - When scanning a directory, only the first matching item (if any) is returned.
    ///   - No existence checks are performed beyond locating matching items; ensure the path is accessible.
    ///   - This method does not resolve symlinks; pass a resolved path if needed.
    public static func detect(at path: Path) throws -> ProjectSource {
        if path.extension == "xcworkspace" { return .workspace(path) }
        if path.extension == "xcodeproj"   { return .project(path) }

        // Auto-detect in directory
        if let ws = path.glob("*.xcworkspace").first  { return .workspace(ws) }
        if let proj = path.glob("*.xcodeproj").first  { return .project(proj) }

        throw ProjectError.notFound(path)
    }
    
    /// Compares two ProjectSource values for equality by matching both their case and associated Path values.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand ProjectSource to compare.
    ///   - rhs: The right-hand ProjectSource to compare.
    /// - Returns: `true` if both values are the same case (`.workspace` or `.project`) and their associated `Path`s are equal; otherwise, `false`.
    /// - Note: A `.workspace` is never considered equal to a `.project`, even if their underlying paths resolve to the same directory.
    public static func == (lhs: ProjectSource, rhs: ProjectSource) -> Bool {
        if case let .workspace(lhsPath) = lhs, case let .workspace(rhsPath) = rhs {
            return lhsPath == rhsPath
        }
        if case let .project(lhsPath) = lhs, case let .project(rhsPath) = rhs {
            return lhsPath == rhsPath
        }
        return false
    }
    
    /// The underlying file system path associated with the project source.
    ///
    /// - For `.workspace`, this is the full `Path` to the `.xcworkspace` bundle.
    /// - For `.project`, this is the full `Path` to the `.xcodeproj` bundle.
    ///
    /// This path does not perform any resolution (e.g., symlinks) or existence checks; it simply
    /// returns the stored path for the current case. Use `fetchRootPath()` if you need the parent
    /// directory of the project source.
    private var path: Path {
        switch self {
        case .workspace(let path):
            return path
        case .project(let path):
            return path
        }
    }
    
    /// Returns the root directory for the selected project source.
    ///
    /// - For a workspace (`.xcworkspace`), this is the parent directory of the workspace file.
    /// - For a project (`.xcodeproj`), this is the parent directory of the project file.
    ///
    /// - Returns: The parent `Path` of the underlying `.xcworkspace` or `.xcodeproj`.
    /// - Throws: Rethrows any underlying errors in future implementations (currently none).
    /// - Note: This does not resolve symlinks or perform existence checks; it purely returns the parent path.
    func fetchRootPath() throws -> Path {
        switch self {
        case .workspace(let path):
            return path.parent()
        case .project(let path):
            return path.parent()
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
