---
name: show-me-your-work
description: Keep an append-only decision log for long-running, autonomous, multi-phase, or handoff-sensitive work. Use when decisions and evidence must survive a handoff or later review.
---

# Show me your work

Keep one TSV log per effort. Record decisions and checkpoints, not every action. The columns are `ts`, `phase`, `decision`, `why`, `evidence`, and `result`. Evidence is a path, URL, commit, command artifact, or concise check result.

## Log

Use `scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>`. Resolve the script from this skill's directory. It creates the header, adds a UTC timestamp, normalizes cells to one line, and escapes spreadsheet formula prefixes.

Start with [the header template](references/decision-log-template.tsv) if writing the file directly. A row should answer what changed, why, where the proof is, and what happened. Log chosen forks, completed verification units, pivots, reverts, blockers, and gates.

A conversation or replacement agent is one run. When appending to an existing log, read its recent rows first. The first row of each run uses phase `start`, names the timestamp range inherited from prior runs, and identifies the current run in evidence.

## Storage and audit

Keep the log local by default, such as `decisions.tsv` in the working directory or `.audit/<task-slug>.tsv` for concurrent efforts. Respect repository ignore rules. Commit or publish only when authorized and useful to the reviewer.

The log is append-only. Correct a wrong or unsupported row with a later row that supersedes it. Before handoff, check each row from this run against the actual artifacts. When the runtime exposes the current transcript, use it to catch omitted decisions. Otherwise audit against available files, command results, and external state, and disclose the limit.

An independent reviewer can check evidence quality and risky decisions when available and worth its cost. This is optional, not a reason to block completion.

Read a log in a terminal with `column -s$'\t' -t <logfile>`.
