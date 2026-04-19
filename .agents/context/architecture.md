# Architecture Reference

> Source layout is in `AGENTS.md`. This file covers invariants and data flow.

## Core Invariants

- `XcodeProj` is loaded once in `xcodeproj_audit.swift` and passed into `DashboardManager` — services never reload it
- Services are stateless structs with static methods — receive all inputs as parameters, return a result model
- `DashboardManager` calls `print(result)` — no service ever calls `print` directly
- `devPodFilesProvider` is a `lazy var` closure — only evaluated when a service requests it

## Dev Pod Flow

```
isWorkspace == true && !config.skipDevelopmentPods
  → PodspecReader.findDevelopmentPodspecs(projectRoot:)   # scans Pods/Development Pods/ for .podspec
  → PodspecReader.resolveSourceFiles(podspecPath:config:)  # parses source_files globs → [Path]
  → passed as devPodFiles: (() -> [Path])? to services
```

Dev pods only exist in `.xcworkspace` inputs. For `.xcodeproj`, `devPodFilesProvider` is always `nil`.

## Workspace vs Project

- `.xcworkspace` → flattens `.xcodeproj` refs from workspace XML, skips vendored (Pods/Carthage/SPM), loads each
- `.xcodeproj` → loaded directly as a single `LoadedProject`

Downstream code always operates on `[LoadedProject]` — source type is transparent after `fetchProjects()`.

## Operation Dispatch

```
CLI flags → validate() → run()
  → ProjectSource.detect() + fetchProjects()
  → DashboardManager init
  → generateDashboard()           (--generate-dashboard-report)
    OR runOperation() per flag    (individual flags)
    AND/OR fetchTopNFilesByLines/Words
```

`runOperation()` is a thin switch — no logic, just dispatch to `DashboardManager` methods.
