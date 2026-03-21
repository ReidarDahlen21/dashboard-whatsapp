# /pr-feat — Create PR (feat) to main

You are an agent operating inside a git repository. Create a feature PR against `main` from current working tree changes.

## Pre-flight
1) Run `git status --porcelain`. If there are no changes, respond: "No changes to commit."
2) Ensure working tree is not in the middle of a merge/rebase. If it is, stop and explain.
3) Identify repo remote:
   - `git remote -v`

## Determine PR scope
1) Run `git diff --stat` and `git diff`.
2) Write a short summary (1–3 bullets) of what changed.

## Branch name (always feat)
1) Create a concise slug from the summary: use lowercase, dash-separated.
2) Branch format: `feat/<slug>`.

## Create branch
- Get current branch: `git branch --show-current`
- If currently on `main`, create and checkout the branch:
  - `git checkout -b feat/<slug>`
- If currently on another branch:
  - If it already matches `feat/*`, keep it and reuse its name as `<branchName>`.
  - Otherwise create a new branch from current HEAD:
    - `git checkout -b feat/<slug>`
- Set `<branchName>` to the current branch name.

## Commit
1) Stage all changes:
   - `git add -A`
2) Show staged scope:
   - `git diff --cached --stat`
   - `git diff --cached`
3) Save current HEAD before commit:
   - `git rev-parse --short HEAD`
4) Create commit message:
   - Title: `feat: <short summary>`
   - Body: 2–6 bullets with key changes (max ~80 chars per line)
5) Commit:
   - `git commit -m "<title>" -m "<body>"`
6) Verify the commit actually happened:
   - `git rev-parse --short HEAD`
   - `git log --oneline -1`
   - `git status --porcelain`
7) If HEAD did not change, or if staged changes remain after commit, stop and explain that the commit did not complete successfully.

## Push
1) Push:
   - `git push -u origin <branchName>`
2) Verify remote branch exists and includes current HEAD:
   - `git ls-remote --heads origin <branchName>`
3) If push verification fails, stop and explain instead of pretending the PR is ready.

## Create PR (best effort with GitHub CLI)
1) Check if `gh` is available:
   - `gh --version`

2) If `gh` is available:
   - First, check if a PR already exists for this branch:
     - `gh pr view <branchName> --json url -q .url`
     - If it returns a URL, print it and stop.

   - Verify that the branch is ahead of `main`:
     - `git log --oneline main..HEAD`
     - If this returns no commits, stop and explain:
       "Branch is identical to main. No PR can be created."

   - Otherwise create PR:
     - `gh pr create --base main --head <branchName> --title "<title>" --body "<body>"`

   - Print the PR URL.

3) If `gh` is NOT available or PR creation fails:
   - Print a manual PR URL in this format:
     - `https://github.com/<owner>/<repo>/pull/new/<branchName>`
   - Derive `<owner>/<repo>` from the `origin` remote if possible. If not possible, still print a fallback message.

## Output
- Print:
  - branch name
  - commit SHA (short): `git rev-parse --short HEAD`
  - PR URL (gh-created or manual)
- Next step: "Merge it on GitHub, then run /sync to update main and clean branches."