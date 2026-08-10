# Jira CLI command recipes

These recipes target ankitpokhrel/jira-cli 1.7.x. Use `jira <command> <subcommand> --help` as the installed source of truth when a command differs.

## Identity and discovery

```bash
jira version
jira me
jira serverinfo
jira project list
jira board list -p PROJECT
jira release list -p PROJECT
```

## Search and view issues

```bash
jira issue view ISSUE-123 --plain
jira issue view ISSUE-123 --comments 10 --plain
jira issue view ISSUE-123 --raw

jira issue list -p PROJECT --plain --columns KEY,SUMMARY,STATUS,ASSIGNEE --paginate 0:50
jira issue list -p PROJECT --status "In Progress" --assignee "USER" --plain
jira issue list -p PROJECT --created week --plain
jira issue list -q 'project = PROJECT AND status != Done' --order-by priority --plain
jira issue list -q 'project IS NOT EMPTY AND assignee = currentUser()' --raw --paginate 0:100
```

Repeat `--status` and `--label` for multiple values. Useful list filters include `--type`, `--priority`, `--reporter`, `--assignee`, `--component`, `--parent`, `--created`, and `--updated`.

Use `--order-by FIELD` and `--reverse` for ordering. Do not put `ORDER BY` inside `--jql`; jira-cli appends its own ordering clause. Prefix cross-project JQL with `project IS NOT EMPTY` so the configured project does not narrow the result.

## Create and edit

```bash
jira issue create -p PROJECT --type Task --summary "Summary" --body "Description" --no-input --raw
jira issue create -p PROJECT --type Bug --summary "Summary" --priority High --label bug --no-input --raw
jira issue create -p PROJECT --type Task --summary "Summary" --template - --no-input --raw
jira issue create -p PROJECT --type Sub-task --parent ISSUE-123 --summary "Summary" --no-input --raw

jira issue edit ISSUE-123 --summary "New summary" --no-input
jira issue edit ISSUE-123 --body "New description" --no-input
jira issue edit ISSUE-123 --custom story-points=3 --no-input
jira issue edit ISSUE-123 --label backend --no-input
jira issue edit ISSUE-123 --label -obsolete --no-input
```

For multiline creates, stream the body on stdin with `--template -`. For multiline edits, stream the description directly to `jira issue edit ISSUE-123 --no-input`; supplying `--body` overrides stdin.

## Assign, transition, and comment

```bash
jira issue assign ISSUE-123 "Exact Display Name"
jira issue assign ISSUE-123 "user@example.com"
jira issue assign ISSUE-123 default
jira issue assign ISSUE-123 x

jira issue move ISSUE-123 "In Progress"
jira issue move ISSUE-123 Done --resolution Done
jira issue move ISSUE-123 Done --comment "Completed"

jira issue comment add ISSUE-123 "Comment" --no-input
jira issue comment add ISSUE-123 --template - --no-input
jira issue comment add ISSUE-123 --template - --internal --no-input
```

`x` unassigns an issue. Transition names must match an available Jira workflow state.

## Link, clone, watch, and worklog

```bash
jira issue link ISSUE-123 ISSUE-456 Blocks
jira issue unlink ISSUE-123 ISSUE-456
jira issue clone ISSUE-123 --summary "Cloned summary"
jira issue watch ISSUE-123 "user@example.com"
jira issue worklog add ISSUE-123 "2h 30m" --comment "Work completed" --no-input
```

Link order matters: the first key is inward/source, the second is outward/target. Check subcommand help for remote links and worklog fields.

## Epics and sprints

```bash
jira epic list -p PROJECT --table --plain
jira epic add EPIC-1 ISSUE-123 ISSUE-456
jira epic remove ISSUE-123 ISSUE-456

jira sprint list -p PROJECT --table --plain
jira sprint list -p PROJECT --current --plain
jira sprint list SPRINT_ID --plain --columns KEY,SUMMARY,STATUS,ASSIGNEE
jira sprint add SPRINT_ID ISSUE-123 ISSUE-456
jira sprint close SPRINT_ID
```

Epic and sprint batch operations accept at most 50 issue keys per call.

## Destructive operations

```bash
jira issue delete ISSUE-123
jira issue delete ISSUE-123 --cascade
```

Inspect the issue first unless the user already supplied enough context to identify the exact target. `--cascade` also deletes subtasks.

## Troubleshooting

```bash
jira --help
jira issue <subcommand> --help
jira --debug issue view ISSUE-123
```

Use `--debug` only when ordinary error output is insufficient because it may expose extra request details. A different config can be selected with `--config PATH` or `JIRA_CONFIG_FILE` when the user explicitly provides it.
