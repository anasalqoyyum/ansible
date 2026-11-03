# Merge gate

Evaluate the live PR on its current source head and actual target branch. Record
both SHAs with the verdict. A watcher event or cached green result is a reason
to inspect, not a readiness verdict.

All applicable conditions must hold:

- The PR is open, not draft, and targets the intended repository and branch.
- Required checks are present and successful on the current head. Count skipped
  checks only when repository policy allows them. Missing or unreadable checks
  are unknown, not passing; an explicitly check-free repository is different.
- Required approvals are satisfied and no current human review requests changes.
  Inspect complete review state, paginating where needed. On Bitbucket derive
  approval and changes-requested state from participants and merge requirements.
- Required review bots have finished on the current head. Verify their findings
  against code and address or dismiss each substantive item with evidence. Use
  repository policy to decide which bots gate; no bot is universally advisory.
- No actionable review item, unresolved review thread, or incomplete blocking
  task remains. Outdated does not mean resolved. Paginate thread listings and
  inspect the full discussion when a summary or final comment is insufficient.
- The host reports mergeable with its branch requirements satisfied. A conflict,
  required base update, unknown state, or unreadable merge requirement blocks a
  ready verdict. Respect release branches and dependent PR order.
- Behavior proof and independent review still cover the current diff. Recheck
  changed behavior and meaningful conflict resolutions. If the base moved into
  affected behavior, reassess integration proof even when Git finds no conflict.

Read the head again after collecting the gate. If it changed, discard the
mixed-state verdict and inspect the new head. Reevaluate affected gates when
the target changes. Before merging, check live state again and bind the merge
to the inspected head when the host supports it; otherwise verify immediately
before submission and confirm the remote result.

`merge-ready` means this gate passes. `waiting for required approval` and
`blocked` are separate outcomes. Gate success does not itself authorize merge.
For a workflow that must leave the PR unmerged, also verify that automatic merge
and merge-queue entry are disabled before the handoff.
