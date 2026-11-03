# Completion workflow

Use endpoint `merged` for `full-send` or `merge-ready` for `full-stop`.

## Establish the task

Read the original goal, later corrections, and applicable repository guidance.
Record the intended behavior, source branch, actual target branch, host, and
endpoint. For inherited work, use [takeover](../../takeover/SKILL.md) first.

If inspection shows the goal is already satisfied, or modernize recommends
`CLOSE`, report the evidence instead of manufacturing a change or merging
obsolete work. Closing an existing PR still needs explicit authority.

Inspect tracked, staged, and untracked changes before editing. Preserve unrelated
work. Resolve the PR's source and destination repositories separately, including
forks and release or stacked targets. Use GitHub tools for GitHub and
[bkt](../../bkt/SKILL.md) for Bitbucket Cloud or Data Center.

Carry forward the user's authority and limits for edits, commits, pushes,
rebases, PR creation, review replies, and merging. Ask only when the next needed
operation lacks authority or a product decision changes the result. Do the
independent authorized work first. A no-commit or no-publish instruction takes
precedence over the endpoint; report the exact transition left for the user.

For `merge-ready`, check whether auto-merge or a merge queue could land the PR
during this work. Disable it only with existing authority. If keeping the PR
unmerged requires an unauthorized remote change, explain that blocker before
pushing or changing its checks. Never enable automatic merging in this mode.

## Complete, prove, and review

1. Finish the requested behavior with the smallest complete change. Use a task
   branch when branch creation is authorized; preserve the intended PR base.
2. Reproduce the reported failure when applicable, then observe the corrected
   behavior through the real interface. Run the repository's relevant checks.
   Record actual results and unverified behavior. Use the project's verification
   skill when available. Testing follows repository and session permissions.
3. Apply [sol-loop](../../sol-loop/SKILL.md) to review and fix the scoped change.
   Give the reviewer the goal, standards, spec when present, stable base, current
   diff, and proof. Continue only after approval covers the current behavior
   diff and no substantive finding remains open. A budget limit is not approval.
4. Commit only task-owned changes when authorized. Recheck after any change
   introduced by review, rebasing, conflict resolution, or generated output.
   Use [modernize](../../modernize/SKILL.md) when updating an old PR requires
   checking whether its goal and implementation still belong.

## Publish and follow through

1. Reuse an existing PR for this source and target when appropriate. For creation
   or description updates, use [pr](../../pr/SKILL.md) for the title, template,
   Jira key, evidence, and safe body handoff. For a new Bitbucket PR, use the
   creation steps of [bkt-jira-pr](../../bkt-jira-pr/SKILL.md). Run its Jira
   transition only when the user's request or existing session authority includes
   that change; otherwise skip it without blocking the PR and report Jira as
   unchanged. Updating an existing PR does not rerun PR creation or a Jira
   transition. Verify the remote URL, source head, target, and draft state after
   publication. Follow the harness's PR linking rules.
2. Apply [babysit](../../babysit/SKILL.md) until its
   [merge gate](../../babysit/references/merge-gate.md) passes on the current
   head. Fix real CI and review findings, verify each fix, push when authorized,
   and return to the gate. Behavior changes also return to the review step.
3. Keep ownership while checks or reviews are pending. Use babysit's durable
   wake mechanism before yielding. Handle wake events and resume this workflow
   without another prompt. An opened PR is an intermediate result.

## Reach the endpoint

Fetch and inspect the live head and target before the final decision. If either
changed, reassess the affected proof, review, and checks using the merge gate.

- `merge-ready`: leave the PR open and unmerged, with no automatic merge armed.
  Stop when the gate passes. If required human approval is the only remaining
  gate and needs user action, report `waiting for required approval`.
- `merged`: with existing merge authority, use the repository's allowed merge
  method through the host. Honor branch protection, approvals, and dependency
  order. If an authorized merge queue or auto-merge is used, continue until the
  host confirms the merge. Record the resulting merge or squash commit.

When blocked, use the harness's question tool for the exact missing decision or
authority. Keep the PR and local work intact. A tool failure, missing proof,
unknown merge state, or unanswered question is not success. Follow babysit's
watch cleanup rules before handing back. Leave a resumable record of the goal,
URL, head, proof, open findings, blocker, and next action for long-running work.

Report the endpoint actually reached, PR URL, final head, proof, reviewer
verdict, CI and review state, and remaining risks. For a merge, include the
resulting commit. For merge-ready, state that the PR remains open and unmerged.
