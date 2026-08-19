# Autopilot full

You own independent verdicts across a queue whose PR owners are authorized to carry changes through merge.

1. Freeze the queue and mark operator-owned items. A request to state the protocol is not permission to execute it.
2. Assign one owner per independent PR. Each owner builds, proves the real behavior, applies `no-comments`, opens or updates the PR on the correct host, and babysits it to merge-ready.
3. Keep owners parallel only when branches and files are independent. Sequence overlapping work.
4. At each merge-ready head, run an independent verification fan-out with distinct lanes for gates, real-surface behavior, and diff plus receipt audit.
5. Return findings to the owner. A changed head requires a fresh verdict.
6. On a clean verdict and existing merge authority, the owner merges through GitHub or `bkt` as appropriate and takes the next ready item.
7. Audit owner liveness, protocol adherence, decisions, and the queue frontier at a sensible interval.
8. On operator stop, send every owner an immediate zero-writes hold.

Report owners, PR URLs, exact heads, verdicts, merges, remaining queue, and operator gates.
