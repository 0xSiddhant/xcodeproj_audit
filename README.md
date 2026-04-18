# XC Project Auditor

A macOS CLI tool to audit Xcode projects — detect missing and orphaned files, analyze code statistics, and extract project metadata from `.xcodeproj` and `.xcworkspace` files.

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple&logoColor=white)](https://apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Release](https://img.shields.io/github/v/release/0xSiddhant/xcodeproj_audit)](https://github.com/0xSiddhant/xcodeproj_audit/releases)
[![CI](https://github.com/0xSiddhant/xcodeproj_audit/actions/workflows/release.yml/badge.svg)](https://github.com/0xSiddhant/xcodeproj_audit/actions/workflows/release.yml)

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

## Install

```bash
# Install to /usr/local/bin (requires sudo)
curl -fsSL https://raw.githubusercontent.com/0xSiddhant/xcodeproj_audit/main/install.sh | sudo bash

# Install to ~/.local/bin (no sudo)
curl -fsSL https://raw.githubusercontent.com/0xSiddhant/xcodeproj_audit/main/install.sh | bash -s -- --user
```

The script fetches the latest release from GitHub, downloads the universal macOS binary, and installs it.

### Update

- Re-run the install script to update — it compares versions and skips the download if you're already on the latest

- Or use the built-in update subcommand if the tool is already installed:

    ```bash
    sudo xcodeproj_audit update
    ```

---

## Requirements

- macOS 13+

---

## Build from source

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
