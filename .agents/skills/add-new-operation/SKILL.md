---
name: add-new-operation
description: Add a new audit operation to xcodeproj-audit CLI. Use when implementing a new --flag that analyses the Xcode project and prints results to stdout.
---

# Add a New Audit Operation

Every operation follows: `Operation` enum case → `DashboardManager` method → stateless service → result model. Touches exactly 5 files.

## Steps

### 1. Enum case — `Sources/explorer/Configuration/Operation.swift`

```swift
case myNewOperation

case .myNewOperation:
    return "Short description shown in --help"
```

### 2. Result model — `Sources/explorer/models/MyNewResult.swift`

```swift
struct MyNewResult: CustomStringConvertible {
    var description: String { /* formatted output */ }
}
```

### 3. Service — `Sources/explorer/dashboard/Services/MyNewService.swift`

```swift
struct MyNewService {
    private init() {}
    static func run(in pbxproj: PBXProj, projectRoot: Path) -> MyNewResult { ... }
}
```

### 4. DashboardManager method — `Sources/explorer/dashboard/DashboardManager.swift`

```swift
func fetchMyNewResult() {
    print(MyNewService.run(in: xcodeProj.pbxproj, projectRoot: root))
}
```

Add call inside `generateDashboard()` if it belongs in the full report.

### 5. Wire the switch — `Sources/explorer/xcodeproj_audit.swift`

```swift
case .myNewOperation:
    dashboard.fetchMyNewResult()
```

## Verify

```bash
swift build
swift run xcodeproj_audit --path ./SomeApp.xcodeproj --my-new-operation
swift run xcodeproj_audit --help
```
