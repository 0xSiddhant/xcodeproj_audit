# Plan: Local SPM Package Support

> Before writing any code, follow the mandatory branch + PR workflow in `.agents/rules/git.md`.

## Status
Not started.

## Goal
Include source files from local SPM packages in all analysis operations
(`--generate-code-stats`, `--empty-files`, `--n-largest-files-by-*`),
mirroring exactly how Development Pods are handled today.

---

## How Discovery Works

Local SPM packages are stored directly in the pbxproj as `XCLocalSwiftPackageReference` objects — **not** in `Package.resolved` (which is remote-only). The XcodeProj library exposes them via:

```swift
let localRefs = pbxproj.rootObject?.localPackages ?? []   // [XCLocalSwiftPackageReference]
// Each ref has: ref.relativePath  (always relative to the .xcodeproj directory)
```

Resolving to an absolute path:

```swift
let packageRoot = (projectRoot + ref.relativePath).normalize()
```

Unlike dev pods, local packages can exist in a standalone `.xcodeproj` (not just workspaces), so the `isWorkspace` guard used for pods does **not** apply here.

---

## How Source File Enumeration Works

No manifest parsing. A recursive directory walk under the package root, filtered by `config.includedExtensions` and `config.excludedPathFragments` — the same approach as `PodspecReader.allRegularFiles(under:)`.

---

## Changes (minimal, follows existing devPod pattern exactly)

### 1. NEW — `Sources/explorer/utils/LocalSPMPackageReader.swift`

Two static methods, parallel to `PodspecReader`:

```swift
struct LocalSPMPackageReader {
    private init() {}

    /// Returns resolved absolute roots for all local SPM packages in the pbxproj.
    static func findLocalPackageRoots(pbxproj: PBXProj, projectRoot: Path) -> [Path]

    /// Recursively enumerates source files under a package root,
    /// filtered by config.includedExtensions and config.excludedPathFragments.
    static func resolveSourceFiles(packageRoot: Path, config: DashboardConfig) -> [Path]
}
```

`findLocalPackageRoots` skips any path where `.isDirectory == false` (graceful no-op when the directory doesn't exist on disk).

### 2. MODIFY — `Sources/explorer/dashboard/DashboardConfig.swift`

Add one property after `skipDevelopmentPods`:

```swift
/// When true, skips source files from local SPM packages. Default false.
var skipLocalSPMPackages: Bool = false
```

### 3. MODIFY — `Sources/explorer/dashboard/DashboardManager.swift`

Add a lazy provider mirroring `devPodFilesProvider`:

```swift
private lazy var localSPMFilesProvider: (() -> [Path])? = makeLocalSPMFilesProvider()

private func makeLocalSPMFilesProvider() -> (() -> [Path])? {
    guard !config.skipLocalSPMPackages else { return nil }
    let roots = LocalSPMPackageReader.findLocalPackageRoots(pbxproj: xcodeProj.pbxproj, projectRoot: root)
    guard !roots.isEmpty else { return nil }
    let capturedConfig = config
    return { roots.flatMap { LocalSPMPackageReader.resolveSourceFiles(packageRoot: $0, config: capturedConfig) } }
}
```

Pass `localSPMFiles: localSPMFilesProvider` to the three existing call sites:
- `CodeStats.generateCodeStats`
- `CodeStats.generateTopNLargestFiles` (both `fetchTopNFilesByLines` and `fetchTopNFilesByWords`)
- `EmptyFilesCheck.detectEmptyFiles`

No other changes to `DashboardManager`.

### 4. MODIFY — `Sources/explorer/dashboard/Services/CodeStats.swift`

Add `localSPMFiles: (() -> [Path])? = nil` to `generateCodeStats` and `generateTopNLargestFiles`.  
After the existing dev pod merge block in each method, add the identical block for `localSPMFiles`.

`detectMissingFiles` and `collectPaths` — **no changes** (they work from pbxproj graph references, not path lists).

### 5. MODIFY — `Sources/explorer/dashboard/Services/EmptyFilesCheck.swift`

Add `localSPMFiles: (() -> [Path])? = nil` to `detectEmptyFiles`.  
After the existing dev pod block (lines 57–63), add the identical block:

```swift
if let extra = localSPMFiles?() {
    for fullPath in extra {
        guard DashboardConfig.sourceExtensions.contains(fullPath.extension ?? "") else { continue }
        totalScanned += 1
        checkEmptiness(at: fullPath, groupPath: "Local SPM Packages", into: &emptyFiles)
    }
}
```

### 6. MODIFY — `Sources/explorer/xcodeproj_audit.swift`

Add `--no-spm` flag (parallel to `--no-pods`) and wire to `config.skipLocalSPMPackages`.

---

## Edge Cases

| Scenario | Behaviour |
|---|---|
| No local packages in project | `findLocalPackageRoots` returns `[]` → provider is `nil` → zero overhead |
| Standalone `.xcodeproj` (no workspace) | Supported — local packages live in pbxproj, not workspace XML |
| Package directory missing on disk | Filtered out in `findLocalPackageRoots` via `.isDirectory` check |
| `../Sibling` or `./Local` relative paths | Both resolved correctly via `(root + relativePath).normalize()` |
| Nested `Sources/TargetA/`, `Sources/TargetB/` | Recursive walk handles naturally |
| `--no-spm` combined with `--no-pods` | Independent flags, no interaction |
| Same file in pbxproj + SPM walk | Deduplicated by `seenPaths` set already present in each service |

---

## Done When

- `LocalSPMPackageReader` unit-tested with a fixture package directory
- `--generate-code-stats` counts files from a local package
- `--empty-files` and `--n-largest-files-by-lines` include local package files
- `--no-spm` excludes them
- `swift build` and `swift test` pass
- Works for both `.xcodeproj` and `.xcworkspace` inputs
