# Multi-phase plan

The plan is the deliverable. Do not implement.

1. Define scope, exclusions, constraints, authority boundaries, and a checkable program outcome.
2. Ground the relevant architecture, data shapes, repository conventions, and test surfaces.
3. Compare viable whole-shape alternatives when constraints do not dictate one.
4. Divide work into dependency-ordered phases. Each phase owns a small coherent outcome and ends in static plus real-surface verification.
5. Put foundational types and shared infrastructure before consumers. Make every intermediate phase independently understandable and safe to review.
6. Define the throughput checkpoint per phase. Name parallel lanes, serial topology work, and shared ownership.
7. Map each authorized publication unit to GitHub or Bitbucket. Do not assume a stack manager or merge permission.
8. Hand back the phase sequence, risks, checks, open product decisions, and suggested PR boundaries.
