# Tracing other languages

Use the repository's compiler, language server, call hierarchy, framework configuration, and tests when available.

Resolve direct calls first. Then trace dynamic dispatch, callbacks, handlers, dependency injection, generated code, async scheduling, concurrency, process boundaries, and persistence only as far as evidence supports them.

Keep these distinctions explicit:

- static call edge versus observed runtime edge;
- native stack versus logical continuation;
- synchronous call versus scheduled or concurrent work;
- local function dispatch versus network, queue, event, or process handoff;
- proven target versus inferred target.

Record the evidence basis in `values.evidence`. If the language or framework semantics are uncertain, consult its primary documentation or source before drawing the edge.
