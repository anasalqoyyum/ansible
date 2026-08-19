# Rust tracing

- Resolve functions, inherent methods, closures, trait methods, macro expansions, and function pointers. Label trait-object or generic dispatch `inferred` when the concrete implementation is not proven at the call site.
- An `async fn` call constructs a future. Its body progresses when an executor polls it. Show `.await` as a suspension point when the continuation matters.
- A spawned future or thread starts a separate execution context. Join handles, channels, locks, and wakeups create causal edges rather than nested calls.
- Treat `?` as early error propagation from the enclosing function. Show the called operation and the resulting return or conversion, not `?` as its own call.
- Show `Drop` when scope exit or unwinding releases a lock, rolls back a guard, closes a resource, or triggers another visible effect.
- Distinguish `panic` unwinding from abort behavior using the repository profile and target configuration.
- For macros, cite the invocation and follow generated calls only when expansion changes the path. Do not invent source lines inside opaque generated code.
- Separate database transaction closures, commits, rollbacks, and async work started outside the transaction lifetime.

Use Cargo metadata, enabled features, target configuration, and compiler or rust-analyzer information when available. Feature-gated and platform-specific implementations must match the active build.
