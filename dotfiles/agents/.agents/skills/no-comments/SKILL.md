---
name: no-comments
description: Review comments and suppressions in a requested file set or diff, remove narration and workarounds, preserve proven constraints, and encode important rules in code or tooling. Use before code review or when the user asks to remove comments.
disable-model-invocation: true
---

# No comments

Run a fresh "Comment Sicko" pass, then act on accepted findings. Authoring context makes comments feel necessary. The fresh pass exists to challenge that bias.

## Scope

Use the caller's files or diff. Otherwise use the active task's changed files against its fixed point, including working-tree changes. If neither is available, ask for scope instead of sweeping the repository.

Include line and block comments, doc comments, lint suppressions, formatter directives, TypeScript suppressions, and equivalent annotations. Treat generated files as read-only and use their generator when a change is required.

## Steps

1. When delegation is available and worth the coordination cost, use the installed `comment-sicko` or `comment_sicko` specialist and pass the scope. Use the current session model by omitting model selection. If the harness cannot resolve that specialist, send one independent reviewer the scope and the absolute path to [references/comment-sicko.md](references/comment-sicko.md), and require it to follow that role. Ask for a report, not edits. When delegation is unavailable, read that reference and perform a separate comment-only pass after setting aside the authoring rationale.
2. Inspect the report and diff. Reject scope escapes, application behavior changes, legal-header deletion, generated-directive edits, and removal of comments that describe proven constraints outside the codebase. Audit missed lint, formatter, and type suppressions yourself.
3. Classify each accepted finding:
   - `remove` for narration, section labels, stale explanations, commented-out code, and comments that restate the next statement.
   - `reshape` when naming, hidden state, unclear ownership, a dead path, or a workaround makes the comment necessary.
   - `encode` when an invariant can become a type, assertion, test, lint rule, schema, or CI check.
   - `keep` for legal text, generated markers, tool-required directives, caller-facing API documentation, or non-obvious external constraints the code cannot express.
   - `investigate` when a suppression or warning cannot yet be shown safe or necessary.
4. Fix trivial reshape findings directly by deleting dead paths, dropping unused parameters, choosing precise names, or using the real API. When several accepted findings expose one structural problem, sketch the corrected shape before editing.
5. Implement the smallest root-cause fix inside scope. Remove every workaround made obsolete by that fix. Do not change application behavior merely to improve the comment count.
6. Constraint comments such as “do not remove,” “do not change wording,” or “ask X first” need proof. Encode them when the encoding is in scope and authorized. Otherwise keep only a justified external constraint and report the cheapest proposed encoding.
7. Audit suppressions individually. Keep only the narrowest suppression with a demonstrated need. Correctness and safety suppressions remain actionable until proven necessary.
8. Run focused checks for every code change and inspect the final diff. If the independent report made a material mistake, name it and do one corrected pass. A repeated unreliable pass becomes an open finding, not an excuse for unbounded reruns.

## Report

Report the deletion count, comments kept with reasons, suppressions removed or retained, structural fixes, encoded constraints, proposed encodings, reruns, and unresolved work. Mention the independent pass only when it materially affected the result.
