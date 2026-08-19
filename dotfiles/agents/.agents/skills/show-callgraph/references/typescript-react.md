# TypeScript and React tracing

Trace runtime behavior, not the type graph. Type aliases, interfaces, generics, and erased validation helpers are not runtime frames unless emitted code executes.

## TypeScript

- Resolve imports, re-exports, overload implementations, closures, method calls, and function-valued fields to their concrete implementation when the repository proves it.
- Mark union narrowing, schema parsing, serialization, and validation as boundaries only when runtime code performs them.
- Treat Promise continuations, timers, event listeners, workers, queues, and `fetch` as causal edges across an unwound or separate stack.
- For dependency injection, decorators, routers, and middleware, cite both registration and selected handler when framework dispatch creates the edge.
- When dynamic dispatch has several possible targets, include the target only if local configuration or types narrow it. Otherwise label the edge `inferred`.

## React

- Treat event handlers as later browser entry points, not children of render.
- Treat component rendering as React scheduler work. A JSX element does not prove a normal JavaScript call from parent component to child component.
- Place layout effects after commit and before paint. Place passive effects after commit. Show cleanup before the next effect or unmount when it matters.
- Separate render, commit, event, transition, Suspense retry, query callback, and server request contexts when the path crosses them.
- For TanStack Query or similar libraries, distinguish mutation or query functions from cache callbacks and component rerenders.
- For server components and actions, separate build or server execution from browser hydration and later client events.

Prefer repository versions and configuration over framework defaults. Cite framework or dependency source only when local code does not establish the dispatch behavior.
