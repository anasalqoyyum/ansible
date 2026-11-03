---
name: full-stop
description: Carry a change through implementation, verification, review, PR creation, and CI follow-up, leaving it merge-ready and unmerged. Use for an intentional full-stop workflow request or an explicit end-to-end request to stop before merge; ordinary emphasis is not a trigger.
---

# Full stop

Read and follow the shared
[completion workflow](../full-send/references/completion-workflow.md) with
endpoint `merge-ready`. The user's current limits and existing authority apply.

Leave the PR open and unmerged. Never merge, enable auto-merge, enter a merge
queue, or delegate those actions in this mode. Check existing automatic merge
state before working, and follow the shared workflow if disabling it needs
authority. Report any required human approval separately from completed checks.

Adapted from [tstack](https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/full-stop).
[MIT notice](../tstack-license.txt).
