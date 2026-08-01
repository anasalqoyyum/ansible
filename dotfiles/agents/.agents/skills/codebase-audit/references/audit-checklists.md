# Audit Checklists

Load only the categories relevant to the repository and request. A checklist item is a search direction, not a finding. Report it only after tracing a reachable path and concrete consequence.

## Security

- Authentication without resource-level authorization
- User, tenant, role, or ownership identifiers trusted from request input
- Alternate routes that bypass guards
- SQL, NoSQL, template, shell, path, or header injection
- Unsafe HTML rendering or output encoding
- Unsafe redirects and user-controlled URLs, including SSRF
- Weak session, cookie, token, CORS, or CSRF handling
- Secrets or sensitive values exposed through source, logs, errors, or responses
- Mass assignment and over-broad object updates
- Missing size, type, or content validation at trust boundaries
- Sensitive information revealed by distinct authorization error behavior

## Reliability

- Swallowed errors or failures converted into successful empty responses
- Missing timeouts, cancellation, or cleanup for external operations
- Non-idempotent writes inside retries
- Partial multi-step writes without transaction or recovery strategy
- Race conditions and check-then-act behavior
- Unhandled promises, event handlers, or background jobs
- Retry storms, missing backoff, or retrying permanent failures
- Resource leaks involving files, streams, sockets, timers, or subscriptions
- Invalid state transitions or assumptions about operation ordering
- Error paths that leave stale locks, loading states, or database records

## Performance

- N+1 database or network access
- Independent operations executed sequentially
- Unbounded `Promise.all`, queues, or fan-out
- Queries without pagination, bounds, projection, or appropriate filtering
- Large objects or files loaded fully when streaming or selecting fields is sufficient
- Duplicate frontend requests, unstable effect dependencies, or render loops
- Expensive parsing, serialization, cryptography, or transformation in hot request paths
- Repeated computation or lookup with measurable cost
- Missing indexes only when query shape and expected scale justify the claim
- Backpressure ignored in stream or queue processing

## Developer tooling

- Workspace packages omitted from test, lint, or type-check commands
- CI and documented local commands exercising different code paths
- Failures ignored through permissive flags or shell behavior
- Environment defaults that silently target unsafe services
- Non-deterministic dependency installation or inconsistent lockfile use
- Tests dependent on order, time, network, or shared mutable state
- Configuration inheritance that excludes important files
- Deployment artifacts derived from stale or different source inputs
- Secrets passed unsafely through CI configuration or logs

## Backwards compatibility

- Response shape, status code, header, or error semantics changed
- Ordering, pagination, default value, or nullability changed
- Previously valid inputs rejected without a migration path
- Existing stored data violates a new invariant
- Clients depend on a deprecated field or behavior
- New authorization behavior leaks resource existence
- Performance changes alter result ordering or concurrency semantics
- Retry or timeout changes make writes observable more than once
- Schema changes require phased reads/writes or backfill

## Evidence test

Before reporting a finding, answer:

1. What input, request, state, or failure triggers it?
2. Which exact path carries the trigger to the outcome?
3. What guard might prevent it, and was that guard checked?
4. What concrete harm or broken behavior results?
5. Why is the identified code the root cause rather than a symptom?
6. What minimal test or reproduction would prove it?
7. What legitimate behavior must a fix preserve?
