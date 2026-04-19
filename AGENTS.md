# xcodeproj-audit

A macOS CLI tool written in Swift that audits Xcode projects — detecting missing/orphaned files, analyzing code statistics, and extracting project metadata from `.xcodeproj` and `.xcworkspace` files.

## Project Basics

- **Language:** Swift 5.9+, Swift Package Manager
- **Platform:** macOS 13+
- **Binary name:** `xcodeproj_audit`
- **Entry point:** `Sources/explorer/xcodeproj_audit.swift` — `@main struct XCProjAudit: ParsableCommand`
- **Dependencies:** `swift-argument-parser`, `XcodeProj` (tuist/XcodeProj ≥ 8.12.0)

## Source Layout

```
Sources/explorer/
├── xcodeproj_audit.swift          # CLI entry point, argument parsing, orchestration
├── Configuration/
│   ├── Operation.swift            # EnumerableFlag enum — maps CLI flags to operations
│   └── Update.swift               # `update` subcommand — self-update via GitHub releases
├── dashboard/
│   ├── DashboardManager.swift     # Orchestrator — calls services, manages dev pod lazy init
│   ├── DashboardConfig.swift      # Config struct (included extensions, skip pods, topN mode)
│   ├── DashboardError.swift
│   └── Services/
│       ├── ProjectMeta.swift      # --generate-meta
│       ├── CodeStats.swift        # --generate-code-stats, --detect-missing-files, topN files
│       ├── OrphanFileDetector.swift  # --detect-orphaned-files
│       └── EmptyFilesCheck.swift  # --empty-files
├── models/
│   ├── ProjectMetadata.swift
│   ├── CodeStatsResult.swift
│   ├── MissingFilesResult.swift
│   ├── OrphanedFilesResult.swift
│   ├── EmptyFilesResult.swift
│   └── LoadedProject.swift
└── utils/
    ├── ProjectSource.swift        # Detects .xcworkspace vs .xcodeproj, loads projects
    ├── PodspecReader.swift        # Finds dev podspecs, resolves source_files globs
    ├── Updater.swift
    ├── ProjectError.swift
    └── Utils.swift
Tests/
└── xcodeproj_audit_test.swift
```

## CLI Flags

| Flag | Description |
|---|---|
| `--generate-dashboard-report` | Runs all operations in one shot |
| `--generate-meta` | Project metadata — name, targets, SPM deps, build settings |
| `--generate-code-stats` | Lines, words, file count by extension |
| `--detect-missing-files` | Files referenced in project but absent on disk |
| `--detect-orphaned-files` | Files in navigator not assigned to any build phase |
| `--empty-files` | Source files that are empty or whitespace-only |
| `--n-largest-files-by-lines <n>` | Top N files by line count |
| `--n-largest-files-by-words <n>` | Top N files by word count |
| `--no-pods` | Exclude Development Pods source files from analysis |
| `update` (subcommand) | Self-update to latest GitHub release |

## Deeper Context

- **Rules** (what agents must/must not do): `.agents/rules/`
  - `coding.md` — architecture invariants, stateless services, output contract, forbidden actions
  - `git.md` — branch strategy, commit conventions, forbidden git actions
- **Skills** (step-by-step workflows): `.agents/skills/`
  - `add-new-operation/` — how to add a new `--flag` audit operation end-to-end
  - `build-and-test/` — how to build, run, and test the tool locally
- **Context** (reference material): `.agents/context/`
  - `xcodeproj-api.md` — key XcodeProj library APIs, PathKit usage, Xcode 16 notes
  - `architecture.md` — core invariants, dev pod flow, workspace vs project handling
- **Specs** (features being designed): `.agents/specs/`
  - `json-output-format.md` — spec for adding `--json` machine-readable output
- **Plans** (upcoming features backlog): `.agents/plans/`
  - `dependency-graph.md` — implementation plan for the `--dependency-graph` feature
