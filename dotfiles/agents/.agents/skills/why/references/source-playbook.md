# Source playbooks

Assign one playbook to each available investigator.

| Evidence lane | Playbook | Tools |
|---|---|---|
| Repository and forge history | [`code-archaeology.md`](./sources/code-archaeology.md) | `git`, connected GitHub tooling or `gh`, `bkt` |
| Jira | [`jira.md`](./sources/jira.md) | `jira` CLI |
| In-repo documents | [`code-archaeology.md`](./sources/code-archaeology.md) | `rg`, repository files, history |

Add [`incident-postmortem.md`](./sources/incident-postmortem.md) when the target contains defensive behavior such as retries, timeouts, rate limits, feature flags, fallbacks, or data-recovery logic.
