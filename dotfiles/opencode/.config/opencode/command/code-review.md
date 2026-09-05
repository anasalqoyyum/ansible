---
description: Review changes with parallel @code-reviewer subagents
agent: plan
---
Review the code changes with the configured `@code-reviewer` subagent when independent review adds value, then correlate findings into a summary ranked by severity. For broad or high-risk changes, use up to three distinct reviewers and consult `@oracle` to check the findings for accuracy and correctness against the surrounding code, subsystems, abstractions, and architecture. For a small change, one reviewer or a direct review is enough; do not delegate merely to satisfy a fixed fan-out. Apply recommendations from the oracle when that review is run.

Guidance: $ARGUMENTS

Review uncommitted changes by default. If no uncommitted changes, review the last commit. If the user provides a pull request/merge request number or link, use CLI tools (gh/glab/bkt) to fetch it and then perform your review.
