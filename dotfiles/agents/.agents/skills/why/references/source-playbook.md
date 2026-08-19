# Source playbooks

The why skill spawns one investigator per available evidence category, each reading a single source-specific playbook below. The playbooks are concrete examples for common MCPs; adapt them for a different provider in the same category. A provider is an MCP server **or** an authenticated CLI (`bkt`, `gh`, `glab`, `jira`); the playbooks apply either way.

| Category | Playbook | Example MCP it documents |
|---|---|---|
| Source control history | [`code-archaeology.md`](./sources/code-archaeology.md) | git, `bkt` (Bitbucket), `gh` (GitHub), `glab` (GitLab) |
| Issue / ticket tracker | [`jira.md`](./sources/jira.md), [`linear.md`](./sources/linear.md) | `jira` CLI; Linear MCP (adapt for GitHub Issues, Plane, Shortcut) |
| Long-form documents | [`notion.md`](./sources/notion.md) | Notion (adapt for Confluence, Google Docs, Coda) |
| Product analytics (PostHog) | [`databricks.md`](./sources/databricks.md) | adapt the warehouse playbook for the PostHog MCP |
| Real-time team chat | [`slack.md`](./sources/slack.md) | Slack (adapt for Discord, Microsoft Teams, Mattermost) |
| Infrastructure observability | [`datadog.md`](./sources/datadog.md) | Datadog (adapt for New Relic, Honeycomb, Grafana, Splunk) |
| Error / exception tracking | [`sentry.md`](./sources/sentry.md) | Sentry (adapt for Rollbar, Bugsnag, Airbrake) |
| Product analytics warehouse | [`databricks.md`](./sources/databricks.md) | Databricks SQL (adapt for Snowflake, BigQuery, ClickHouse, dbt) |

Cross-cutting:

- [`incident-postmortem.md`](./sources/incident-postmortem.md). Add this if the target code looks defensive (null checks, retry, timeout, rate limit, feature flag, egress guard, OOM handler).
