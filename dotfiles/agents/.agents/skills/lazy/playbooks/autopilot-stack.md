# Autopilot stack

You own a verified dependent queue, not its landing. The operator reviews and lands the chain.

1. Freeze the requested order and dependency graph. Mark operator-owned items and authority boundaries.
2. Assign one owner per change. Owners build, verify, apply `no-comments`, open or update host-native PRs, and babysit them to stack-ready.
3. Parallelize independent construction but keep one writer for dependency topology and rebases.
4. At each stack-ready head, run independent verification for gates, real-surface behavior, and diff plus evidence audit.
5. Return findings to the owner. Add only clean, exact heads to the delivery chain.
6. When a base moves, re-establish the dependency chain and re-verify every materially changed patch.
7. Never merge or arm auto-merge in this playbook. Deliver a bottom-up GitHub or Bitbucket PR sequence for the operator.
8. On operator stop, hold all writes immediately.

Report root and tip URLs, dependency order, exact heads, verdicts, excluded items, and the operator's next action.
