//
//  ProjectError.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import Foundation
import PathKit

enum ProjectError: Error, LocalizedError, CustomStringConvertible {
    case notFound(_ path: Path)
    case workspaceNotFound(Path)
    case failedToLoadProject(Path, Error)
    case topNFileFailedProcessing
    
    var errorDescription: String? {
        switch self {
        case .notFound(let path):
            return "Project not found at \(path.string)"
        case .workspaceNotFound(let path):
            return "No .xcworkspace found at: \(path)"
        case .failedToLoadProject(let path, let error):
            return "Failed to load project at \(path): \(error)"
        case .topNFileFailedProcessing:
            return "Failed to get/parse number for top N file"
        }
    }
    
    var description: String {
        self.localizedDescription
    }
}
