# File Permissions

This doc explains how Linux file permissions apply to this project, with output captured on the project server..

## 1. How to read permissions

```
$ ls -l README.md scripts/backup.sh
-rw-rw-r-- 1 backup-user backup-user 2012 Nov  1 17:44 README.md
-rwxrwxr-x 1 backup-user backup-user 3513 Nov  1 17:44 scripts/backup.sh
```

The first ten characters are the file type followed by three groups of three:

```
-  rwx  rwx  r-x
│   │    │    └── others
│   │    └─────── group
│   └──────────── owner
└──────────────── type: - file, d directory, l symlink
```

Each permission has a numeric value, added together per group:

| Permission | Symbol | Value | On a file | On a directory |
|---|---|---|---|---|
| Read | `r` | 4 | Read contents | List names inside |
| Write | `w` | 2 | Change contents | Create or delete files inside |
| Execute | `x` | 1 | Run it | Enter it |

`stat` shows both notations side by side:

```
$ stat -c '%A  %a  %U  %G  %n' README.md scripts/backup.sh
-rw-rw-r--  664  backup-user  backup-user  README.md
-rwxrwxr-x  775  backup-user  backup-user  scripts/backup.sh
```

## 2. The execute permission

A script needs execute permission to run. Using a copy of the script:

```
$ chmod -x /tmp/perm-demo.sh
$ ls -l /tmp/perm-demo.sh
-rw-rw-r-- 1 backup-user backup-user 3513 Nov  1 19:12 /tmp/perm-demo.sh
$ /tmp/perm-demo.sh; echo "exit: $?"
-bash: /tmp/perm-demo.sh: Permission denied
exit: 126
$ chmod +x /tmp/perm-demo.sh
$ ls -l /tmp/perm-demo.sh
-rwxrwxr-x 1 backup-user backup-user 3513 Nov  1 19:12 /tmp/perm-demo.sh
```

Exit code `126` means the file was found but could not be executed (`127` would mean not found).


## 3. Default permissions and umask

`umask` sets which permissions are removed from new files. New files start from `666` and new directories from `777`.

```
$ umask
0002
$ echo "data" > /tmp/perm-src/file.txt
$ ls -l /tmp/perm-src/file.txt
-rw-rw-r-- 1 backup-user backup-user 5 Nov  1 19:12 /tmp/perm-src/file.txt
```

The system used for this project has a default umask is `002`, so new files are `664`. Group write is allowed because each user has a private group of their own.

Backups may contain sensitive data, so `backup.sh` sets `umask 077`, removing all group and other permissions regardless of the system default:

```
$ ./scripts/backup.sh /tmp/perm-src /tmp/perm-backups
2026-11-01 19:12:56 [INFO] Starting backup: /tmp/perm-src -> /tmp/perm-backups
2026-11-01 19:12:56 [INFO] Backup OK: /tmp/perm-src -> /tmp/perm-backups/perm-src_20261101_191256.tar.gz (4.0K)
$ ls -ld /tmp/perm-backups
drwx------ 2 backup-user backup-user 4096 Nov  1 19:12 /tmp/perm-backups
$ ls -l /tmp/perm-backups
-rw------- 1 backup-user backup-user 167 Nov  1 19:12 perm-src_20261101_191256.tar.gz
```

| | System default (`002`) | Script (`077`) |
|---|---|---|
| New file | `664` `rw-rw-r--` | `600` `rw-------` |
| New directory | `775` `rwxrwxr-x` | `700` `rwx------` |

Setting the umask before creating files means a backup will never exist with open permissions, even briefly.

## 4. Permissions enforced

With all permissions removed, the script refuses the source before attempting a backup:

```
$ chmod 000 /tmp/perm-src
$ ls -ld /tmp/perm-src
d--------- 2 backup-user backup-user 4096 Nov  1 19:12 /tmp/perm-src
$ ./scripts/backup.sh /tmp/perm-src /tmp/perm-backups; echo "exit: $?"
2026-11-01 19:13:02 [ERROR] Source is not readable: /tmp/perm-src
exit: 2
```

The script checks for both `r` (list the directory) and `x` (enter it), since reading a directory's files needs both. This test only works as a non-root user, because root ignores file permissions.

## 5. Real-world example: SSH keys

SSH client will refuse a private key that other users can read. The working setup for this repo's GitHub access:

```
$ ls -ld ~/.ssh
drwx------ 2 backup-user backup-user 4096 Oct 22 21:01 /home/backup-user/.ssh
$ ls -l ~/.ssh/github_key ~/.ssh/github_key.pub ~/.ssh/config
-rw------- 1 backup-user backup-user  95 Oct 22 21:01 /home/backup-user/.ssh/config
-rw------- 1 backup-user backup-user 419 Oct 22 20:37 /home/backup-user/.ssh/github_key
-rw-r--r-- 1 backup-user backup-user 108 Oct 22 20:37 /home/backup-user/.ssh/github_key.pub
```

| File | Mode | Why |
|---|---|---|
| `~/.ssh/` | `700` | Only the owner can enter the folder |
| `github_key` (private) | `600` | Secret: owner only |
| `github_key.pub` (public) | `644` | Safe to share; it is what GitHub holds |
| `config` | `600` | SSH rejects a config others can write to |
