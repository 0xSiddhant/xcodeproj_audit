# Git Rules

## Branch Strategy

- `develop` — all active development happens here
- `main` — release branch only; merging triggers CI version bump and binary publish
- Never push directly to `main` — always go through a PR from `develop`

## Implementing a Plan — Mandatory Workflow

Before writing any code from a plan in `.agents/plans/`:

1. **Create a feature branch** from `develop`:
   ```bash
   git checkout develop && git pull
   git checkout -b feat/short-description
   ```
2. **Implement and test** on that branch (`swift build` + `swift test` must pass)
3. **Raise a PR** targeting `develop` — never `main`
4. **Do not merge** — leave the PR for the human to review and approve

Never implement directly on `develop` or `main`.

---

## Commits & Pull Requests

For commit message format, PR title format, allowed types, and versioning rules — see `CONTRIBUTING.md` at the project root. CI enforces the PR title convention; a PR will be blocked until the title is valid.

- Keep commits focused — one logical change per commit
- PRs always target `develop`, never `main` directly
- Merge strategy: squash merge (PR title becomes the commit message — must follow Conventional Commits format)

## What Agents Must Never Do

- Never force-push to `main` or `develop`
- Never use `--no-verify` to skip hooks
- Never amend a commit that has already been pushed
