# Shipping

You own the independent verdict before an authorized landing. Green is necessary, not sufficient.

1. Confirm explicit merge, land, ship, or auto-merge authority. Pin the exact PR head and target branch.
2. Determine the host and platform capability. Use GitHub tooling or `gh` for GitHub. Use `bkt` for Bitbucket and distinguish Cloud from Data Center.
3. Verify draft state, approvals, unresolved threads, CI, conflicts, mergeability, and dependency order.
4. Review the diff and load-bearing runtime proof independently of the PR body.
5. Re-run stale or incomplete verification at the pinned head. A changed head voids the verdict unless the actual patch is proven unchanged and the relevant gates still apply.
6. For a dependent queue, verify each PR on the correct base and land only the contiguous verified run from the root.
7. Merge through the host-native operation. Use auto-merge only when explicitly requested and supported by the platform.
8. Verify the remote result, resulting commit, remaining queue, and ticket state. Jira transitions require their own authorization or an invoked workflow that already includes them.

Report the verdict, exact heads, operation performed, resulting commit, and any PR deliberately left unmerged.
