# Incident and postmortem context

Use this as a cross-cutting angle when defensive code may have been incident-driven.

- Search commit messages for incident, outage, revert, follow-up, retry, timeout, and the exact error string.
- Search GitHub or Bitbucket PR bodies and review threads for incident IDs, postmortem links, rollback discussion, and follow-up work.
- Search Jira for linked incidents, reliability labels, caused-by relationships, and postmortem action items.
- Search in-repo ADRs, RFCs, postmortems, runbooks, and changelogs for the target symbol, feature name, error text, and ship date.
- Follow linked evidence fully. A PR that says “postmortem action item” is only a lead until the action item or incident record is read.

Strong evidence connects the incident condition, the chosen mitigation, and the exact code change. Temporal proximity alone is circumstantial. Report missing postmortems and inaccessible links as gaps.
