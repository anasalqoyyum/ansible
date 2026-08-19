# Runtime forensics

You own a live diagnosis, not a fix.

1. Define the symptom, process, environment, and observation window.
2. Capture live evidence with the least intrusive instrumentation that can distinguish the leading hypotheses.
3. Reduce the evidence to the responsible thread, task, allocation path, event loop, syscall, or state transition.
4. Map runtime frames and identifiers back to concrete source symbols.
5. Repeat or vary one condition to distinguish cause from background activity.
6. Hand back the cited diagnosis, confidence, captured artifacts, and next experiment. Re-route to Bug fix or Performance issue only when the user asks for a repair.

Do not edit code merely because a plausible cause appeared.
