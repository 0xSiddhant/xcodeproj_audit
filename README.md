# XC Project Auditor

A Swift command-line tool for auditing and exploring `.xcodeproj` and `.xcworkspace` files. Built on top of [XcodeProj](https://github.com/tuist/XcodeProj) by Tuist.

---

## Features

| Flag | Description |
|---|---|
| `--generate-meta` | Project metadata — name, targets, SPM deps, build settings |
| `--generate-code-stats` | Lines, words, and file count broken down by extension |
| `--detect-missing-files` | Files referenced in the project but absent on disk — shows path, group, affected targets, and reason (missing/broken symlink) |
| `--detect-orphaned-files` | Files in the navigator not assigned to any build phase |
| `--empty-files` | Source files that are empty or whitespace-only — lists file names |
| `--dependency-graph` | Full target dependency graph *(coming soon)* |
| `--generate-dashboard-report` | Runs all of the above in one shot |
| `--n-largest-files-by-lines <n>` | Top N files by line count |
| `--n-largest-files-by-words <n>` | Top N files by word count |

---

## Requirements

- Swift 5.9+
- macOS 13+

---

## Build

```bash
swift build
```

For a release build:

```bash
swift build -c release
```

---

## Run

```bash
# Full audit report
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report

# Individual operations
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-meta
swift run xcodeproj_audit --path ./MyApp.xcodeproj --detect-missing-files
swift run xcodeproj_audit --path ./MyApp.xcodeproj --detect-orphaned-files
swift run xcodeproj_audit --path ./MyApp.xcodeproj --empty-files

# Works with .xcworkspace too
swift run xcodeproj_audit --path ./MyApp.xcworkspace --generate-dashboard-report

# Combine operations
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-meta --generate-code-stats

# Top N largest files
swift run xcodeproj_audit --path ./MyApp.xcodeproj --n-largest-files-by-lines 10
swift run xcodeproj_audit --path ./MyApp.xcodeproj --n-largest-files-by-words 5
```

Run the built binary directly after `swift build -c release`:

```bash
.build/release/xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report
```

---

## Help

```bash
swift run xcodeproj_audit --help
```

---

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) `>= 1.2.0`
- [XcodeProj](https://github.com/tuist/XcodeProj) `>= 8.12.0`

---

## License

MIT
