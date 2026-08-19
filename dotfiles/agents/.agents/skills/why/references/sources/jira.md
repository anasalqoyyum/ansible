# Jira Tickets

## What this source contains

- Issues describing features, bugs, and their motivation
- Epics and their child issues (broader initiative → specific tickets)
- Comments on issues (clarifications, scope changes, "why we're doing this" rationale)
- Labels and components that signal the type of motivation
- Issue links (`blocks`, `relates to`, `duplicates`, `caused by`)
- Fix versions and sprints, which tie work to deadlines
- Remote links to Confluence pages and pull requests

Jira is where the product/business context often lives: the "we're doing this because customer X asked" or "this is for the Q3 compliance initiative" layer.

## How to search it

Use the `jira` CLI (ankitpokhrel jira-cli). It is usually available even when no Jira MCP is installed. Prefer `--plain` output; it is far cheaper to read than the TUI rendering. Never run `jira init`; if auth is missing, report the gap.

1. **Start with linked tickets.** If the seed commits, branch names, or PRs reference issue keys (e.g. `AR-1234`, `IAM-567`), fetch those first, with comments:

```bash
jira issue view AR-1234 --plain --comments 20
```

2. **Search by keyword with JQL.** Try multiple phrasings of the feature name, key symbol, endpoint path, or business term:

```bash
jira issue list -q 'text ~ "client template seeding" ORDER BY created DESC' --plain --no-headers
jira issue list -q 'project = IAM AND text ~ "permission catalog" AND created >= -180d' --plain
```

3. **Walk the issue tree.** If you land on a subtask or story, fetch its epic. Children are tactical; the epic often carries the "why":

```bash
jira epic list AR-1200 --plain
jira issue list -q 'parent = AR-1234' --plain
```

4. **Follow issue links and remote links.** `blocks` / `caused by` chains often lead to the incident or dependency that forced the design.
5. **Check labels, components, and fix versions.** Labels hint at the category of motivation; fix versions tie the work to a release date you can line up against the commit date.

## What good evidence looks like here

- An issue description stating the business problem: "Customer Acme needs X because of their SOC2 audit"
- A comment recording a decision: "We decided to go with approach B because approach A would require touching the platform service"
- An epic titled like an initiative: "Q3 Enterprise Readiness" or "Reduce Payment Failures"
- A remote link to a Confluence PRD or spec
- Labels like `customer-request`, `incident-followup`, `compliance`, `perf-regression`

## Common pitfalls

- **Scope drift.** The ticket the PR references may have been reopened with a different scope. Read the whole history and the comment timeline.
- **Mechanical templates.** Required "Why" fields filled with boilerplate ("improve user experience") are not a real answer.
- **Stale tickets.** Old tickets often reflect a plan that changed. Check dates against the code's ship date.
- **Duplicate chains.** Follow `duplicates` links back to the canonical ticket.
- **Permissions.** If a project or issue is not visible to your account, note it as a gap rather than guessing.
- **JQL text search is narrow.** `text ~` misses hyphenated and camelCase symbols. Also try `summary ~`, and search the plain feature name, not just the identifier.

## What to return

For each relevant ticket:
- Issue key and summary
- The problem/motivation quoted from the description or comments (exact text, not paraphrased; the synthesizer needs it to cite)
- Labels, components, epic, fix version, sprint
- Reporter, assignee, created date, resolved date
- Link to the ticket
