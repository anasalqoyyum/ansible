---
name: bkt-jira-pr
description: Open Bitbucket pull requests with bkt while coordinating gen-pr-title and optional Jira status updates. Use when the user asks to create or open a PR through bkt. Include a Jira key from the request or branch in the PR title and move that issue to Review after successful non-draft PR creation; preserve the ordinary PR workflow without Jira calls when no ticket key exists.
---

# Bitbucket Jira PR

Compose `$gen-pr-title`, `$bkt`, and, only when a Jira key exists, `$jira-cli` into one PR workflow. Keep the tool-specific details in those skills; this skill owns their ordering and failure behavior.

## Workflow

1. Apply `$gen-pr-title` to inspect the branch, diff, and commits. Resolve one Jira key matching `[A-Z][A-Z0-9]+-[0-9]+`, case-insensitively, from the explicit request or current branch and normalize it to uppercase. If explicit and branch keys conflict, or multiple branch keys are ambiguous, ask which key to use.
2. Generate the title and summary. With a key, include it exactly once after the Conventional Commit prefix, for example `fix(test): DEX-2 - this is a test fix`. Without a key, retain the ordinary `type(scope): description` title.
3. Apply `$bkt` and create the PR with the generated title and summary. Include `--with-default-reviewers` so the repository's configured default reviewers are added. Request JSON output so the created PR ID and URL are unambiguous. Continue only after Bitbucket confirms creation.
4. When no Jira key was resolved, report the PR and finish without invoking Jira.
5. When the PR is a draft, report the PR and leave Jira unchanged unless the user explicitly requested a transition.
6. For a non-draft PR with a key, apply `$jira-cli` and inspect the issue. If its status is already `Review`, report that no transition was needed. Otherwise attempt `jira issue move KEY Review`, then verify the issue.
7. Keep the created PR when Jira lookup or transition fails. Report the PR URL and state that Jira was unchanged, distinguishing a missing issue, authentication failure, and an unavailable `Review` transition.

## Completion

Finish when the Bitbucket PR is confirmed and any applicable Jira transition is either verified or precisely reported as skipped or unavailable. Never represent Jira as updated based only on successful PR creation.
