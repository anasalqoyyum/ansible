# Opening a PR

You own a truthful PR description and a verified remote result. Use only when the user explicitly asks to create or open a PR.

1. Confirm the intended diff, source branch, target branch, dependency order, and draft state.
2. Run relevant verification and apply `no-comments` before publication.
3. Generate a concise title and body from the actual change with `gen-pr-title`. Include proof and known limits.
4. Determine the host before choosing a tool.
5. For GitHub, use the connected GitHub workflow and `gh` only where needed. For Bitbucket, apply `bkt-jira-pr`, which coordinates `bkt`, default reviewers, and Jira when a ticket key exists.
6. Request structured output where available. Verify the returned number, URL, base, head, and draft state.
7. Stop after creation unless the user also asked for Babysit, Shipping, thread replies, or ticket changes.

Creating a PR does not authorize merging it. Report the URL and any post-creation action that was skipped or failed.
