# Visual parity

You own pixel-equivalent output. The untouched baseline is the spec.

1. Capture a baseline for every required state and viewport before changing implementation.
2. Establish a repeatable screenshot and image-diff harness.
3. State the guardrails. Do not edit the baseline, weaken the harness, or restructure content solely to fool the comparison.
4. Migrate shared primitives before consumers. Assign one writer per component or isolated worktree when parallelizing.
5. Verify each component on matching fonts, browser or device, viewport, and interaction state.
6. Investigate every material delta. Preserve accessibility and interaction behavior alongside pixels.
7. Apply `no-comments`. Publish component batches only when explicitly requested.

Report each component's diff result, baseline location, interaction proof, and remaining work.
