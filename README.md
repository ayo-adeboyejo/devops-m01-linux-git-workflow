# DevOps Module 1: Linux, Bash and Git Workflow

A collaborative workflow built with Linux commands, a Bash backup script and Git.
Practice assignment for Module 1 of DevOps Engineering course.

## Contents

| Path | Description |
|---|---|
| `scripts/backup.sh` | Backs up a directory to a timestamped, compressed archive and logs the result |

## Requirements

- Linux with Bash
- `tar` and `gzip`
- GNU coreutils (the script uses `realpath -m`)
- Git

## Quick start

```bash
git clone git@github.com:ayo-adeboyejo/devops-m01-linux-git-workflow.git
cd devops-m01-linux-git-workflow
./scripts/backup.sh <directory-to-back-up> [destination-directory]
```

- Backups are saved to `backups/` unless a destination is given.
- Each run is logged to `logs/backup.log`.
- Archives are created with owner-only permissions (`600`).

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Backup completed and verified |
| `1` | Wrong number of arguments |
| `2` | A check failed or the backup could not be created |
| `130` | Backup interrupted; any unfinished archive is removed |

## Branch workflow

`main` always holds working, reviewed code.

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
