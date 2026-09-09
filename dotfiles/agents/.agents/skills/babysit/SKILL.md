---
name: babysit
description: Watch a pull request or review cycle until it is ready to merge. Works with GitHub via gh and Bitbucket via bkt. Use when asked to babysit, monitor, or keep checking PR comments, reviews, and CI until all actionable issues are resolved.
---

# Babysit PR

Stay with the PR until it is actually clean. Do not stop after one check pass if comments or review threads are still unresolved.

## Workflow

1. Identify the host (GitHub or Bitbucket), the PR number, branch, and base branch.
2. Confirm the PR is not draft and inspect mergeability, checks, review decision, comments, and review threads.
3. Watch pending checks until they finish. Poll at a practical interval, usually 30-60 seconds unless the user asks for a different cadence.
4. Read new comments and unresolved review threads. Treat bot summaries as useful, but verify actionable findings against the code.
5. Fix real issues in focused commits, run relevant tests/builds, push, and return to step 2.
6. Resolve stale review threads only after verifying the code or generated artifact now addresses the comment.
7. Stop only when checks are passing or intentionally skipped, review decision is acceptable, no actionable comments remain, and no unresolved review threads remain.

## Pick the Host

```bash
git remote get-url origin
```

- `github.com` → use `gh` ([GitHub section](#github-gh)).
- `bitbucket.org` or a Data Center host → use `bkt` ([Bitbucket section](#bitbucket-bkt)).

Confirm the tool is authenticated before the first poll: `gh auth status` or `bkt auth status`.

## GitHub (gh)

Use `gh pr view` for the coarse status:

```bash
gh pr view <number> --json \
  number,state,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefOid,statusCheckRollup,url
```

Resolve the repository owner/name before using GraphQL:

```bash
repo_json=$(gh repo view --json owner,name)
owner=$(jq -r '.owner.login // .owner.name' <<<"$repo_json")
repo=$(jq -r '.name' <<<"$repo_json")
```

Use GraphQL for unresolved review threads. Include `pageInfo`; omit `cursor` on the first page, then pass the previous `endCursor` with `-f cursor="$cursor"` while `hasNextPage` is `true`.

```bash
gh api graphql \
  -f query='query($owner:String!,$repo:String!,$number:Int!,$cursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100,after:$cursor){pageInfo{hasNextPage endCursor}nodes{id,isResolved,isOutdated,path,line,comments(last:1){nodes{author{login},body,createdAt,url}}}}}}}' \
  -f owner="$owner" -f repo="$repo" -F number=<number>
```

Use this loop when a PR may have many review threads:

```bash
thread_query='query($owner:String!,$repo:String!,$number:Int!,$cursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100,after:$cursor){pageInfo{hasNextPage endCursor}nodes{id,isResolved,isOutdated,path,line,comments(last:1){nodes{author{login},body,createdAt,url}}}}}}}'
cursor_args=()

while :; do
  page=$(gh api graphql -f query="$thread_query" -f owner="$owner" -f repo="$repo" -F number=<number> "${cursor_args[@]}")
  printf '%s\n' "$page" | jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved==false)
    | [.id,.path,(.line//""),(.isOutdated|tostring),(.comments.nodes[-1].author.login//""),(.comments.nodes[-1].body|gsub("\n";" ")|.[0:240])]
    | @tsv'

  jq -e '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' >/dev/null <<<"$page" || break
  cursor=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$page")
  cursor_args=(-f cursor="$cursor")
done
```

Filter unresolved threads with `jq`:

```bash
jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved==false)
  | [.id,.path,(.line//""),(.isOutdated|tostring),(.comments.nodes[-1].author.login//""),(.comments.nodes[-1].body|gsub("\n";" ")|.[0:240])]
  | @tsv'
```

Resolve a stale thread only when the fix is verified:

```bash
gh api graphql \
  -f query='mutation($threadId:ID!){resolveReviewThread(input:{threadId:$threadId}){thread{id,isResolved}}}' \
  -f threadId=<thread-id>
```

## Bitbucket (bkt)

`bkt` covers both Cloud and Data Center, but the review-state surface differs between them. Check which one you are on before relying on a command:

```bash
bkt auth status      # shows the host and whether it is cloud or dc
bkt context list     # active context, workspace/project, default repo
```

Repository targeting comes from the active context. Outside a repo the context covers, pass `--repo <slug>` and `--workspace <slug>` (Cloud) or `--project <KEY>` (DC).

### PR status

```bash
bkt pr view <id> --json --jq '.pull_request | {id,title,state,draft,
  source:.source.branch.name, head:.source.commit.hash,
  target:.destination.branch.name, url:.links.html.href}'
```

There is no single `reviewDecision` field. Derive it from participants:

```bash
bkt pr view <id> --json --jq '[.pull_request.participants[]
  | select(.role=="REVIEWER")
  | {who:(.user.display_name), state, approved}]'
```

Treat `state == "changes_requested"` as blocking and `approved == true` as satisfied.

### Checks

```bash
bkt pr checks <id> --json          # one snapshot of head-commit build statuses
bkt pr checks <id> --wait --interval 30s --timeout 30m
```

`--wait` polls with backoff and exits `0` when all builds pass, `1` when one fails, `8` when it times out with builds still pending. Prefer it over a hand-rolled sleep loop. Statuses are `SUCCESSFUL`, `FAILED`, or `INPROGRESS`:

```bash
bkt pr checks <id> --json | jq -r '.statuses[] | [.state,.key,.name,.url] | @tsv'
```

`bkt --jq` JSON-encodes its result, so pipe to `jq -r` whenever you want raw lines.

On Data Center, `bkt status pr <id>` reports the same head-commit statuses. On Cloud, `bkt status pipeline <uuid>` gives the per-step breakdown for a Pipelines run.

### Comments and unresolved threads

```bash
bkt pr comments <id> --details --json
bkt pr comments <id> --state unresolved --json   # Cloud only
```

Comment fields: `id`, `content.raw`, `user.display_name`, `created_on`, `updated_on`, `deleted`, `resolution` (`null` until resolved), `parent` (`null` on thread roots, otherwise `{id}`), and `inline` (`{path,from,to}`) on diff comments.

List open thread roots:

```bash
bkt pr comments <id> --details --json | jq -r '.comments[]
  | select(.deleted==false and .resolution==null and .parent==null)
  | [.id,(.inline.path//"-"),((.inline.to//.inline.from)//""),
     (.user.display_name),(.content.raw|gsub("\n";" ")|.[0:240])]
  | @tsv'
```

Two traps:

- `resolution == null` only means "never resolved". General activity comments and bot summaries have no resolution and will show up in `--state unresolved` alongside real threads. Judge each one on content; do not treat the count as a thread count.
- Data Center does not expose resolution status at all, so `--state` is rejected and every comment reads as unresolved. On DC, track actionable items through tasks instead.

Read a whole thread by following `parent`:

```bash
bkt pr comments <id> --details --json | jq -r --argjson root <comment-id> \
  '.comments[] | select(.id==$root or (.parent.id//0)==$root)
   | [.id,(.user.display_name),(.content.raw|gsub("\n";" ")|.[0:240])] | @tsv'
```

### Tasks

Tasks are the blocking checklist on both platforms — on DC they are blocker comments, on Cloud a first-class resource. Treat an incomplete task as an unresolved thread:

```bash
bkt pr task list <id> --json
bkt pr task complete <id> <task-id>
```

### Replying and resolving

Reply in the thread when the fix needs explaining, then resolve:

```bash
bkt pr comment <id> --text "Fixed in <sha>: <what changed>" --parent <comment-id>
bkt pr comments resolve <id> <comment-id>
```

`resolve` and `reopen` take the thread root ID, not a reply ID. Use `--details` to find the root before resolving. Resolve only after verifying the fix.

### Merging

```bash
bkt pr merge <id>                 # closes the source branch by default
bkt pr auto-merge enable <id>     # DC only; merges once checks and approvals land
```

Merge only when the user asked for it.

## Operating Rules

- Keep the watcher running while long checks are pending.
- If a generated file is part of the distribution, verify the source and generated artifact agree before resolving comments.
- If a bot reports an issue against stale code, confirm whether the thread is outdated or addressed in the latest head. On Bitbucket there is no `isOutdated` flag: compare the comment's `inline.path`/`inline.to` and `created_on` against the current head commit yourself.
- Before final reporting, do one fresh sweep of PR status, unresolved threads, recent comments, and local `git status`.
- Report concrete evidence: latest commit SHA, check names and results, unresolved thread count, tests run, and any dirty local files left untouched.
