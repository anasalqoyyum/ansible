# Orchestrate

You own the program, not every line of code. Use only for a standing multi-unit effort that outlives one ordinary task.

## Roles

- The coordinator frames units, owns the board and human report, controls shared topology, and makes cross-unit decisions.
- One owner carries each unit from brief to verified result. Give each owner disjoint write scope or an isolated worktree.
- Independent verifiers inspect exact heads or artifacts and return evidence, not confidence statements.
- Add sub-coordinators only when one coordinator cannot drain and synthesize the active tracks.

Every delegate inherits the current session model. Omit model overrides.

## Loop

1. Define the program predicate, tracks, unit schema, dependency graph, authority boundary, and durable state location.
2. Write complete briefs. Each brief names outcome, scope, exclusions, data shape, owner, verification, and return format.
3. Write the throughput checkpoint. Cap in-flight work at what the coordinator can review without losing the frontier.
4. Dispatch only ready units. Keep one writer per shared file, branch, PR topology, or state record.
5. Drain completed work in batches. Review evidence and diffs before marking a unit verified.
6. Keep the lowest dependency frontier green. Do not spend the program on upstack polish while a root unit blocks everything above it.
7. Re-plan from evidence. Split oversized units, retire obsolete units, and record material decisions.
8. For publishing, babysitting, or landing, use the host-aware PR playbooks and the user's explicit authority.
9. Stop when the program predicate is met, the user pauses it, or continuation needs new authority.

Report the board, frontier, verified units, active owners, decisions, blockers, and durable resumption point.
