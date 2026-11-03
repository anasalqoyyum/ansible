---
name: modernize
description: Assess an old PR against current code and product intent, then rebase or rework it within the user's requested scope. Use when asked to modernize or bring an old PR up to date on GitHub or Bitbucket.
---

# Modernize

## Recover intent and current state

Resolve the host, PR URL, source repository and branch, destination repository
and actual target branch, remote head SHA, author, checks, and review state.
Use GitHub tools for GitHub or [bkt](../bkt/SKILL.md) for Bitbucket, distinguishing
Cloud and Data Center. Read the full diff, commits, discussion, linked issues,
and later user corrections. State the smallest goal the PR serves.

Inspect local work before changing Git state. Preserve unrelated changes and
use an isolated checkout when needed and authorized. Refresh the source and
target refs when fetching is authorized, then record the original head and merge
base. Resolve remotes explicitly for forks; the intended base need not be `main`
or on `origin`.

## Decide whether the idea still belongs

Inspect target-branch changes since divergence and related open or merged PRs.
Check whether the original problem is already solved, APIs or invariants changed,
ownership moved, or the proposed behavior would restore something deliberately
removed. A conflict-free rebase does not establish current usefulness.

Choose a disposition before rewriting or pushing:

- `MODERNIZE`: the goal and implementation still fit. Rebase and verify within
  the user's existing Git and publication authority.
- `REWORK`: the goal remains useful, but the old implementation no longer fits.
  Make the smallest coherent rework when the request already includes finishing
  that goal. A rebase-only request stops at the proposed rework for a decision.
- `CLOSE`: evidence shows the PR is superseded or no longer useful. Explain why
  and preserve the branch. Close the PR only when explicitly authorized.

## Update and verify

For an authorized update, record the exact destination of the push and its
current remote head. Check out the intended source head on the authorized
working branch and verify `HEAD` before rewriting commits. Account for any local
commits ahead of the remote. Rebase onto the refreshed intended target. Use the
conflict resolution procedure only within this task's authorized paths and Git
actions.
Resolve conflicts from both sides' intent and current invariants; ask when a
product choice cannot be inferred.

Compare old and new commit series with `git range-diff` and inspect the final
target-relative diff. Preserve intended behavior, contributor credit, and base
changes already landed. Run relevant checks and observe changed runtime paths.
Repeat review when the behavior diff changed; old approval is not new proof.

Re-read the remote head before publishing. Push a rebased branch only when
history rewriting is authorized, with an explicit lease against the head
recorded before the rebase. Set these variables from the verified source branch,
original remote head, and source remote:

```bash
git push --force-with-lease="refs/heads/$source_branch:$observed_sha" "$source_remote" "HEAD:refs/heads/$source_branch"
```

A failed lease means someone changed the branch. Fetch and reassess their work;
do not retry with a newer lease until that work is accounted for. Verify the
published head, target, and checks. Return to the caller's review and babysit
steps when it owns a wider workflow. Modernize alone never merges the PR.

Report disposition, evidence, base changes that matter, meaningful patch
differences, verification, publication result, final head, and remaining work.

Adapted from [tstack](https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/modernize).
[MIT notice](../tstack-license.txt).
