# Bug fix

You own the reproduction and the root cause.

1. Reproduce the defect on the same user-facing or runtime surface. If the environment cannot reproduce it, state the missing condition and gather the strongest available evidence before editing.
2. Apply `diagnosing-bugs`. Trace the symptom through state and boundaries until one owning cause explains it.
3. Write the throughput checkpoint. Parallelize independent investigation or verification lanes. Keep one writer for the owning code.
4. Add the narrowest meaningful failing test or executable check when it strengthens the reproduction.
5. Sketch the corrected data shape or boundary when the fix crosses modules. Remove obsolete workarounds.
6. Implement the smallest root-cause fix.
7. Re-run the original reproduction, focused tests, and relevant static checks. Verify the real artifact.
8. Apply `no-comments` and inspect the final diff for scope drift.
9. Run Opening a PR only when publication was explicitly requested. Run Babysit only when the user requested PR follow-through.

Report the reproduction, cause, fix, and before-and-after proof.
