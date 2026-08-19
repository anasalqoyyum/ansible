# Feature

You own the user experience and the data shape.

1. State the user-visible behavior, acceptance boundary, and principal data structure or state model.
2. Ground the existing path with `how`. Use `codebase-design` or `architect` when ownership and seams are not obvious.
3. Compare alternative shapes when the interaction or architecture has no precedent. Choose from observed tradeoffs.
4. Write the throughput checkpoint. Name independent lanes, blocking foundations, and shared-write ownership.
5. Subtract obsolete structure first. Integrate the requirement into the existing model as if it had always existed.
6. Implement in small verifiable units. Add focused tests for meaningful behavior and expected failures.
7. Exercise the feature on its real surface. Run relevant static checks and inspect the produced artifact.
8. Apply `no-comments` and review the final diff.
9. Run Opening a PR only when authorized. Run Babysit only when requested.

Report the user-visible result, data shape, design choice, proof, and open tradeoffs.
