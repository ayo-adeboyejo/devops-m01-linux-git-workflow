# Process Diagnostic: Inspecting and Stopping a Running Backup

This doc demonstrates process diagnostics on a Linux system, using a running `backup.sh` job as the example. It covers how to find the processes a job starts, see what files they are using, check progress, and stop the job safely. It also confirms that the script cleans up after itself when interrupted.


## Objectives

- Identify the processes started by the backup script and how they relate to each other
- Inspect each process's state, CPU usage and open files
- Confirm the backup is making progress
- Stop the backup from outside the script and verify the cleanup

## 1. Preparing test data

A 1 GB file of random data keeps it running long enough, because random data cannot be compressed and keeps `gzip` busy.


```
$ df -h /tmp .
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        25G   17G  6.4G  73% /
/dev/sda2        25G   17G  6.4G  73% /
$ head -c 1G /dev/urandom > /tmp/big/random.bin
$ ls -lh /tmp/big
total 1.1G
-rw-rw-r-- 1 backup-user backup-user 1.0G Nov  3 19:32 random.bin
```


## 2. Starting the backup in the background

```
$ ./scripts/backup.sh /tmp/big > /tmp/backup-run.out 2>&1 &
$ PID=$!
$ echo "Backup PID: $PID"
Backup PID: 1388935
```

- `&` runs the script in the background, leaving the terminal free for inspection.
- `$!` holds the PID of the last background command. It is saved in `PID` for the following steps.

## 3. Inspecting the process tree

```
$ pstree -p "$PID"
bash(1388935)───tar(1388950)───sh(1388951)───gzip(1388952)
```

**Observation:** the backup runs as four processes, not two. GNU `tar` does not compress data itself. It starts `gzip` through a shell (`sh -c gzip`) and pipes the archive into it.

Every process in the backup's process group, with more detail:

```
$ ps -o pid,ppid,pgid,stat,etime,%cpu,%mem,cmd -p "$(pgrep -d, -g "$PID")"
    PID    PPID    PGID STAT     ELAPSED %CPU %MEM CMD
1388935    1447 1388935 S          00:02  0.4  0.0 bash ./scripts/backup.sh /tmp/big
1388950 1388935 1388935 S          00:02  5.4  0.0 tar -czf /home/backup-user/devops-m0
1388951 1388950 1388935 S          00:02  0.0  0.0 /bin/sh -c gzip
1388952 1388951 1388935 R          00:02 90.5  0.0 gzip
```

| Column | Meaning | Observation |
|---|---|---|
| PPID | Parent process ID | Each process was started by the one above it; the script was started by the terminal (`1447`) |
| PGID | Process group ID | All four processes share the script's PID as their group |
| STAT | Process state: `R` running, `S` sleeping | Only `gzip` is actively running |
| %CPU | CPU usage | `gzip` at 90.5% is the bottleneck; `tar` mostly waits for it |

**Note:** `ps -g` does not select by process group ID on Linux; it selects by session or group name. `pgrep -g` matches the process group, so it is used here to collect the PIDs for `ps -p`.

## 4. Inspecting open files

Each process's open files are listed under `/proc/<PID>/fd`.

**`tar`:**

```
$ TAR_PID=$(pgrep -P "$PID" tar)
$ ls -l /proc/"$TAR_PID"/fd | grep -E 'part|random'
lr-x------ 1 backup-user backup-user 64 Nov  3 19:32 6 -> /tmp/big/random.bin
```


**`gzip`:**

```
$ GZIP_PID=$(pgrep -g "$PID" gzip)
$ ls -l /proc/"$GZIP_PID"/fd
total 0
lr-x------ 1 backup-user backup-user 64 Nov  3 19:32 0 -> 'pipe:[4730661]'
l-wx------ 1 backup-user backup-user 64 Nov  3 19:32 1 -> /home/backup-user/devops-m01-linux-git-workflow/backups/big_20261103_193245.tar.gz.part
l-wx------ 1 backup-user backup-user 64 Nov  3 19:32 2 -> /tmp/backup-run.out
```

| FD | Stream | Points to |
|---|---|---|
| `0` | stdin (read) | The pipe carrying data from `tar` |
| `1` | stdout (write) | The temporary `.part` archive |
| `2` | stderr (write) | The output file the script was redirected to |

**Observation:** `gzip` writes the archive. `tar` reads the source and passes the data through a pipe; `gzip` compresses it and writes the `.part` file.

## 5. Checking progress

The size of the `.part` file is checked twice, two seconds apart:

```
$ ls -l backups/ | grep part
-rw------- 1 backup-user backup-user 42729472 Nov  3 19:32 big_20261103_193245.tar.gz.part
$ sleep 2
$ ls -l backups/ | grep part
-rw------- 1 backup-user backup-user 81526784 Nov  3 19:32 big_20261103_193245.tar.gz.part
```

**Observation:** the file grew by about 39 MB.

## 6. Stopping the backup and verifying cleanup

Bash waits for a running command to finish before it handles a signal. Sending `TERM` to the script's PID alone would let `tar` and `gzip` complete the whole archive before the script reacts. Sending the signal to the process group (`kill -- -PID`) stops all four processes at once, which is what `Ctrl+C` does in a terminal.

```
$ kill -TERM -- -"$PID"
$ wait "$PID"; echo "exit: $?"
[1]+  Exit 130                ./scripts/backup.sh /tmp/big > /tmp/backup-run.out 2>&1
exit: 130
$ cat /tmp/backup-run.out
2026-11-03 19:32:45 [INFO] Starting backup: /tmp/big -> /home/backup-user/devops-m01-linux-git-workflow/backups
Terminated
2026-11-03 19:32:49 [ERROR] Backup interrupted
$ ls -la backups/ | grep -c part
0
```

| Check | Expected | Result |
|---|---|---|
| Exit code | `130` (128 + signal 2), marking the run as interrupted | `130` |
| Log entry | "Backup interrupted" recorded | Recorded at 19:32:49 |
| Temporary file | No `.part` file left behind | `0` found |

**Observation:** the script's `trap` handled the signal from outside the terminal. It logged the interruption and removed the unfinished archive, so no partial file remains that could be mistaken for a valid backup.

## Summary

- The backup runs as a chain of four processes in one process group: the script, `tar`, a shell and `gzip`.
- Progress can be confirmed by watching the temporary file grow.
- Signalling the whole process group stops the job immediately, and the script's cleanup works as designed.

## Commands used

| Command | Purpose |
|---|---|
| `df -h` | Check free disk space |
| `$!` | Get the PID of the last background command |
| `pstree -p` | Show parent and child processes |
| `pgrep -P` / `pgrep -g` | Find processes by parent or by process group |
| `ps -o ... -p` | Show chosen details for specific processes |
| `/proc/<PID>/fd` | List a process's open files |
| `kill -TERM -- -PID` | Send a signal to a whole process group |
| `wait` | Wait for a background job and get its exit code |
