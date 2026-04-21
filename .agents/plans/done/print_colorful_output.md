# Plan: Colorful Terminal Output

> Before writing any code, follow the mandatory branch + PR workflow in `.agents/rules/git.md`.

## Context

All dashboard output is plain text. `Updater.swift` has inline ANSI codes as private constants — not reusable. Goal: centralize color into one utility, inject it across all model outputs, and handle edge cases properly.

---

## New File: `Sources/explorer/utils/Terminal.swift`

Enum namespace with static methods — matches existing stateless utility pattern.

```swift
enum Terminal {
    // ANSI primitives
    static func red(_ s: String) -> String
    static func green(_ s: String) -> String
    static func yellow(_ s: String) -> String
    static func cyan(_ s: String) -> String
    static func bold(_ s: String) -> String
    static func dim(_ s: String) -> String

    // Semantic helpers
    static func header(_ s: String) -> String    // bold
    static func success(_ s: String) -> String   // green
    static func warning(_ s: String) -> String   // yellow
    static func problem(_ s: String) -> String   // red
    static func label(_ s: String) -> String     // dim
    static func value(_ s: String) -> String     // bold
    static func separator(_ char: String = "─", count: Int = 50) -> String  // dim

    static var isColorEnabled: Bool
}
```

`isColorEnabled` returns false when:
- `NO_COLOR` env var is set (no-color.org standard)
- `isatty(STDOUT_FILENO) == 0` (piped/redirected)
- `TERM == "dumb"` (CI / dumb terminals)
- `DashboardConfig.noColor == true` (see `--no-color` flag below)

---

## Files to Modify

### `Sources/explorer/utils/Updater.swift`
Remove private inline ANSI constants (lines 7–10), replace 7 usages with `Terminal.red/green/yellow()`.

### `Sources/explorer/models/ProjectMetadata.swift`
| Element | Style |
|---|---|
| Separator lines | `Terminal.separator()` |
| Section headers (PROJECT METADATA, TARGETS, SPM DEPENDENCIES) | `Terminal.header()` |
| Key labels ("Name", "Bundle ID", etc.) | `Terminal.label()` |
| Target name after ◆ | `Terminal.bold()` |
| ◆ and • bullets | `Terminal.cyan()` |
| Em-dash (—) for missing values | `Terminal.dim()` |

### `Sources/explorer/models/OrphanedFilesResult.swift`
| Element | Style |
|---|---|
| Separator lines | `Terminal.separator()` |
| Header | `Terminal.header()` |
| Count (N found) | `Terminal.warning()` if > 0 |
| ✅ clean message | `Terminal.success()` |
| ⚠ per orphan | `Terminal.warning()` |
| File paths | `Terminal.yellow()` |
| "group:" label | `Terminal.label()` |

### `Sources/explorer/models/EmptyFilesResult.swift`
| Element | Style |
|---|---|
| Separator lines | `Terminal.separator()` |
| Header | `Terminal.header()` |
| Count | `Terminal.warning()` if > 0 |
| ✅ clean message | `Terminal.success()` |
| ⚠ per file | `Terminal.warning()` |
| reason labels/values | `Terminal.label()` / `Terminal.dim()` |

### `Sources/explorer/models/MissingFilesResult.swift`
| Element | Style |
|---|---|
| Separator lines | `Terminal.separator()` |
| Header | `Terminal.header()` |
| Count | `Terminal.problem()` if > 0 (red — more severe than orphaned) |
| ✅ clean message | `Terminal.success()` |
| ⚠ per file | severity-split (see Additional C below) |
| File name | `Terminal.bold()` |
| "expected at", "group", "in targets", "reason" labels | `Terminal.label()` |

### `Sources/explorer/models/CodeStatsResult.swift`
| Element | Style |
|---|---|
| Labels ("Total files", "Total lines", etc.) | `Terminal.label()` |
| Numbers | `Terminal.value()` |
| Extension names (.swift, .m) | `Terminal.cyan()` |
| Internal separator | `Terminal.separator()` |

### `Sources/explorer/models/TopNFileResult.swift`
| Element | Style |
|---|---|
| "Lines:" / "Words:" label | `Terminal.label()` |
| Count number | `Terminal.bold()` |
| File path | plain |

---

## Edge Cases

1. `NO_COLOR` env var — disable all ANSI (no-color.org standard)
2. Piped output (`| grep`, `> file`) — `isatty(STDOUT_FILENO) == 0` → strip colors
3. `TERM=dumb` — strip colors
4. `--json` flag (future) — must disable colors; wire `Terminal.isColorEnabled` when implementing JSON spec
5. Empty strings — `Terminal.bold("")` returns `""`, not bare ANSI codes
6. Nested styling — avoid; every method appends `\u{1B}[0m` reset to guarantee clean state

---

## Additional Features

### A. `--no-color` CLI flag
Add `@Flag(name: .long) var noColor: Bool = false` to `XCProjAudit`.
Pass into `DashboardConfig.noColor` → checked by `Terminal.isColorEnabled`.

Files: `xcodeproj_audit.swift`, `DashboardConfig.swift`, `Terminal.swift`

### B. Dashboard Summary Badge
After `generateDashboard()` completes, print a final summary (only for `--generate-dashboard-report`):

```
──────────────────────────────────────────────────
AUDIT COMPLETE  ·  2 issues found
  ⚠  3 orphaned files
  ⚠  1 empty file
  ✅  No missing files
──────────────────────────────────────────────────
```

Zero issues → green. Any issues → yellow/red per severity.
`DashboardManager.generateDashboard()` collects counts, passes to new `SummaryBadge` model.

Files: `DashboardManager.swift`, new `Sources/explorer/models/SummaryBadge.swift`

### C. Severity-Split Coloring for Missing Files
Color ⚠ and file name based on `MissingReason`:
- `"file not found on disk"` → `Terminal.problem()` (red)
- `"broken symlink"` → `Terminal.warning()` (yellow)

Header count: red if any hard-missing, yellow if only broken symlinks.

Files: `MissingFilesResult.swift`

### D. Section Timing
Elapsed time shown on each section header during `--generate-dashboard-report`:
```
MISSING FILES (0 found)                      11ms
```

`DashboardManager` wraps each service call with `Date()` start/end. Each result model gets `duration: TimeInterval?` — when set, appended right-aligned in `Terminal.dim()`.

Files: `DashboardManager.swift`, all models in `models/`

---

## Post-Implementation

Once implemented and merged:
1. Move this file to `.agents/plans/done/print_colorful_output.md`
2. Update `.agents/skills/build-and-test/SKILL.md` — add `--no-color` flag and `NO_COLOR=1` usage to the run examples
3. Update `.agents/rules/coding.md` — add a rule that all new output must use `Terminal` helpers, never raw ANSI codes
4. Update `AGENTS.md` — mention `Terminal.swift` in the source layout comments

---

## Verification

```bash
swift build

# Colors on
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report

# Colors stripped (piped)
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report | cat

# Colors stripped (env var)
NO_COLOR=1 swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report

# Colors stripped (flag)
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report --no-color

swift test
```
