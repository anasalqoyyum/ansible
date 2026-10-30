---
name: interrogate
description: Adversarially test a change, design, or plan and keep only findings proven by an executable reproduction or probe. Use explicitly for /interrogate, adversarial review, or blind-spot testing.
disable-model-invocation: true
---

# Interrogate

Try to break the scoped work. Report verified findings without applying fixes.

## Frame

Use the user's scope. Otherwise use the branch diff from its merge base, including working-tree changes. State the intended behavior from the request, specification, commits, and PR description. Ask when intent is genuinely ambiguous.

Define a rubric from the intent and choose independent attack lanes such as behavior, state transitions, failure handling, security boundaries, or integration contracts. Use only lanes relevant to the scope.

## Attack

Run the smallest direct probes yourself when they provide full coverage. Use independent read-only reviewers or isolated workers when distinct perspectives or environments would add evidence. Give every worker the same scope and intent, a separate scratch location, and this requirement:

> Prove each finding with a command, failing test, reproduction script, or observable output against the real code. For a design or plan, use a prototype or probe the current implementation. Report the exact steps, actual output, expected output, and affected intent. Leave out unexecuted concerns and style opinions. No findings is a valid result.

Workers may create scratch reproductions but may not change the scoped product files. Preserve the baseline and isolate writes.

## Verify

Rerun every reported reproduction independently. Keep a finding only when the observed failure violates the stated intent. Drop invalid, irrelevant, and non-reproducing claims. Merge findings with one root cause.

Report the intent, verified findings with reproduction evidence, and dropped-claim counts with reasons. Include coverage gaps and probes that could not run. Do not present an unexecuted risk as a verified finding.
