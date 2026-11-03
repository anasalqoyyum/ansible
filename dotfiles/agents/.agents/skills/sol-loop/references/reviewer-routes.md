# Reviewer routes

Select the route using the current host's rules, the user's preference, and the
required reviewer model and effort. Read only the relevant sections below.
Check the current tool schema or CLI help before launching; a similarly named
`Agent` tool in another client can have different arguments and model support.
Keep the reviewer in the same checkout so it sees uncommitted and untracked
changes. A separate Git worktree omits them unless explicitly transferred.

## T3 Code

Follow T3's orchestration rules. Discover `orchestrator_capabilities`, then use
a fresh `delegate_task` for each round with the model in `target.model` and
the supported effort option in `target.options`.
Follow the returned `next` instruction and collect the completed result.
An unavailable requested provider or model is a blocker; do not bypass the
host's routing rules with a CLI. Reviewers never watch PRs or start more agents.

## Herdr-core from Codex, Claude Code, or Pi

Outside T3, prefer [herdr-core](../../herdr-core/SKILL.md) when its use is
authorized and `hc` is installed. It works without a Herdr TUI or a parent
`HC_TERMINAL_ID`. Follow the skill's consent rule when outside core; existing
user authorization to use it is sufficient. Read `hc --skill` and `hc templates`.
Use a fitting template only if its actual command selects the required model
and effort. If no template fits, start an interactive reviewer directly.

Use a unique task-owned terminal name, the exact checkout path, and a complete
review brief. Pass prompt text as one argument, not executable shell text. For
a GPT reviewer through Codex, set these variables from the selected configuration:

```bash
hc run --bg --name "$reviewer_name" --cwd "$repo_path" codex --no-daemon --model "$reviewer_model" -c "model_reasoning_effort=\"$reviewer_effort\"" --sandbox read-only "$review_brief"
```

Codex requires `--no-daemon` under core so commands run inside its terminal.
Alternatively, select a model from Pi's registry and use its provider explicitly:

```bash
hc run --bg --name "$reviewer_name" --cwd "$repo_path" pi --provider "$reviewer_provider" --model "$reviewer_model" --thinking "$reviewer_effort" --tools read,bash --no-mcp "$review_brief"
```

When policy calls for a Claude reviewer, an interactive `claude` process with its
supported model and effort flags is another option. A Claude Code parent can
launch a GPT reviewer through Codex or Pi; the parent client does not constrain
the child model. All reviewers receive the read-only and no-delegation brief.
Pi's `bash` access is not a filesystem sandbox.

Read the returned terminal address and startup result. When `first_message.sent`
is present and false, inspect the terminal and resolve readiness before sending
the task. Never blindly resend after an ambiguous submission failure.

Wait and collect through the returned address:

```bash
hc wait "$reviewer_terminal" --timeout 30
hc read --lines 160 "$reviewer_terminal"
```

A timeout is a check-in, not approval. Wait again while the reviewer is working;
use `hc wait`, not a sleep or polling loop. Inspect `blocked` or `error` output
and follow the current permission rules. Do not force input through an approval
dialog. Only accept a complete verdict covering the current review snapshot.
For long reports, request a scratch-file result and read that artifact.

If the parent itself has a core terminal, give the reviewer that parent's exact
address for reports. Outside core, collect with explicit `wait` and `read`;
there is no parent terminal to receive `hc send` messages. Do not invent one.

For a later round, reuse the idle reviewer with `hc send --wait --timeout 30`
and the new brief and ledger, or start a fresh one after stopping the old one.
Once its final result is accepted, `hc kill` then `hc rm` only the terminal this
task created. Leave the user's core, other terminals, and configuration intact.
Keep agents interactive; `codex exec`, `claude -p`, and `pi -p` are not this route.

## Native Codex

When native delegation is the selected route, use the exposed subagent tools,
such as `spawn_agent` and `wait_agent`. Set the required model and effort using the
current schema. Use a fresh child when inheriting history would override those
settings. Supply the full review brief, collect its actual answer, and use the
supported follow-up tool for later rounds. No separate client is needed when
the native route supports the required reviewer configuration.

## Native Claude Code

Use Claude Code's `Agent` tool only when it supports the required reviewer model
and effort. For a foreground review set `run_in_background: false` and collect
the returned answer. Its native Claude model selection does not run GPT models.
When a GPT reviewer is required, use authorized herdr-core with Codex or Pi,
or the managed Herdr route below; do not substitute a Claude reviewer.

## Native Pi with pi-durable-subagents

When the installed extension exposes `Agent`, use an investigation role such as
`Explore` with the full review brief, a provider-qualified `model`, required
`thinking`, `run_in_background: false`, and `inherit_context: false`. Leave
worktree isolation off so the review includes the parent's working-tree changes.
Inspect a custom role's tools and instructions before using it.

Collect the full result with `get_subagent_result` when needed. Continue the
same child using `Agent` with `resume` and the next prompt; omit new model and
role arguments because the child retains its configuration. Failed or stopped
results are not approval. If the extension is absent, use an authorized Herdr
route rather than inventing a built-in Pi subagent tool.

## Managed Herdr TUI

Use [herdr](../../herdr/SKILL.md) when the user requests or permits that route
and `HERDR_ENV=1`. Follow its discovery, sibling-pane, agent start, prompt,
wait, read, and cleanup procedure. Select the client that supports the required
reviewer model and pass its native arguments after `--`. Reuse only the reviewer
this task owns. Outside a managed pane, use core or a supported native route;
do not attach to or control another focused Herdr session.
