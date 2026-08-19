# Babysit

You own the merge frontier. Declare a mode, clear one PR at a time, and stop where merge authority begins.

1. Declare the mode before querying. `check` performs one status pass. `threads` handles review feedback only. `background` triages while another plan runs. `drive` continues until merge-ready or genuinely blocked.
2. Determine the host. For GitHub, use connected GitHub tooling and `gh` where needed. For Bitbucket, use `bkt pr view`, `bkt pr comments`, and `bkt pr checks`.
3. Work the lowest unmerged dependency first. Read higher PRs but do not restart their checks while the frontier is blocked.
4. Keep one babysitter per PR or dependent queue. Do not mutate stack topology, rebase a dependent chain, or force-push as part of babysitting unless the user separately authorized that operation.
5. Order work as conflicts, actionable review threads, then CI. Batch known fixes that restart the same checks.
6. Query the platform's current merge state after every change. Do not trust a deduplicated or remembered green list.
7. Classify CI before retriggering. One infrastructure or flake retry is enough. An identical second failure requires diagnosis.
8. Triage human and automated findings through [review triage](../references/review-triage.md). Fix real findings in the lowest owning PR. Dismiss noise only with evidence and authorization to mutate threads.
9. Stop at merge-ready, owner approval, a conflict requiring new authority, or a real external blocker. Babysitting never authorizes merge or auto-merge.

Answer user questions during a drive and continue unless the user says stop. Report the mode, current frontier, blockers cleared, current head, and remaining gate.
