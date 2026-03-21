# /sync — Sync main and clean up previous branch

You are an agent operating inside a git repository.

## Pre-flight
1) Run `git status --porcelain`. If there are uncommitted changes, STOP and tell the user to commit/stash/discard first.
2) Identify current branch: `git branch --show-current`. Save it as `<prevBranch>`.

## Fetch
- Run: `git fetch --prune`

## Switch to main and update
- Run: `git checkout main`
- Run: `git pull --ff-only`

## Delete previous local branch
- If `<prevBranch>` is not empty AND `<prevBranch>` is not `main`, delete it locally:
  - `git branch -D <prevBranch>`

## Delete previous remote branch (best effort)
- If `<prevBranch>` is not empty AND `<prevBranch>` is not `main`, try:
  - `git push origin --delete <prevBranch>`
- If that fails because the branch doesn’t exist on origin, ignore the error.

## Output
- Confirm:
  - current branch is `main`
  - `main` is up to date
  - `<prevBranch>` was deleted locally
  - remote delete succeeded or was already deleted