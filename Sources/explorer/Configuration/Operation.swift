//
//  Operation.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import ArgumentParser

// MARK: - Operation Enum

enum Operation: String, EnumerableFlag, CaseIterable {
    case generateMeta
    case generateCodeStats
    case detectMissingFiles
    case detectOrphanedFiles
    case dependencyGraph
    case emptyFiles

    static func name(for value: Operation) -> NameSpecification {
        .long
    }

    static func help(for value: Operation) -> ArgumentHelp {
        switch value {
        case .generateMeta:
            return "Print project metadata (name, targets, SPM dependencies, build settings)"
        case .generateCodeStats:
            return "Generate full code stats dashboard (lines, words, files by type)"
        case .detectMissingFiles:
            return "Detect missing files referenced in project but absent on disk"
        case .detectOrphanedFiles:
            return "List all orphaned files not referenced by any target"
        case .dependencyGraph:
            return "Show full target dependency graph"
        case .emptyFiles:
            return "Show list of empty files"
        }
    }
}
