# DevOps Module 1: Linux, Bash and Git Workflow

A collaborative workflow built with Linux commands, a Bash backup script and Git.
Practice assignment for Module 1 of DevOps Engineering course.

## Assignment deliverables

| Requirement | Where to find it |
|---|---|
| Repository with a README and a documented branch workflow | This README: [Branch workflow](#branch-workflow) |
| Bash script that backs up a directory and logs its result | [`scripts/backup.sh`](scripts/backup.sh) |
| File permissions demonstration | [`docs/permissions.md`](docs/permissions.md) |
| Process or network diagnostic | [`docs/process-diagnostics.md`](docs/process-diagnostics.md) and [`docs/network-diagnostics.md`](docs/network-diagnostics.md) |
| How a pull request and review reduce integration risk | [`docs/pull-requests.md`](docs/pull-requests.md) |
| Run guide with sample output | [`docs/run-guide.md`](docs/run-guide.md) |

## Project structure

```
.
├── README.md
├── .gitignore
├── scripts/
│   └── backup.sh
└── docs/
    ├── run-guide.md
    ├── permissions.md
    ├── process-diagnostics.md
    ├── network-diagnostics.md
    └── pull-requests.md
```

The script also creates `backups/` and `logs/` when it runs. Both are listed in `.gitignore`, so generated files are never committed.

## Contents

| Path | Description |
|---|---|
| `scripts/backup.sh` | Backs up a directory to a timestamped, compressed archive and logs the result |
| `docs/run-guide.md` | How to run the script and check its output, with sample output |
| `docs/permissions.md` | File permissions demonstration with sample output |
| `docs/process-diagnostics.md` | Inspecting and stopping a running backup |
| `docs/network-diagnostics.md` | Layer-by-layer network troubleshooting |
| `docs/pull-requests.md` | How pull requests and review reduce integration risk |

## Requirements

- Linux with Bash
- `tar` and `gzip`
- GNU coreutils (the script uses `realpath -m`)
- Git

## Quick start

```bash
git clone https://github.com/ayo-adeboyejo/devops-m01-linux-git-workflow.git
cd devops-m01-linux-git-workflow
./scripts/backup.sh <directory-to-back-up> [destination-directory]
```

- Backups are saved to `backups/` unless a destination is given.
- Each run is logged to `logs/backup.log`.
- Archives are created with owner-only permissions (`600`).

See the [run guide](docs/run-guide.md) for full instructions and sample output.

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Backup completed and verified |
| `1` | Wrong number of arguments |
| `2` | A check failed or the backup could not be created |
| `130` | Backup interrupted; any unfinished archive is removed |

## Branch workflow

`main` always holds working, reviewed code. A GitHub ruleset blocks direct pushes, force pushes and deletion of `main`, so every change arrives through a pull request.

1. Update `main`: `git switch main && git pull`
2. Create a branch: `git switch -c <type>/<short-description>`
3. Commit changes in small, clear steps
4. Push the branch: `git push -u origin <branch-name>`
5. Open a pull request into `main`
6. Review the changes and fix any issues raised
7. Merge with a merge commit, so the branch stays visible in history
8. Delete the branch and update local `main`

### Branch names

| Prefix | Use for | Example |
|---|---|---|
| `feature/` | New functionality | `feature/backup-script` |
| `fix/` | Bug fixes | `fix/quote-paths` |
| `docs/` | Documentation | `docs/run-guide` |

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `chore:` setup and maintenance
- `refactor:` code changes that don't change behaviour

## How this repository was built

Every change after the initial setup went through a pull request, following the workflow above. The [pull request history](https://github.com/ayo-adeboyejo/devops-m01-linux-git-workflow/pulls?q=is%3Apr) shows each change, its description and its review. The commit graph shows the same thing:

```bash
git log --oneline --graph
```
