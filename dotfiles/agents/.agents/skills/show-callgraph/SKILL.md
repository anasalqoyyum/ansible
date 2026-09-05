---
name: show-callgraph
description: "Build an interactive standalone HTML call graph from repository evidence."
disable-model-invocation: true
---

# Show callgraph

Generate one standalone HTML file that explains how a real feature moves through code, async boundaries, processes, storage, and failure paths. Treat it as an evidence-backed causal graph, not a literal native stack.

Do not modify production code. Read the repository, build the artifact, verify it, and return a link to the HTML file.

## Map the feature

Resolve the requested entry point or user-visible operation. If the request names a broad feature, choose the smallest set of scenarios that explains it and state the choice in the artifact.

Detect the languages on the selected path, then read the matching guidance before tracing:

- TypeScript or React: [references/typescript-react.md](references/typescript-react.md)
- Go: [references/go.md](references/go.md)
- Rust: [references/rust.md](references/rust.md)
- Any other language: [references/other-languages.md](references/other-languages.md)

Follow direct calls, callbacks, registered handlers, framework dispatch, async work, process or network boundaries, persistence, and relevant returns or errors. Read implementations rather than inferring behavior from names. Include generated or dependency code only when it changes the explanation.

## Keep the graph honest

Every step needs:

- a symbol or event name;
- an execution context;
- one of `call`, `boundary`, `effect`, `error`, or `return`;
- a real `file:line` source location;
- a short source excerpt;
- the state or payload that matters at that point;
- the causal next step and native-stack state.

Use `values.evidence` to label the basis as `direct`, `framework`, `runtime`, or `inferred`. Explain inferred edges plainly. Never present an async continuation, network request, queue message, channel handoff, or spawned task as a nested native call.

Set `elapsedMs` only when logs, traces, or measurements establish it. The template displays step numbers when timing is unavailable.

Use separate scenarios for materially different success, validation, conflict, retry, cancellation, and failure paths. Prefer 8 to 20 meaningful steps per scenario. Collapse plumbing that carries no decision, boundary, state change, or side effect.

## Build the HTML

Copy [assets/callgraph-template.html](assets/callgraph-template.html) to a clearly named output file. Treat the bundled file as the visual and interaction reference.

Replace these data sections in the copied file:

- `artifact` for title, repository scope, language, stack summary, and trace label;
- `operations` for entry points or scenarios;
- `contextMeta` for execution lanes;
- the initial scenario only when the first operation is not the right default.

Keep the Ayu-inspired dark palette, enlarged desktop type, three switchable views, source inspector, state table, filters, stepping controls, breakpoints, keyboard navigation, and responsive layout unless the user asks for a design change.

The result must open directly from disk with no server, package install, CDN, or network request. Escape repository text before embedding it. Keep factual and inferred content visually and verbally distinguishable.

## Verify and hand back

Open the exact output at 1440 by 900 when browser tooling is available. Check the densest scenario in Workbench and Timeline views. Confirm that controls work, text does not overlap, source locations are real, and each context referenced by a step exists in `contextMeta`.

Return the HTML link, name the scenarios included, and disclose which edges remain inferred.
