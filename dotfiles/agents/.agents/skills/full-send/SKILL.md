---
name: full-send
description: Carry a change through implementation, verification, review, PR creation, CI follow-up, and confirmed merge. Use when the user requests full send or explicitly asks to finish work through merge.
---

# Full send

Own the task until the host confirms the PR is merged. Read and follow the
[completion workflow](references/completion-workflow.md) with endpoint `merged`.
Use the existing `pr`, `babysit`, and `sol-loop` skills at their named steps.

An explicit full-send request asks for the merged endpoint. Carry its scope and
existing session authority forward without asking again for authorized steps.
Respect narrower instructions such as leaving changes uncommitted. Automatic
skill selection alone does not authorize Git changes, publication, or merge.

Adapted from [tstack](https://github.com/t3dotgg/tstack/tree/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/full-send).
[MIT notice](../tstack-license.txt).
