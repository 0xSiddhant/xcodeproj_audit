# Plan: Implement `--dependency-graph`

> Before writing any code, follow the mandatory branch + PR workflow in `.agents/rules/git.md`.

## Status
Stubbed — `case .dependencyGraph: break` in `runOperation()`. Flag exists, does nothing.

## Goal
Print a full target dependency graph — which targets depend on which.

## Output Format
```
Target Dependency Graph
=======================
MyApp
  └── MyFramework
  └── MyKit
        └── CoreUtils
MyAppTests
  └── MyApp
MyFramework
  └── (no dependencies)
```

## Approach

API: `PBXNativeTarget.dependencies` → `[PBXTargetDependency]` → `.target?.name`

```swift
for target in pbxproj.nativeTargets {
    let deps = target.dependencies.compactMap { $0.target?.name }
}
```

1. **Model** — `Sources/explorer/models/DependencyGraphResult.swift`
   - `[String: [String]]` (target → deps), `CustomStringConvertible` renders the tree

2. **Service** — `Sources/explorer/dashboard/Services/DependencyGraph.swift`
   - `static func buildGraph(in pbxproj: PBXProj) -> DependencyGraphResult`

3. **DashboardManager** — `fetchDependencyGraph()`, include in `generateDashboard()`

4. **Wire** — replace `break` with `dashboard.fetchDependencyGraph()` in `runOperation()`

## Edge Cases
- Guard against circular dependencies
- Include aggregate targets or native only — decide before implementing
- Cross-project workspace dependencies — out of scope for v1

## Done When
- Prints non-empty tree for a real project
- Included in `--generate-dashboard-report`
- Works for both `.xcodeproj` and `.xcworkspace`
- `swift build` + `swift test` pass
