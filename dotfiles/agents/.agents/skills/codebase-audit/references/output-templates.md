# Output Templates

Use the smallest template that satisfies the active mode.

## Architecture map

```text
System shape:
- Applications/packages:
- Entrypoints:

Primary flow:
client/input → route/handler → service → database/external system → response

Trust and state boundaries:
- Authentication:
- Authorization/ownership:
- Validation:
- Persistence/transactions:
- External failures:

Verification surface:
- Tests:
- Type checking/linting:
- CI:

Highest-risk files:
1. path — reason
2. path — reason
```

## Ranked findings

| Priority | Finding | Evidence | Impact | Confidence | Fix cost | Decision |
|---:|---|---|---|---|---|---|
| 1 | Concise defect | `path:line` and reachable path | Critical/High/Medium/Low | High/Medium/Low | Low/Medium/High | Fix/Investigate/Document/Discard |

For each selected finding:

```text
Trigger:
Consequence:
Root cause:
Existing guard checked:
Smallest fix:
Focused verification:
Compatibility concern:
```

## Investigation result

```text
Conclusion: Confirmed | Rejected | Unresolved

Suspected failure:
Execution path:
Decisive evidence:
Guards and alternate paths checked:
Root cause:
Behavior to preserve:
Smallest safe fix:
Verification plan:
```

## Fix handoff

```text
Changed:
- path — necessary change

Verification:
- command — actual result

Compatibility:
- preserved behavior
- remaining risk or migration note

Suggested atomic commit:
fix(scope): concise root-cause-oriented description
```

## Final justification

```text
Problem:
Describe the incorrect reachable behavior.

Impact:
Describe who or what is affected and how.

Root cause:
Identify the underlying missing invariant, guard, or incorrect assumption.

Fix:
Explain the minimal change and why it belongs at that layer.

Backwards compatibility:
State preserved contracts, intentional changes, and any migration path.

Verification:
List only tests or checks that actually ran and their results.
```

## Unresolved finding

```text
Finding:
Evidence:
Risk:
Why not changed:
Recommended next step:
```
