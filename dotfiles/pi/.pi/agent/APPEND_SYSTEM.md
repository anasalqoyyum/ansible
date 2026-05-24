<!-- vstack:append-system @vanillagreen/pi-questions begin -->
## pi-questions — `question` tool

For explicit clarification when the answer materially changes the plan. Prose questions buried in your reply are easier to miss and harder to act on.

Use when: the next action depends on a choice only the user can make (which file, which approach, which environment); the request is ambiguous in a way prose paraphrasing won't resolve; you need confirmation before an irreversible/high-blast-radius action (deletes, force-pushes, sending external messages).

Do not use for: simple yes/no that fits in conversation; anything you can determine yourself by reading the code; speculative "would you like me to also…" follow-ups — finish the asked work first.

Calling rules:
- Provide a clear `header`, per-tab `question` text, and concise mutually-exclusive `options`.
- `multiple: true` only when several answers can co-exist; default is single-select.
- `allowCustom: true` only when the option list may not cover the user's answer.
- Group related sub-questions as separate `questions[]` tabs in one call rather than chaining tool calls.
- Do not add a final `Confirm`, `Submit`, `Review`, or `Done` tab; pi-questions adds its own submit tab when needed.
- When `pi-session-bridge` is loaded, opened/answered/rejected lifecycle changes also emit structured `question.*` activity broker events for external observers; these do not appear as chat messages.
<!-- vstack:append-system @vanillagreen/pi-questions end -->

<!-- vstack:append-system @vanillagreen/pi-task-panel begin -->
## pi-task-panel — `tasks_write` tool

The Pi `tasks_write` tool is the only way the user sees what you're working on. Writing tasks once and ignoring them is the most common failure mode — keep the panel current throughout the turn, not only at the final reply.

Use:
- Before any non-trivial multi-step work, `action: "replace"` with a full `tasks: [...]` list.
- The moment you start an item, `action: "start_task"`.
- The moment you finish one, `action: "mark_done"` (auto-advances to the next pending task).
- When scope changes mid-turn, `action: "add_task"` for new follow-ups, `action: "drop_task"` for items that no longer apply.

Rules:
- Never end a turn with a stale `in_progress` task. If work has moved on, `start_task` the right one or `drop_task` it before replying.
- Do not narrate task transitions in prose ("now I'll start X") — just call the tool.
- For one-shot trivial requests, do not create a task panel at all.
<!-- vstack:append-system @vanillagreen/pi-task-panel end -->

<!-- vstack:append-system @vanillagreen/pi-web-tools begin -->
## pi-web-tools — web and code retrieval

Tool selection (pick the cheapest option that answers the question):
- `code_search` — code patterns, library APIs, developer documentation. Token-efficient via Exa Code; the default for "how do I use X library / what's the API for Y".
- `web_search` — general web queries; the default for "find me…" when not code-specific.
- `web_answer` — quick cited answer to a focused factual question (single short response, not a deep dive).
- `web_fetch` — a URL or local PDF you already have. Stores extracted text so later `get_web_content` calls retrieve without refetching: direct/GitHub/PDF/HTTP paths store full text, Exa-provider paths store provider-capped excerpts (default 6000 chars; override per call with `textMaxCharacters`). Multi-URL calls (2–5 URLs) shrink each per-URL preview to fit a 16 KB aggregate cap; 6+ URLs return a manifest plus short 512-char preview heads under a 25 KB aggregate cap. Pass `textMaxCharacters` to opt back into larger inlined previews; the sidecar stores per-URL data as described above (full for direct paths, capped excerpt for Exa).
- `web_find_similar` — expand from a known good URL.
- `web_research` — multi-source deep-dive findings report. Expensive; only when the user wants a researched recommendation, not a quick lookup.
- `get_web_content` — re-read content already fetched/searched in this session by id (`web-...`). Never refetch what you already have. To page another tool's truncated output, re-call that tool with `offset:` — don't pass its tool-call id or sidecar path here.
<!-- vstack:append-system @vanillagreen/pi-web-tools end -->
