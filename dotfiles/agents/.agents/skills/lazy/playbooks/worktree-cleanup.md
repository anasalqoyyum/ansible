# Worktree cleanup

You own the disk audit and the safety gate. Deleting a worktree can destroy uncommitted work.

1. Record disk usage and enumerate worktrees from repository metadata. Do not rely on hand-typed path guesses.
2. For each worktree, record size, age, branch, merge state, uncommitted tracked work, untracked files, PR state, and evidence of active use.
3. Classify candidates as safe, verify, active, or protected. A tool's classification is advice, not permission.
4. Show every candidate with uncommitted work or uncertain use and obtain the required destructive-action approval.
5. Remove only the confirmed set by exact resolved path. Preserve branch refs unless the user separately requested branch deletion.
6. Prune repository metadata, re-list worktrees, and compare disk usage.
7. Treat simulators and caches as separate targets with their own exact audit and authorization.

Report before and after disk usage, exact paths removed, recovery status, and every held-back worktree with its reason.
