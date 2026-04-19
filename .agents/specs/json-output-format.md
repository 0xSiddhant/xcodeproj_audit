# Spec: `--json` Output Flag

## Problem
Output is human-readable plain text only. No machine-readable format for piping into CI dashboards or scripts.

## Flag
```bash
xcodeproj_audit --path ./MyApp.xcodeproj --detect-missing-files --json
xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report --json
```

`--json` is a global modifier — combinable with any operation flag.

## Requirements
- All result models support JSON serialization alongside existing `CustomStringConvertible`
- Multiple operations with `--json` → single JSON object with one key per operation
- Exit codes unchanged

## Output Shape

Single operation:
```json
{
  "missingFiles": [
    { "path": "Sources/Foo/Bar.swift", "group": "Foo", "targets": ["MyApp"], "reason": "missing" }
  ]
}
```

Dashboard report:
```json
{ "meta": {}, "codeStats": {}, "orphanedFiles": [], "emptyFiles": [] }
```

## Implementation
1. Result models conform to `Encodable`
2. Add `--json` as `@Flag` on `XCProjAudit` (cross-cutting, not an `Operation` case)
3. Pass `outputFormat: OutputFormat` (`.text` / `.json`) into `DashboardManager`
4. Each `DashboardManager` method branches on format: `print(result)` vs `print(jsonEncoded)`
5. Dashboard report collects all results into a wrapper struct and encodes once

## Done When
- `xcodeproj_audit ... --json | jq '.missingFiles | length'` works
- Plain-text output unchanged when `--json` is absent
- `swift test` passes
