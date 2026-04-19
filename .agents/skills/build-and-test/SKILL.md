---
name: build-and-test
description: Build and run xcodeproj-audit locally for development and testing. Use when verifying changes, running the tool against a real Xcode project, or executing the test suite.
---

# Build and Test

## Build
```bash
swift build               # debug
swift build -c release    # release — .build/release/xcodeproj_audit
```

## Test
```bash
swift test    # Tests/xcodeproj_audit_test.swift
```

## Run
```bash
swift run xcodeproj_audit --path /path/to/MyApp.xcodeproj --generate-dashboard-report
swift run xcodeproj_audit --path /path/to/MyApp.xcworkspace --generate-dashboard-report

# Individual flags
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-meta
swift run xcodeproj_audit --path ./MyApp.xcodeproj --detect-missing-files
swift run xcodeproj_audit --path ./MyApp.xcodeproj --detect-orphaned-files
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-code-stats
swift run xcodeproj_audit --path ./MyApp.xcodeproj --empty-files
swift run xcodeproj_audit --path ./MyApp.xcworkspace --generate-code-stats --no-pods
swift run xcodeproj_audit --path ./MyApp.xcodeproj --n-largest-files-by-lines 10
```

## Help / Version
```bash
swift run xcodeproj_audit --help
swift run xcodeproj_audit --version
```
