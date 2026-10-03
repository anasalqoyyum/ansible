# Durable subagents for Pi

Local Pi extension for child execution and persistence through `@earendil-works/pi-durable@1.0.0`. The parent stays on Pi's SDK runtime. Tested with Pi 1.0.0 and Node 26.10.0. The runtime requires Node 22.19 or later and Git for worktree isolation.

## Operations

- `Agent` accepts `prompt`, `description`, `subagent_type`, `name`, `run_in_background`, `model`, `thinking`, `inherit_context`, `isolation`, and `resume`. Background execution is the default. Foreground execution returns the child's final answer through the original call and cancels on parent Esc. Write-capable roles require authorization; see [Write authorization](#write-authorization).
- `get_subagent_result` accepts `agent_id`, optional `wait`, and optional `verbose`. IDs or unique names work. Failed and stopped work returns an error result. Verbose retrieval includes saved entries.
- `steer_subagent` accepts `agent_id`, `message`, and optional `follow_up`. Steering enters at the next tool-round boundary; follow-ups enter after the current answer. Either can continue an idle child.
- `stop_subagent` cancels active tools and queued requests, including reporter tasks that have not submitted their input yet. The transcript and checkout remain available.
- `cleanup_subagent_worktree` requires `agent_id` and the exact recorded `path`. Only use it after explicit user authorization. Interactive callers also receive a confirmation dialog.

`resume` uses the saved configuration. Do not combine it with a new model, thinking level, role, history setting, name, or isolation setting. A foreground resumed request is cancelled with its target child when the parent aborts.

Unsupported fields fail schema validation rather than being ignored. This includes legacy `isolated`, `max_turns`, `schedule`, workflow, and nested-delegation fields. MCP, fff, codemode, and other SDK extensions are not installed in children. Parent tools and MCP configuration are untouched.

## Fleet and inspector

A compact fleet appears below the editor. At an empty prompt, press Down or Left to select `main`, then use Up/Down to select an agent and Enter to open its inspector. Esc or Up past `main` returns to the prompt; typing also returns to the editor without losing the typed key. Fleet navigation leaves dialogs and nonempty prompts alone.

Finished agents show status-specific icons and linger for four seconds before disappearing from the compact fleet. An agent being inspected stays in the fleet until its inspector closes. This only changes visibility, not stored results or transcripts. `/agents` or Ctrl+Alt+A opens the full overview, including completed, failed, and stopped agents for this parent session. `/agents ID` opens an inspector directly.

The bordered inspector supports arrows, Page Up/Down, Home/End, and Markdown or raw output with `m`. Enter or `s` opens an inline steering composer; `f` opens an inline follow-up composer, including for a finished agent. Enter sends; Esc or an empty submission cancels the composer without closing the inspector. Admission errors retain the draft for retry. Press `x` twice to stop without closing the inspector. Esc closes it when no composer is open. It attaches a current Durable snapshot before listening for updates. Assistant text, thinking, tool arguments, tool output, and tool results are inspectable during and after execution. Token and estimated cost totals come from Durable's usage document, not SDK session impersonation. Parent SDK totals do not separately account for this child ledger.

`/agents implement on` and `/agents implement off` toggle session authorization for write-capable subagents. `/agents stop ID` stops one agent. `/agents cleanup ID EXACT_PATH` removes a clean, owned checkout after confirmation. Programmatic execution works without a terminal; custom screens are TUI-only.

## Models and credentials

`src/models.ts` passes normal and compaction requests through public `ModelRegistry` methods. Pi resolves credentials, provider overrides, custom endpoints, and request-time authentication. This extension does not read private SDK fields, write another auth file, or move the parent conversation into Durable. Deferred model requests are not supported.

Model and thinking precedence is:

1. Explicit `Agent.model` and `Agent.thinking`.
2. Values in the selected user-authored role definition.
3. For GPT parents, `gpt-6-luna` with `max`, matching the current shared subagent policy. For other parents, the parent's model and thinking level.

Use `provider/modelId` to avoid ambiguous IDs. A bare exact ID prefers the parent's provider. Selection validates the model catalog, credential availability, provider availability filters, and supported thinking levels before admission. It never silently selects another model. The shared GPT default is implemented explicitly; update it if the user's shared policy changes.

Resolved instructions, model, thinking, allowlist, history, and cwd are saved at creation. Recovery and continuation use those values instead of rediscovering role files. Credentials remain request-time Pi state and are not copied into SQLite.

## Roles and repository instructions

Built-in roles are `Explore`, `Plan`, and `general-purpose`. Load basic Markdown definitions from `~/.pi/agent/agents/` and the launch directory's `.pi/agents/`. `PI_CODING_AGENT_DIR` changes the user location. Project definitions override same-name user definitions; both override built-ins.

Supported frontmatter:

```yaml
---
name: reader
description: Inspect repository files
model: openai/gpt-6-luna
thinking: max
tools: [read, bash]
---
Inspect the requested files. Do not change files or Git state.
Use bash only for read-only inspection.
```

Only `name`, `description`, `model`, `thinking`, `tools`, and `approved` are supported. Tools can be a YAML string array or a comma-separated string. Unsupported fields fail when that role is selected; malformed YAML or invalid field types fail discovery. A definition without a name uses its filename. A custom definition without a tools field gets all four coding tools. `Explore` and `Plan`, including overrides of those names, cannot select `write` or `edit`.

Instructions load independently of parent-history inheritance. The extension reads user instructions, then ancestors from the filesystem root through the parent launch cwd. It reads `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, and Markdown files below `.claude/rules/`. `AGENTS.override.md` replaces AGENTS/CLAUDE in its own directory. Realpath deduplication prevents a symlinked instruction file from being included twice.

Rule frontmatter supports only `paths`, as a single glob or YAML array:

```yaml
---
paths: ['src/**/*.{ts,tsx}', 'test/**/*.ts']
---
Follow the project's TypeScript conventions in these files.
```

Patterns are globs relative to the directory containing `.claude`. Their matching examples are tested with Node's `path.matchesGlob`. Unscoped rules apply to all work. Scoped rules are saved in the initial prompt with their path conditions. They are instructions for the model, not filesystem permissions or dynamically activated hooks. Nested instruction files below the launch cwd are not automatically discovered. Full Claude frontmatter compatibility is not claimed.

Parent history is a separate opt-in and is supplied as serialized context. It does not load the parent's extensions or MCP tools. History can contain sensitive tool output; only inherit it when needed.

## Write authorization

A role is write-capable when its `tools` include `write` or `edit`. The parent may run those roles without a dialog when the role itself is the authorization:

- Roles installed in `~/.pi/agent/agents/` are trusted.
- Project roles in `.pi/agents/` are trusted only with `approved: true` in their frontmatter.
- Built-in `general-purpose` and any other built-in write-capable role require authorization.

Otherwise the extension asks before the child starts, or blocks the call. The dialog offers `Allow once`, `Allow for this session`, and `Deny`. A session authorization is stored as a `durable-subagents.policy` custom entry in the parent session, survives reload and session switching, and is managed with `/agents implement on` and `/agents implement off`. The footer shows `subagents: writes allowed` while it is on.

Without an interactive UI, print and JSON modes block a write-capable call that needs authorization and return an explanatory result: implement in the parent, or ask the user to run `/agents implement on`. Read-only roles are never gated. Resuming a child re-resolves its role name against current definitions, so a removed or renamed definition falls back to the authorization rules above.

## Coding tools and replay

The extension adapts Durable's text-file `read`, `write`, `edit`, and `bash` tools with `NodeExecutionEnv`. Paths and shell processes use the saved child cwd. Output limits, truncation notices, shell timeouts, and cancellation come from the pinned Durable implementation.

Allowlisting controls the actual offered and executable tools. Invented calls to unselected tools fail. Explore and Plan have no file-write tools, but unrestricted shell access makes them **prompt-restricted, not strictly read-only**. Shell commands can still write files or access credentials, networks, and external services.

File writes and edits hold Pi's public `withFileMutationQueue` around the complete operation, in addition to Durable's shared local-file coordination. Arbitrary shell mutations and external processes do not participate in those queues.

Replay policies:

| Operation             | Interrupted execution                                                                                        |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| `read`                | Safe to repeat; contents may have changed.                                                                   |
| `write`, `edit`       | Unsafe. The model receives an interruption instead of an automatic repeat.                                   |
| `bash`                | Unsafe, including seemingly read-only commands. A running process is cancelled when Pi closes.               |
| Foreground delegation | Stable parent-call mapping, durable ownership, and submission IDs reuse the same child and input.            |
| Background messaging  | A checkpointed reporter submits with its task ID and records result/outbox state atomically.                 |
| Worktree creation     | An ownership intent is synced before Git runs; recovery reconciles exact recorded branch/path/base identity. |

Abrupt OS termination cannot guarantee cancellation of a shell process already started. Inspect external effects after a crash. This does not make side effects transactional. A command or file mutation might have taken effect before its result was interrupted. Inspect before deciding whether to repeat it.

## Persistence and reporting

State lives outside maintained source in `<agent-dir>/durable-subagents/`. Each parent session ID has its own SQLite database. A separate SQLite exclusive ownership transaction prevents two runtimes from owning that session's storage, including within one process. The OS releases it after a process crash.

Foreground tasks own their initial child. Background children belong to completed background anchors, so parent Esc does not stop them. Each message has a durable reporter task and a stable submission ID. Stop also aborts pending reporter tasks to prevent a not-yet-submitted request from starting after the stop.

Results, configuration, ownership links, transcripts, usage, and report outbox entries persist. Reopening the same parent resumes pending work. Terminal Runner faults and orphaned receipts also reconcile into failed results and stable outbox reports, during the run and at startup. Another parent gets another roster and database. Closing Pi pauses execution; there is no daemon. Foreground child execution recovers in Durable, but Pi's SDK cannot reconstruct an in-process tool waiter lost in a crash. Retrieve the persisted result after restart.

Background success and failure reports use stable IDs. Reports start a parent turn when idle and queue as follow-ups when busy. The outbox remains pending until the report is visible in the parent's persisted active branch. Reopening reconciles existing report IDs before queuing missing reports. Notifications contain a preview; full results remain retrievable. Completed isolated-agent notifications include the checkout, branch, recorded base, and changed-file status.

Delivery crosses a Durable-to-SDK boundary. A crash during delivery or before the SDK transcript is durably saved can duplicate a report. This is recovery with ordinary deduplication, **not exactly-once delivery**. Reports cleared from the SDK queue by Esc can be retried after the parent settles.

## Worktree isolation

Set `isolation: "worktree"` only when isolated execution is wanted. The checkout starts from an explicitly recorded parent HEAD commit. Uncommitted parent files are not copied. Configuration and instructions resolve from the parent launch project; child tools run in the checkout.

Owned branches use `durable/<owner-hash>`. Intents, creation receipts, base commit, branch, path, repository, and parent-derived owner identity persist. Recovery reuses a matching checkout, including the crash window before roster metadata is stored. Missing retained checkouts or mismatched identity fail clearly; execution never falls back to the parent cwd.

Checkouts are retained. Cleanup verifies the exact ownership record and Git identity, requires the agent and queued requests to be idle, and refuses tracked, untracked, or ignored dirty files. It removes only the checkout and keeps the branch and ownership records. There is no force-cleanup option. A cleaned-up agent cannot continue until its recorded checkout is restored explicitly.

The extension never commits or merges agent work. Worktrees isolate repository files, not the machine, credentials, networks, or external services.

## Install and validate

Maintained source belongs in the Ansible repository at:

```text
dotfiles/pi/.pi/agent/extensions/pi-durable-subagents/
```

The repository's `.pi` workspace uses npm and includes `agent/extensions/*`. The root lockfile records this extension. From the `.pi` root, `npm ci --ignore-scripts` installs the workspace and `npm run typecheck --workspace=pi-durable-subagents` checks it.

The package also keeps a standalone lockfile for production deployment and isolated development. From its directory:

```sh
npm ci --workspaces=false --ignore-scripts
npm run typecheck
npm test
npm run test:live
```

Development checks and spacing fixes:

```sh
npm run lint
npm run lint:fix
npm run format
npm run format:check
```

Oxlint enables the vendored anti-slop rules, including structural blank lines. Oxfmt uses two-space indentation and a 100-column print width. The plugin is excluded from linting and formatting. Its source and snapshot checksums are recorded in `tools/oxlint/anti-slop/UPSTREAM.md`.

The last command in the test block is optional and billable. It makes one bounded Durable child request through the configured Pi credentials to `openai/gpt-6-luna` at `max`, checks `DURABLE_OK`, and deletes its temporary database. The deterministic suite covers SQLite reopen, stable admission, ownership, cancellation, real shell interruption, steering, configuration, allowlists, worktrees, report reconciliation, UI lifecycle, SDK reload/session switching, and fresh installed-CLI loading. It also tests cutover in a temporary target. Tests run sequentially to bound Pi/TypeBox memory use.

A production copy needs only:

```sh
npm ci --workspaces=false --omit=dev --omit=peer --ignore-scripts
```

Pi does not install local-package dependencies automatically. Durable and Chord are pinned to 1.0.0. Host Pi modules and TypeBox are declared as peers, following Pi's package contract. The existing `fix-host-dep-warnings.mjs` explains the old subagents manifest patch. This package does not patch installed manifests or change the host version.
