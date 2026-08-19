# Performance issue

You own one measured regression from trace to comparison.

1. Name the workload, metric, environment, and target. Capture a repeatable baseline and a green correctness gate.
2. Profile or instrument the real workload. Attribute the cost to source before editing.
3. Write the throughput checkpoint. Separate measurement, architecture tracing, and independent verification where useful.
4. Plan the fix from the evidence. Sketch boundaries first when the change crosses modules.
5. Implement one causal change. Capture the post-fix trace under comparable conditions.
6. Compare the metric, trace, correctness gate, and user-visible behavior. Revert changes that do not earn a measurable win.
7. Apply `no-comments`. Run Opening a PR only when authorized.

Report the baseline, attribution, changed mechanism, after measurement, and remaining variance.
