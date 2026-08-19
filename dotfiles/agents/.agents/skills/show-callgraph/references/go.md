# Go tracing

- Resolve package functions, methods, closures, deferred functions, middleware wrappers, and interface calls. Label interface dispatch `inferred` unless construction or assignment proves the concrete type.
- A `go` statement starts a concurrent root. Show the spawn as a boundary and trace the goroutine in its own context.
- A channel send and matching receive form a causal handoff, not a nested call. Do not claim a specific receiver when several can consume the value unless the code proves it.
- Show `defer` at function return in last-in, first-out order when cleanup, unlock, rollback, recovery, or response mutation matters.
- Treat `panic` as stack unwinding. Show `recover` only inside a deferred function that can actually observe it.
- For `net/http`, trace router selection and middleware wrapping from registration to the concrete handler. Request context propagation carries cancellation and values but is not itself a call edge.
- Distinguish database transaction callbacks, commits, rollbacks, and work outside the transaction.

Use `go list`, `go doc`, tests, and compiler or language-server information when available. Build tags, generated files, and platform-specific implementations must match the active repository configuration.
