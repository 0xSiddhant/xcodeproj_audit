//
//  DashboardError.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//


enum DashboardError: Error {
    case notOnDisk
    case isBinary
    case unreadable
    case isSymlink          // optionally skip symlinks
}
