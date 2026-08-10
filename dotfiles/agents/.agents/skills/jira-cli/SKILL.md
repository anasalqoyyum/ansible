---
name: jira-cli
description: Operate Jira through the installed ankitpokhrel jira-cli. Use for Jira issue searches and JQL; viewing, creating, editing, assigning, transitioning, commenting on, linking, cloning, or deleting issues; and working with projects, boards, epics, sprints, releases, worklogs, or watchers. Trigger on Jira issue keys and requests involving tickets, backlog, or sprint work that should use the CLI.
---

# Jira CLI

Use the installed `jira` binary instead of reconstructing Jira API calls.

## Workflow

1. Extract the issue key, project, operation, and requested values from the user's request. Use the configured project when the user clearly means their current Jira project; pass `-p PROJECT` when they name another project.
2. Read [references/commands.md](references/commands.md) for the relevant recipe. Run `jira <command> <subcommand> --help` only when the recipe does not cover the operation or the installed version rejects it.
3. Run read-only requests immediately. Prefer `--plain` with selected columns for concise human-readable results and `--raw` when structured data is needed for filtering or extraction. Set `--paginate` deliberately.
4. Run a write immediately when the user specified the target and intended change. Use non-interactive flags such as `--no-input`. If a material value is missing or ambiguous, inspect read-only context first, then ask only for the unresolved choice.
5. Treat an explicit instruction naming the exact target as authorization for that change. Otherwise require confirmation before deletion, cascade deletion, unlinking, closing a sprint, or similarly hard-to-reverse actions.
6. Verify successful writes with `jira issue view KEY --plain` or the narrowest relevant read command. Report the changed key and outcome; include failure output when the CLI rejects the request.

## Execution rules

- Use non-interactive output. Avoid bare commands that open a terminal explorer when `--plain`, `--table --plain`, or `--raw` is available.
- Quote summaries, statuses, display names, JQL, and other values containing spaces.
- Feed multiline create descriptions and comments through stdin with `--template -`. Feed multiline edit descriptions directly through stdin without `--body`. Avoid interpolating user text into shell syntax.
- Use exact user names or email addresses for assignment and watchers. Use `jira me` when the user means themselves.
- Keep credentials private. Do not print or modify `~/.config/.jira/.config.yml`, `JIRA_API_TOKEN`, or other authentication values.
- Do not run `jira init` unless the user asks to configure authentication. If authentication is missing, report that setup is required.

## Completion

Finish when the requested Jira data is returned or every requested mutation is verified. State any unresolved target, permission error, invalid field, or unavailable transition precisely.
