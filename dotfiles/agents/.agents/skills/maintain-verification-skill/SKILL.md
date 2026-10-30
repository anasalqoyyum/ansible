---
name: maintain-verification-skill
description: Check and repair a project-local verification skill and its feature map against current source and live behavior. Use for verification-skill drift audits or after application changes that bypassed the verification workflow.
disable-model-invocation: true
---

# Maintain a verification skill

Reconcile every mapped feature with source, then exercise every feature live. Change only the verification skill, its feature map, and its helpers. Report product regressions instead of editing product code or rewriting the map to hide them.

## Outcome

Finish with one outcome:

- `clean`: every feature received source and live coverage, with no required corrections.
- `changed`: verified corrections changed the verification files.
- `blocked`: coverage could not finish or a correction could not be verified. Name the uncovered features and cause.

## Pass

1. **Locate the target.** Use the named skill or find the project-local `verify-*` skill with launch and drive instructions plus a feature map. If several unqualified candidates exist, ask which to maintain. If none exists, use `create-verification-skill` when requested.
2. **Reconcile the index.** Read the feature-map index and its sibling files. Identify missing, extra, duplicate, and dead entries.
3. **Read source.** Cover every feature. Assign independent read-only exploration when useful. Return each feature's source entry points, likely documentation drift with citations, and one live-verification recipe. Source readers do not drive the app or edit files.
4. **Plan the live pass.** Account for every feature and combine compatible journeys. Check recently changed user-facing files for unmapped features. A missing feature needs a concrete source path.
5. **Drive every feature.** Follow the verification skill's own launch and isolation model. Use its available browser, device, PTY, HTTP, or application control tooling. Keep one coordinator in charge of a shared app instance.
6. **Classify findings.** Correct inaccurate user guidance and broken verification helpers. Record product gaps separately. Run every helper correction against the live app.
7. **Finish cleanly.** Tear down everything started by the run and confirm evidence persists. Commit or open a PR only when separately authorized.

## Live invariants

- Run doctor before the first drive and after each failed or surprising drive. Reset or relaunch when doctor cannot detect a wedged interface.
- A feature is `verified-unreachable` only after recording its missing prerequisite and attempted route. Add omitted prerequisites to the map.
- Preserve all evidence at its documented location through every cleanup, including failed iterations.
- Clean up processes, sessions, and scratch state created by each drive. For a shared instance, clean the drive's residue without stopping someone else's process.

Report the outcome, features covered, drift corrected, product gaps, unreachable prerequisites, and evidence paths.
