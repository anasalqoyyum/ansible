# Autonomous run

You own the exit condition. Define done, then drive to it without stopping.

1. State a checkable predicate before the first iteration. Examples include a passing reproduction, a metric target, a zero image diff, or every named PR merge-ready.
2. Choose an event-driven wake mechanism when available. Otherwise use a polling interval appropriate to when external state can change.
3. Each iteration makes the smallest evidence-backed move, verifies the predicate, and records the decision.
4. Keep changes that advance the predicate. Discard speculative changes that do not.
5. Handle reversible in-scope discoveries and return to the main predicate. Keep separable fixes separate when repository and Git authorization permit.
6. Pause only for missing authority, irreversible action, product intent, user stop, or a genuine dead end. A plateau requires a changed hypothesis, not a weaker predicate.
7. Stop when the predicate is met and report the trail, accepted and discarded changes, and final evidence.
