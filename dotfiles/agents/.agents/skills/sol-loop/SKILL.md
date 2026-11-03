---
name: sol-loop
description: Run a bounded independent review and fix loop over a scoped change. Use for a sol-loop request or the review step of full-send and full-stop. Follow the session's reviewer model policy unless the user explicitly selects another model.
---

# Sol loop

## Scope and budget

Pin the intended behavior, exclusions, comparison base, and task-owned paths.
Include staged, unstaged, and relevant untracked work in the review. Preserve
unrelated changes. Resolve the base from the actual PR target or calling workflow;
ask only when inspection cannot establish it. Record checks that passed, failed,
or could not run before sending the review.

Use one independent reviewer, with at most three rounds by default. Extend to
five only when an evidenced security, data-loss, authorization, or concurrency
finding needs it, or the user asks. Keep stable finding IDs, severity, evidence,
and disposition across rounds. A stopped or failed reviewer is not approval.

## Independent review

Choose the reviewer using the user's model choice and applicable agent model
rules. The name `sol-loop` does not override that policy. If the user explicitly
requests Sol, use the available Sol model rather than silently substituting.
Choose a route that actually supports the required model and effort using
[reviewer routes](references/reviewer-routes.md). Codex, Claude Code, and Pi can
all run this workflow; the parent and reviewer need not use the same client.
Report a blocker when no authorized route supports the required configuration.

Give every new reviewer a complete brief. Follow the selected route's wait,
result retrieval, continuation, and cleanup rules. Only one round is active at
a time; keep the reviewed files unchanged while it runs. A terminal becoming
idle is not approval; read the completed verdict and its reviewed scope.

Give the reviewer:

- The repository path, stable base, diff command, included paths, and untracked
  files, plus the goal, exclusions, originating spec, and repository standards.
- Checks and observed behavior, including failures and missing proof.
- A read-only task with no edits, Git changes, external messages, watchers, or
  nested reviewers. Ask for bugs, broken callers, missing intended behavior,
  and unnecessary scope. Distinguish a documented rule from a style preference.
- A verdict of `APPROVE` or `CHANGES`, with a stable ID, severity, file and line,
  claim, evidence, and smallest credible correction for each finding. Approval
  must identify the reviewed head and any working-tree changes it covers.

## Fix and recheck

Verify findings against code and the contract using
[review triage](../lazy/references/review-triage.md). Fix substantive in-scope
issues, rerun affected checks and real-behavior proof, and record the result.
Decline disproven or out-of-scope findings with evidence. Rare inputs do not
automatically make a correctness or security issue a nit.

Later rounds receive the same base and goal, the ledger, the current diff, and
the changes since the previous round. Focus them on changed code and open IDs.
Start another round when behavior changed, a substantive item remains open, or
approval does not cover the current diff. Comment or formatting-only changes
need another review only when they affect meaning or the contract.

Finish when the current behavior diff is approved and no substantive finding or
concern of your own remains. If a dispute survives two exchanges or the round
budget ends, report `unresolved`, both sides' evidence, and the next decision.
Do not claim approval or let a calling workflow merge on that result.

Return rounds, actual reviewer model and effort when known, reviewed head and
scope, fixed and declined findings, verification results, and the verdict to
the caller. Commits, pushes, PR comments, and merging belong to the calling
workflow and its existing authority.

Adapted from [tstack](https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/sol-loop).
[MIT notice](../tstack-license.txt).
