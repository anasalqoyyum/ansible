---
name: benchmark-checklist
description: Validate a performance measurement before reporting or acting on it. Use for benchmarks, speedup or regression claims, performance comparisons, and hillclimb harnesses.
---

# Benchmark checklist

Test the claim you plan to report, not merely the benchmark's output. Answer each applicable question with evidence from a run.

For a requested ballpark, one run is enough. Check errors and completed work, and label the result as one run. Choosing between implementations or configurations requires the full comparison.

## Frame the measurement

- Write the claim with its workload, metric, environment, and expected decision.
- Read what the harness times, counts, and excludes. Confirm that the result could change the decision.
- Record system load and relevant resource counts. If the machine is busy, interleave the compared runs and disclose the remaining noise.

## Validate

1. **Name the limiter.** Profile outside the reported measurement. Use process counters, a runtime profiler, I/O waits, or syscall counts, then map the bottleneck to source. Check the load generator too. A change that cannot move the limiter is not evidence that the change is useless.
2. **Compare production-equivalent configurations.** Match release builds, flags, versions, data, batching, pools, and cache state. If one side remains untuned, report an inconclusive comparison rather than choosing a winner.
3. **Check physical and arithmetic bounds.** Compare throughput with disk, network, and CPU capacity. A saving cannot exceed the time spent in the changed component.
4. **Count errors and validate output.** Fast failures and slow retries distort timing. Check correctness, not just the presence of output.
5. **Measure repeatability.** For comparisons, alternate sides for at least five runs each. Report medians and ranges. Treat an effect within run-to-run variation as unmeasured. Use a suitable statistical test for close decisions.
6. **Measure the user-relevant path.** Put micro results beside an end-to-end measurement with realistic data and concurrency. Report the changed component's share of total time.
7. **Prove the work happened.** Confirm requests arrived, rows were written, bytes were read, and lazy computations were consumed inside the timed region.

## Report

Lead with faster, slower, no measurable difference, or inconclusive. Include the value and unit, runs per side, range, and limiter. Keep supporting runs and environment details in an artifact when the main report needs one number.

Call the result inconclusive when a claimed difference lacks a named limiter, comparable tuning, error checks, or proof of completed work.
