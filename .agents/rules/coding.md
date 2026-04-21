# Coding Rules

## Architecture
- `DashboardManager` is the sole orchestrator — services must never call each other directly
- Services are stateless structs with static methods only — no stored properties, no `init`
- All CLI output goes through `print(result)` on the result model — never print inside a service
- Result models must conform to `CustomStringConvertible` — `description` is the output contract

## Adding Code
- New operation requires changes in exactly 5 places — see `.agents/skills/add-new-operation/SKILL.md`
- Dev pod file resolution must stay lazy — only resolve when a service actually needs the files
- New flags go in `Operation` enum as `EnumerableFlag` cases — do not add ad-hoc `@Flag` to `XCProjAudit` unless cross-cutting (like `--no-pods`)

## CLI Constraints
- `--generate-dashboard-report` and individual operation flags are mutually exclusive
- `--path` is required for all operations; `--help` and `--version` are the only exceptions

## Output
- All styled terminal output goes through `Terminal` helpers in `utils/Terminal.swift` — never emit raw ANSI escape codes from other files
- Respect `Terminal.isColorEnabled` — it automatically strips colour for `NO_COLOR`, non-TTY pipes, `TERM=dumb`, and `--no-color`

## Never
- Edit the version string in `xcodeproj_audit.swift` — rewritten by release CI before every tag
- Modify `release.yml` without explicit instruction
- Add state to service structs — pass shared data as parameters instead
- Skip vendored project filtering in `ProjectSource.fetchProjects()`
