# MEGA Mount Findings

## Outcome

The `rclone nfsmount` experiment for `/Users/xrisk/MEGA downloads` was rolled back.

Current state:

- `~/MEGA downloads` is a plain local directory again.
- The original files were restored successfully.
- The temporary `rclone` config, cache, log, mount helper, and LaunchAgent were removed.

Verified after rollback:

- file count: `10`
- total bytes: `45750615025`
- apparent size: `43G`

## What Failed

### 1. `nfsmount` on macOS is a loopback NFS mount

On macOS, `rclone nfsmount` works by starting a local NFS server and mounting that export back into the filesystem. This is not equivalent to a normal local directory or a native FUSE mount.

Practical consequence:

- if the local `rclone` NFS server dies or wedges, the mount becomes a stale hard NFS mount
- shell operations can then block waiting on the dead server

Observed here:

- `mount` showed `localhost:/mega-downloads-crypt on /Users/xrisk/MEGA downloads`
- `nfsstat -m` reported the mount as `not responding`
- bounded `chdir` worked, but bounded `opendir/readdir` hung

This explains the user-visible symptom that `cd ~/MEGA downloads` appeared to hang: the shell/prompt was likely blocking on directory reads or stats after entering the path.

### 2. Generic macOS copy tools were not reliable against this mount

Small test writes succeeded, but normal copy workflows did not behave like a real local filesystem.

Observed here:

- `cp -pR ... ~/MEGA downloads` hung
- `cat > ~/MEGA downloads/...` also hung in a later probe
- `rsync` into the mounted path did not progress into the real dataset

The `rclone` mount log showed:

- `failing create to indicate lack of support for 'exclusive' mode.`

This strongly suggests incompatibility between the NFS-backed mount behavior and the create/open patterns used by normal macOS tools.

### 3. Finder/macOS metadata side effects were present

The mount saw writes for:

- `.DS_Store`
- `._*` sidecar files

These extra files are normal macOS behavior, but they add noise and extra write activity on a mount that was already fragile.

### 4. Reboot safety during migration was poor

During migration, the original `MEGA downloads` contents had to be staged out of the mountpoint to create an empty directory for `nfsmount`.

The first staging location used was under `/private/tmp`, which is not a durable place to leave the only complete copy if a reboot happens mid-migration.

This was corrected by rolling the entire experiment back instead of trying to continue from that state.

## What Worked

- Direct `rclone` remote setup against the Hetzner Storage Box worked.
- The SFTP backend itself was reachable and browsable.
- Mount creation succeeded initially.
- Restoring the original local directory and files succeeded cleanly.

## Recommendation

Do not use `rclone nfsmount` for `~/MEGA downloads` on this machine if the expectation is:

- normal `cd`/`ls` behavior
- reliable Finder browsing
- reliable `cp`/`rsync`/shell writes into the mounted directory

If this is retried later, use one of these models instead:

1. Use a plain local directory and run explicit `rclone copy` / `rclone move` commands to sync data.
2. If a true mounted view is still desired, test `rclone mount` with `macFUSE` instead of `nfsmount`.

## Short Version

The problem was not the Hetzner backend itself. The problem was macOS `nfsmount` semantics: loopback NFS was too fragile for ordinary shell/Finder use and too easy to wedge into a stale `not responding` mount.
