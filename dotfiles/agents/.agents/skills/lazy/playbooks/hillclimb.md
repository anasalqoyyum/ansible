# Hillclimb

You own a sustained climb of one metric. Keep a decision trail and one independently verifiable step per accepted win.

1. Define the metric, workload, environment, target, regression gate, and stopping condition.
2. Record a stable baseline before any change.
3. Build a ranked hypothesis queue. Each hypothesis must name a mechanism, expected movement, and disconfirming result.
4. Write the throughput checkpoint. Run independent hypotheses in isolated worktrees only when their writes cannot collide.
5. For each hypothesis, change one mechanism, measure it under the same conditions, and keep or discard it from evidence.
6. Verify every accepted win against correctness and runtime behavior before stacking the next.
7. Stop at the target, a demonstrated measurement floor, or a genuine dead end. A plateau alone requires a new hypothesis, not a relaxed target.
8. Apply `no-comments`. Publish the accepted sequence only when the user authorized Git and PR operations.

Report the climb, rejected hypotheses, accepted steps, final metric, and stopping reason.
