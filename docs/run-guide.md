# Run Guide

How to get, run and check the backup script.

## Requirements

- Linux with Bash
- `tar` and `gzip`
- GNU coreutils (the script uses `realpath -m`)
- Git

## 1. Get the code

```bash
git clone https://github.com/ayo-adeboyejo/devops-m01-linux-git-workflow.git
cd devops-m01-linux-git-workflow
```

The script is already executable after cloning, so no `chmod` is needed. Run all commands from the repository root.

## 2. Run a backup

```bash
./scripts/backup.sh <source-dir> [destination-dir]
```

Back up to the default destination, `backups/` in the repository:

```bash
./scripts/backup.sh /path/to/folder
```

Back up to a chosen destination, which is created if it does not exist:

```bash
./scripts/backup.sh /path/to/folder /path/to/backups
```

Each archive is named `<folder>_<YYYYmmdd_HHMMSS>.tar.gz` and is readable only by its owner (`600`).

## 3. Check the result

```bash
echo $?                      # 0 means the backup succeeded
ls -l backups/               # list archives and their permissions
cat logs/backup.log          # every run is logged here
grep ERROR logs/backup.log   # show only failures
```

## 4. Restore and verify a backup

```bash
tar -tzf backups/<archive>.tar.gz                      # list the contents
mkdir /tmp/restore
tar -xzf backups/<archive>.tar.gz -C /tmp/restore      # extract
diff -r /path/to/folder /tmp/restore/<folder> && echo "IDENTICAL"
```

`diff -r` prints nothing when the two folders match, so `IDENTICAL` confirms the backup is complete.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Backup completed and verified |
| `1` | Wrong number of arguments |
| `2` | A check failed or the backup could not be created |
| `130` | Backup interrupted; any unfinished archive is removed |

Usage errors (exit code `1`) are shown on screen but not logged, because the script checks its arguments before logging starts.

## Sample output

A successful backup:

```
$ ./scripts/backup.sh /tmp/rg-data
2026-11-04 12:03:41 [INFO] Starting backup: /tmp/rg-data -> /tmp/rg-test/backups
2026-11-04 12:03:41 [INFO] Backup OK: /tmp/rg-data -> /tmp/rg-test/backups/rg-data_20261104_120341.tar.gz (4.0K)
```

A failed check:

```
$ ./scripts/backup.sh /tmp/no-such-dir
2026-11-04 12:03:41 [ERROR] Source not found: /tmp/no-such-dir
```
