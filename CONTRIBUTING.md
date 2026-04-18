# Contributing to xcodeproj_audit

## Branch strategy

- **`develop`** — all work goes here. Open PRs against `develop`.
- **`main`** — release branch only. Direct commits and PRs from outside the release process are not accepted.

## Opening a pull request

All PRs targeting `main` must have a title that follows [Conventional Commits](https://www.conventionalcommits.org/). This is enforced by CI — the PR will be blocked until the title is valid.

### Format

```
<type>: <short description>
```

For breaking changes:

```
<type>!: <short description>
```

### Allowed types

| Type | When to use | Version bump |
|------|-------------|-------------|
| `feat` | New user-facing feature | Minor (`0.1.0 → 0.2.0`) |
| `feat!` | Breaking change | Major (`0.1.0 → 1.0.0`) |
| `fix` | Bug fix | Patch (`0.1.0 → 0.1.1`) |
| `chore` | Maintenance, deps, config | Patch |
| `docs` | Documentation only | Patch |
| `refactor` | Code restructure, no behaviour change | Patch |
| `test` | Adding or fixing tests | Patch |
| `perf` | Performance improvement | Patch |
| `ci` | CI/CD changes | Patch |
| `style` | Formatting, whitespace | Patch |
| `revert` | Reverting a previous commit | Patch |

### Examples

```
feat: add dependency graph support
fix: handle broken symlinks in missing files detector
chore: update XcodeProj dependency to 9.0.0
docs: add usage examples to README
feat!: rename --generate-meta flag to --meta
```

## Versioning

The release workflow reads the PR title (via squash merge commit message) and bumps the version automatically:

- `feat` → minor bump
- `feat!` or `BREAKING CHANGE` in body → major bump
- Everything else → patch bump

You do not need to manually update the version anywhere.

## Building locally

```bash
swift build
```

Run with a local project:

```bash
swift run xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report
```

Release build:

```bash
swift build -c release
.build/release/xcodeproj_audit --path ./MyApp.xcodeproj --generate-dashboard-report
```

## Requirements

- Swift 5.9+
- macOS 13+
