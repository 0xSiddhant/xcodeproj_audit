# XcodeProj Library — Key APIs

Uses [tuist/XcodeProj](https://github.com/tuist/XcodeProj) ≥ 8.12.0 and PathKit for all path operations.

## Load

```swift
let xcodeProj = try XcodeProj(path: path)   // .xcodeproj
let pbxproj: PBXProj = xcodeProj.pbxproj

let workspace = try XCWorkspace(path: path)  // .xcworkspace
workspace.data.children                      // [XCWorkspaceDataElement]
```

## Key Types

| Type | Represents |
|---|---|
| `PBXProj` | Parsed `.pbxproj` — root of all project data |
| `PBXNativeTarget` | App, framework, extension, or test target |
| `PBXBuildFile` | File reference assigned to a build phase |
| `PBXFileReference` | File known to the project navigator |
| `PBXGroup` | Navigator folder group |
| `PBXVariantGroup` | Localized file group |
| `XCBuildConfiguration` | Named build configuration (Debug/Release) |
| `PBXTargetDependency` | Declared dependency between two targets |
| `XCSwiftPackageProductDependency` | SPM package dependency on a target |

## Common Patterns

```swift
pbxproj.nativeTargets                                          // [PBXNativeTarget]
pbxproj.fileReferences                                         // [PBXFileReference]
try fileRef.fullPath(sourceRoot: projectRoot)                  // absolute Path

target.buildPhases / .sourcesBuildPhase / .resourcesBuildPhase
target.sourcesBuildPhase?.files?.compactMap { $0.file as? PBXFileReference }

target.dependencies.compactMap { $0.target }                   // [PBXNativeTarget]
target.packageProductDependencies.map { $0.productName }       // [String]

config.buildSettings                                           // [String: Any]
```

## Xcode 16 — Filesystem-Synchronized Groups

`PBXFileSystemSynchronizedRootGroup` mirrors the filesystem automatically — files in these groups may not appear as individual `PBXFileReference` entries. Account for this when walking file references to avoid false orphaned/missing results.

## PathKit

```swift
path.exists / .isDirectory / .extension / .parent()
path.glob("*.swift")
path + "subdir"
```
