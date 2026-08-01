---
name: codebase-audit
description: Audit, diagnose, repair, and review an unfamiliar software codebase through reusable evidence-driven stages. Use for timed technical assessments, inherited-project audits, security/performance/reliability/tooling reviews, root-cause investigations, surgical fixes, backwards-compatibility reviews, or concise engineering justifications. Supports independent map, audit, investigate, fix, review, summarize, and full 90-minute modes.
---

# Codebase Audit

Audit unfamiliar code without turning the exercise into a broad rewrite. Treat every mode as independently usable: reconstruct any missing context from repository evidence instead of assuming earlier stages ran.

## Select a mode

Infer the mode from the request. If the user explicitly names a mode, run only that mode.

| Mode | Default behavior | Output |
|---|---|---|
| `map` | Read-only | Architecture, data flow, trust boundaries, risky files |
| `audit` | Read-only | Ranked, evidence-backed findings |
| `investigate` | Read-only | Confirmed or rejected root-cause analysis for one issue |
| `fix` | May edit only when the user requested implementation | Minimal fix, focused verification, compatibility note |
| `review` | Read-only unless correction is requested | Regression and compatibility assessment of current changes |
| `summarize` | Read-only | Submission-ready technical justifications |
| `90-minute` or `full` | Follow all stages within the time budget | Map, ranked findings, fixes if authorized, review, summary |

Invocation examples:

```text
Use $codebase-audit map on this repository.
Use $codebase-audit audit, but do not edit anything.
Use $codebase-audit investigate this suspected authorization bypass.
Use $codebase-audit fix the highest-confidence critical issue.
Use $codebase-audit review my current diff for regressions.
Use $codebase-audit summarize the completed assessment.
Use $codebase-audit in full 90-minute mode.
```

## Apply the core rules

1. Read repository instructions before task work, including `AGENTS.md` and relevant `.claude/` guidance.
2. Respect the requested scope, time budget, and authorization. Review requests do not authorize edits. Never commit unless explicitly requested.
3. Preserve unrelated user changes and inspect the working state before editing.
4. Base every finding on a reachable execution path and cite concrete file locations. Mark uncertainty instead of inventing evidence.
5. Distinguish symptoms from root causes. Check middleware, validators, constraints, callers, and deployment assumptions that might already prevent the issue.
6. Rank by impact, confidence, fix cost, and regression risk. Do not prioritize style or speculative cleanup.
7. Prefer the smallest change that removes the root cause while preserving legitimate behavior.
8. Verify narrowly first, then broaden in proportion to risk. Never claim a command passed unless it ran successfully.
9. Do not modify generated files. Report defects in generated output or sources when repository policy prevents editing them.
10. Communicate concise evidence and decisions, not a diary of tool usage.

Read [audit-checklists.md](references/audit-checklists.md) when selecting audit targets or evaluating a suspected defect. Read [output-templates.md](references/output-templates.md) when formatting findings, justifications, or the final submission.

## Run `map` mode

Target 12 minutes in a timed exercise.

1. Inspect manifests, workspace configuration, entry points, routes, authentication, persistence, external integrations, tests, and CI.
2. Trace the principal path from user input to side effect or response.
3. Identify trust boundaries, ownership checks, state transitions, failure boundaries, and public contracts.
4. List high-risk files to inspect next. Do not report vulnerabilities unless the evidence is already sufficient.
5. Return a compact architecture map using the template in [output-templates.md](references/output-templates.md).

Do not attempt to read every line. Build a useful map, then trace risky paths deeply.

## Run `audit` mode

Target 13 minutes after mapping, or bootstrap a minimal map when run independently.

1. Use the category checklist in [audit-checklists.md](references/audit-checklists.md).
2. Trace candidate defects end to end. Test whether guards elsewhere invalidate them.
3. Exclude naming, formatting, broad modernization, and dependency warnings with no demonstrated application exposure.
4. Record exact evidence, trigger, consequence, root cause, smallest fix, verification, confidence, and cost.
5. Rank findings. Recommend at most three implementation targets for a 90-minute exercise.

Use this priority order:

```text
high impact + high confidence + low cost
high impact + high confidence + medium cost
medium impact + high confidence + low cost
everything speculative or broad: document or discard
```

## Run `investigate` mode

Use this mode before changing code, even when the user starts with `fix`.

1. State the suspected failure in falsifiable terms.
2. Trace the complete path from input or event to outcome.
3. Inspect alternate paths, middleware, validation, authorization, constraints, retries, and error handling.
4. Identify a reproduction, focused test, or decisive static proof.
5. Conclude `confirmed`, `rejected`, or `unresolved`.
6. If confirmed, identify the root cause, preserved behavior, smallest safe fix, and verification plan.

Do not implement an unresolved theory merely because it looks plausible.

## Run `fix` mode

In a full 90-minute exercise, allocate roughly 15 minutes per issue between minutes 25 and 70.

1. Run the `investigate` procedure first.
2. Add or adjust one focused test when practical. A test must reproduce the original failure, not merely exercise the new branch.
3. Make the smallest targeted change. Avoid neighboring refactors, new abstractions, and defensive handling unrelated to the trigger.
4. Preserve response shapes, status codes, ordering, defaults, stored-data assumptions, and valid historical inputs unless changing them is essential.
5. Run the narrowest relevant test or static check, then broader checks when time permits.
6. Review the diff for accidental changes.
7. Provide a concise compatibility note and an atomic commit message suggestion. Commit only when explicitly authorized.

Stop fixing and document the issue when the safe change requires an uncertain migration, broad contract change, or more time than remains.

## Run `review` mode

Target minutes 70 through 85 in a full exercise. Bootstrap from the current diff, repository contracts, and test evidence when run independently.

For every logical change, check:

1. Does it remove the stated root cause across all reachable paths?
2. Does valid existing behavior remain unchanged?
3. Did response shape, status, ordering, defaults, timing, or error semantics change?
4. Does existing data require migration or staged rollout?
5. Are retries, concurrency, partial failure, and cleanup still correct?
6. Does the test fail without the fix and pass with it?
7. Are any edits unrelated, generated, or broader than necessary?

Classify feedback as `must fix`, `document`, or `safe to ignore`. Do not reopen general auditing unless a changed path exposes a new regression.

## Run `summarize` mode

Target the final 5 minutes. Reconstruct facts from diffs, commits, tests, and notes; do not rely on unsupported memory.

1. Write one justification per logical fix using the template in [output-templates.md](references/output-templates.md).
2. State only verification that actually ran.
3. List unresolved findings only when evidence-backed.
4. Explain why unresolved items were not changed: time, uncertainty, migration risk, or scope.
5. Keep the summary concise enough for a reviewer to scan quickly.

## Run full `90-minute` mode

Use this schedule unless the user supplies another budget:

| Minutes | Stage | Exit condition |
|---:|---|---|
| 0–12 | `map` | Request, data, auth, persistence, test, and CI paths are known |
| 12–25 | `audit` | Findings are evidence-backed and ranked |
| 25–40 | `investigate` + `fix` issue one | Root cause fixed and narrowly verified |
| 40–55 | `investigate` + `fix` issue two | Independent minimal change verified |
| 55–70 | Third fix or strengthen completed work | No risky half-finished change remains |
| 70–85 | `review` | Compatibility and regression risks classified |
| 85–90 | `summarize` | Honest, submission-ready justification exists |

At minute 55, choose among a third fix, stronger verification, or documentation based on expected value. Favor completed, defensible work over issue count.
