# Pull Requests and Integration Risk

This document explains how pull requests and review reduce integration risk, using evidence from how this repository was built.

## What integration risk is

Integration risk is the danger that merging new work (independently developed features or fixes) will conflict with or break a codebase that already works. Typical causes are:

- Bugs reaching the main branch before anyone has checked the code
- Accidental changes, such as a file overwritten or a line deleted without noticing
- Half-finished work affecting a branch others rely on
- Changes that are hard to trace or undo once they have been merged

Pull requests (PRs) and code reviews directly mitigate this risk by acting as a structured quality gate before any new code enters the main shared codebase.

## The workflow used in this repo

Every change to `main` followed these steps:

1. Create a branch from an up-to-date `main`
2. Commit the code in small, labelled steps
3. Push the branch and open a pull request
4. Review the diff and test the changes
5. Push fixes to the same branch if review finds problems
6. Merge with a merge commit and delete the branch

A GitHub ruleset (`protect-main`) enforces this. Direct pushes to `main` are rejected, force pushes and deletion of `main` are blocked, and every change must arrive through a pull request.

The result is visible in the history below. Each pull request appears as a branch that splits off and joins back:

```text
*   85e0c5b Merge pull request #3 from ayo-adeboyejo/docs/permissions-and-diagnostics
|\
| * b9a74bc docs: add layer-by-layer network diagnostic
| * 684ac59 docs: add process diagnostic for a running backup
| * b5e27a4 docs: add file permissions demonstration
|/
*   70d10b4 Merge pull request #2 from ayo-adeboyejo/feature/backup-script
|\
| * d219edd fix: reject filesystem root as backup source
| * 1275075 docs: add requirements, quick start and exit codes for backup script
| * 117e6f6 feat: clean up unfinished archives on exit or interrupt
| * e8cc0a9 feat: create verified timestamped archive with private permissions
| * e421871 feat: validate source and destination before backup
| * 590b0fd feat: add backup script skeleton with argument parsing and logging
|/
*   61e075b Merge pull request #1 from ayo-adeboyejo/docs/readme
|\
| * 0688666 docs: add README with branch workflow and commit conventions
|/
- feb4195 chore: initialise repository with .gitignore
```

## How each practice reduces risk

### 1. Protected main branch

**Risk reduced:** untested changes going straight into the branch everyone depends on.

The `protect-main` ruleset makes the workflow a rule rather than a guideline. A direct push to `main` is rejected, so no change can skip review, whether by mistake or under time pressure.

### 2. Isolated branches

**Risk reduced:** half-finished work affecting `main`.

The backup script was built over six commits on `feature/backup-script`. During that time `main` stayed unchanged and working. The script only reached `main` once it was complete, tested and reviewed.

### 3. A visible diff

**Risk reduced:** accidental changes slipping through unnoticed.

**Evidence ([PR #2](https://github.com/ayo-adeboyejo/devops-m01-linux-git-workflow/pull/2)):** the README was updated by replacing the whole file with a new version. The PR's diff showed that this also replaced two lines of wording that had been edited separately on `main`. Nothing in the terminal had shown this. It was only visible because the pull request displayed every line removed and added, side by side.

### 4. Review

**Risk reduced:** bugs reaching `main`.

**Evidence ([PR #2](https://github.com/ayo-adeboyejo/devops-m01-linux-git-workflow/pull/2)):** review found that running `./scripts/backup.sh /` broke the script. `basename "/"` returns `/`, which produced an invalid archive name, and the check preventing a backup inside its own source failed for this one path. Every test written up to that point had passed, because none of them had tried `/`. A reviewer reading the code with fresh eyes asked a question the tests had not.

### 5. Fixing before merging

**Risk reduced:** knowingly merging a problem and promising to fix it later.

**Evidence:** the fix (`d219edd fix: reject filesystem root as backup source`) was committed to the same branch and pushed. The pull request updated automatically, the fix was tested in both directions (`/` rejected, a normal directory still backed up), and only then was the PR merged. The bug never existed on `main`.

### 6. Descriptions and testing checklists

**Risk reduced:** reviewers not knowing what to check, or assuming something was tested when it was not.

Each pull request explained what changed, why, and how to review it, with copy-and-paste test commands. PR #2 included a testing checklist, making clear exactly what had been verified. It also listed what was out of scope, so a missing feature could be told apart from an oversight.

### 7. Small, labelled commits

**Risk reduced:** changes that are hard to understand, trace or undo.

Every commit does one thing and is labelled with its type (`feat`, `fix`, `docs`, `chore`). A reviewer can step through PR #2 one commit at a time, and if one change ever needs undoing, it can be reverted on its own without affecting the rest.

## Summary

- Pull requests shift problem-finding to the moment just before merging, when fixes are still cheap and isolated.
- In this repository, review of PR #2 caught an accidental README regression and a bug handling the filesystem root—both were resolved on the branch, so neither ever reached `main`.
- A protected `main`, isolated branches, clear descriptions, and small, labelled commits work together to provide multi-layered protection against integration risk.
