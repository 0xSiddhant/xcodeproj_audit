//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import XcodeProj
import PathKit
import Foundation

struct Utils {
    /// Returns a human‑readable classification for a given Xcode product type.
    ///
    /// This helper maps `PBXProductType` cases (from the XcodeProj library) to concise
    /// strings that describe the kind of build target, making it easier to present or
    /// log target information without exposing the raw enum.
    ///
    /// - Parameter productType: The optional `PBXProductType` to classify.
    /// - Returns: A short, lowercase string describing the target type:
    ///   - `"app"` for application targets
    ///   - `"framework"` for dynamic or static framework targets
    ///   - `"library"` for static or dynamic library targets
    ///   - `"test"` for unit test or UI test bundles
    ///   - `"extension"` for app extensions, including ExtensionKit extensions
    ///   - `"watchOS"` for watchOS app or extension targets
    ///   - `"tvOS"` for tvOS extension targets
    ///   - `"iMessage extension"` for Messages extensions
    ///   - `"XPC service"` for XPC services
    ///   - `"CLI"` for command‑line tools
    ///   - `"unknown"` when the product type is `nil` or not explicitly handled.
    static func resolveTargetType(_ productType: PBXProductType?) -> String {
        switch productType {
        case .application:                    return "app"
        case .framework, .staticFramework:    return "framework"
        case .staticLibrary, .dynamicLibrary: return "library"
        case .unitTestBundle, .uiTestBundle:  return "test"
        case .appExtension,
                .extensionKitExtension:          return "extension"
        case .watch2App, .watch2Extension:    return "watchOS"
        case .tvExtension:                    return "tvOS"
        case .messagesExtension:              return "iMessage extension"
        case .xpcService:                     return "XPC service"
        case .commandLineTool:                return "CLI"
        default:                              return "unknown"
        }
    }
    
    /// Walks PBXGroups to build a human-readable path like "NewsApp/Coordinators"
    static func resolveGroupPath(
        for fileRef: PBXFileReference,
        in pbxproj: PBXProj
    ) -> String {
        
        // Build a lookup: child UUID → parent group
        var parentMap: [String: PBXGroup] = [:]
        for group in pbxproj.groups {
            for child in group.children {
                parentMap[child.uuid] = group
            }
        }
        
        // Walk up the parent chain collecting group names
        var segments: [String] = []
        var current: PBXFileElement = fileRef
        
        while let parent = parentMap[current.uuid] {
            if let name = parent.name ?? parent.path, !name.isEmpty {
                segments.append(name)
            }
            current = parent
        }
        
        return segments.reversed().joined(separator: "/")
    }
    
    /// Checks if a path is a symlink using lstat
    /// FileManager.fileExists follows symlinks so we need this separately
    static func isSymlink(at path: Path) -> Bool {
        var stat = Darwin.stat()
        // lstat does NOT follow symlinks — returns info about the link itself
        return lstat(path.string, &stat) == 0 && (stat.st_mode & S_IFMT) == S_IFLNK
    }
}
