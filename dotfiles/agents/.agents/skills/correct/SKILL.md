---
name: correct
description: Turn recurring agent mistakes into architectural, type, lint, runtime, or behavioral test guards. Use explicitly for /correct or a request to prevent repeated correction classes.
disable-model-invocation: true
---

# Correct

Find mistake classes with evidence of recurrence, then prevent each class at the strongest practical level. One-off preferences and judgment calls do not justify a new guard.

## Find the classes

Inspect recent corrections, reverts, review comments, agent instructions, and workaround comments. Group by the underlying mistake, not by file. A class needs at least two independent occurrences or an explicit user-confirmed recurrence. Cite the evidence.

## Prevent each class

Choose the first level that can enforce the rule:

1. **Architecture.** Give state one owner, remove duplicate paths, hide invalid imports, or derive duplicated lists from one source.
2. **Types or static checks.** Make invalid states unrepresentable. Add a focused lint or CI check whose error names the correct replacement. For an existing pattern, consider ratcheting only new occurrences.
3. **Behavioral tests.** Assert an observable contract that fails on the old mistake and survives internal restructuring.
4. **Documentation.** Reserve agent rules and comments for judgment that tooling cannot enforce.

Keep each fix within the authorized scope. Do not commit automatically.

## Prove the guard

Reintroduce a real past mistake in a scratch copy or reversible local edit and run the new check. Confirm that it fails for the intended reason. Restore the correct version and confirm that the check passes. Run the same check through the project's normal local and CI commands when available.

Where the repo tracks agent rules, map each repeated rule to its enforcing mechanism. Strengthen an existing unenforced rule rather than adding another copy. Remove a rule when its mistake can no longer occur.

Report each class, its recurrence evidence, chosen enforcement level, rejected stronger levels, failure proof, and remaining unencoded judgment.
