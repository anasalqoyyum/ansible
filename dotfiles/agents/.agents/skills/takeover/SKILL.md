---
name: takeover
description: Continue an existing PR, branch, or agent thread through the requested finish while preserving contributor credit. Use when asked to take over or finish inherited work on GitHub or Bitbucket.
---

# Takeover

## Reconstruct the work

Read the supplied PR, branch, or thread, including the original request, later
corrections, review findings, and handoff artifacts. In T3, read a supplied thread
with `t3_thread_read` before acting on its summary. Inspect current files, Git
state, remote head, target, and uncommitted work. Treat the handoff as context;
independently confirm what is implemented and what still fails.

Record the goal, scope, existing authority, completed steps, remaining behavior,
verification gaps, and requested endpoint. Resume completed work that still
verifies instead of repeating it. A request for local fixes or uncommitted work
keeps that limit throughout the takeover.

## Choose the continuation

Honor a requested in-place, replacement, or stacked continuation. For an in-place
PR update, verify authority to change that source branch. When a replacement PR
is requested, import original commits onto the authorized new branch and add
fixes separately. Preserve unrelated local work and keep the original PR intact
unless changing or closing it is separately authorized.

Preserve original Git authors and co-author trailers. Link the source PR and
credit its contributors in a replacement description. If squashing is part of
the authorized finish, preserve human author and co-author credit in the final
commit using verified identities. Required model attribution is separate from
contributor credit. Follow the harness's PR linking rules on takeover or push.

Use [modernize](../modernize/SKILL.md) when the branch is stale or current
architecture may supersede it. Rework only what finishing the original goal
requires. Recheck the source head before publication; incorporate or report
intervening changes rather than overwriting them.

## Finish the requested endpoint

Independently reproduce the original problem and verify realistic workflows.
Rerun stale checks and review meaningful behavior changes with
[sol-loop](../sol-loop/SKILL.md). Preserve the requested source and target.

When invoked from the shared completion workflow, return the reconstructed
scope, authority, head, and remaining work to it. Otherwise continue to the
endpoint the user requested:

- Local fix or handoff: leave the requested local state and report proof.
- Published, merge-ready PR: follow the shared
  [completion workflow](../full-send/references/completion-workflow.md) with
  endpoint `merge-ready`, resuming after this reconstruction.
- Confirmed merge: follow that workflow with endpoint `merged` when authorized.

If the request does not include publication or merge, complete the authorized
local work and report the remaining transition. Report what was inherited,
independently confirmed, changed, and verified, how credit was preserved, the
final head, and any remaining blocker.

Adapted from [tstack](https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/takeover).
[MIT notice](../tstack-license.txt).
