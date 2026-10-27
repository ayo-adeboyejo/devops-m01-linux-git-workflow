# DevOps Module 1: Linux, Bash and Git Workflow

A collaborative workflow built with Linux commands, a Bash backup script and Git.
Practice assignment for Module 1 of my DevOps Engineering course.

## Branch workflow

The `main` always holds working, reviewed code. A new feature is started on another branch. The following highlights steps to rake while creating and merging a branch with main. 

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
