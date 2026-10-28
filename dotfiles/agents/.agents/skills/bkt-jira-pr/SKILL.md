---
name: bkt-jira-pr
description: Open Bitbucket pull requests with bkt while coordinating pr and optional Jira status updates. Use when the user asks to create or open a PR through bkt. Include a Jira key from the request or branch in the PR title and move that issue to Review after successful non-draft PR creation; preserve the ordinary PR workflow without Jira calls when no ticket key exists.
---

# Bitbucket Jira PR

Compose `$pr`, `$bkt`, and, only when a Jira key exists, `$jira-cli` into one PR workflow. Keep the tool-specific details in those skills; this skill owns their ordering and failure behavior.

## Workflow

1. Apply `$bkt` to resolve the destination repository and platform. Pass that destination, the target branch, and any requested template or format to `$pr`. Apply `$pr` to inspect the branch, diff, and commits, resolve the Jira key, and select the destination repository's PR template before drafting.
2. Generate the title and complete body through `$pr`. Its title rules include a resolved Jira key exactly once and retain the ordinary title format when no key exists. Its template selection owns the body layout; use the generic format only when no template or custom format applies.
3. Create the PR through `$bkt` with that title and complete body, preserving the filled template without converting it back to a generic summary. Pass the body as one quoted `--body "$BODY"` argument using `$pr`'s safe body handoff. Include `--with-default-reviewers` so the repository's configured default reviewers are added. Request JSON output so the created PR ID and URL are unambiguous. Continue only after Bitbucket confirms creation.
4. When no Jira key was resolved, report the PR and finish without invoking Jira.
5. When the PR is a draft, report the PR and leave Jira unchanged unless the user explicitly requested a transition.
6. For a non-draft PR with a key, apply `$jira-cli` and inspect the issue. If its status is already `Review`, report that no transition was needed. Otherwise attempt `jira issue move KEY Review`, then verify the issue.
7. Keep the created PR when Jira lookup or transition fails. Report the PR URL and state that Jira was unchanged, distinguishing a missing issue, authentication failure, and an unavailable `Review` transition.

## Completion

Finish when the Bitbucket PR is confirmed and any applicable Jira transition is either verified or precisely reported as skipped or unavailable. Never represent Jira as updated based only on successful PR creation.
