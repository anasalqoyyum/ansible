# Agent guidelines

These are shared defaults for all coding agents. Follow applicable project instructions and explicit user directions. Review, explanation, and diagnosis requests authorize inspection and relevant checks; implementation requires a request. Ask when a missing decision changes scope, intended behavior, or authority. Skills provide task-specific workflows within the authorized scope. They do not grant additional permission to change Git state, publish, send messages, or modify external systems.

## Code Standards

### React

- Group state values that change together or share invariants. Keep independent values separate.
- Add `useMemo` only for a concrete performance or referential-stability need, not as a default readability pattern or premature optimization.

### Comments

- Add concise comments only to explain non-obvious reasoning or genuinely complex behavior.
- Prefer self-explanatory code over comments. Avoid section dividers and comments that narrate obvious code.

### Engineering Approach

- Prefer the simplest implementation that satisfies the requirement; apply YAGNI.
- Use type safety, precise naming, and straightforward structure so the code explains itself.
- Evaluate proposals on evidence. State disagreements and tradeoffs directly. Propose alternatives when they materially improve the outcome.
- Handle expected failure modes without redundant checks, catch-all logic, unnecessary fallbacks, or speculative abstractions.
- Add focused tests that protect meaningful behavior. Avoid low-value smoke tests and regression tests for removed features.
- Before a destructive action, verify the exact target, scope, and authorization.

## Writing

- Apply the unslop rules to assistant-authored prose on every turn. Remove AI filler, puffery, excessive hedging, chatbot phrases, and em dash overuse while preserving meaning and requested tone.
- Apply prose style rules only to assistant-authored prose. Preserve quoted text, commands, identifiers, and code when reproducing them. Edit them when the task requires it.
- Keep responses concise and direct. Include the evidence and limitations needed to assess the result.

## Build and Execution

- Do not start development or production processes unless the user explicitly requests it or a test requires one. Stop any process started for testing when the test finishes.
- Type checking, linting, formatting, static analysis, unit tests, and E2E tests are allowed.
- Prioritize targeted correctness and safety checks, then run the build when it provides useful validation. Prefer LSP-based checks when available, and do not edit build or release artifacts manually.
- Treat generated files as read-only. If generated output is outdated or causes an error, rerun the repository's documented generator instead of editing the output manually. Report generation failures.

### JavaScript and TypeScript

- Follow the repository's declared package manager and execution workflow. Otherwise prefer `pnpm` for JavaScript and TypeScript, and `uv` for Python. If `pnpm` is missing and Corepack is available, try `corepack enable`.

### Python

- Use `uv` for Python package management, virtual environments, dependency synchronization, and execution when the repository has no other declared workflow. Follow the repository's existing tooling when it explicitly requires `pip` or another package manager.

## Claude Directory Compatibility

When the CLI has not already loaded Claude instructions, check applicable `CLAUDE.md`, `.claude/CLAUDE.md`, and `.claude/rules/` files. Respect each rule's path conditions. Resolve symlinks and read each underlying instruction file only once.

## Tools

- Prefer `rg` and `rg --files`. Include hidden or ignored paths explicitly when they are in scope.

## WSL Path Handling

### Windows-Native Agent with a WSL Workspace

- Edit files through a Windows-accessible WSL path such as `Z:\home\real\work\project` or `\\wsl.localhost\Ubuntu\home\real\work\project`.
- Run repository commands in the correct distribution, for example: `wsl.exe -d Ubuntu --cd /home/real/work/project -- <command>`.
- Use Windows-native browser and computer-use tools when the WSL-hosted agent cannot access them.
- Treat Windows and WSL paths as views of the same files; do not copy the repository between environments.
- For an explicitly authorized WSL server, prefer `localhost` from Windows and bind to `0.0.0.0` only when required.
- Continue following repository restrictions on starting servers, builds, and other commands.

### Windows Paths Provided in WSL

Convert drive-letter paths to `/mnt/<lowercase-drive>/` and replace backslashes with forward slashes.

Example: `F:\Libraries\Pictures\Screenshot.png` becomes `/mnt/f/Libraries/Pictures/Screenshot.png`.

## Concurrent File Changes

Before editing, re-read any file that changed since you last inspected it. Preserve the current contents. Continue when the change comes from your own commands or coordinated work. For unexplained changes, summarize the difference and ask whether it was intentional before editing that file further. Continue independent work while waiting.

## Git Operations

Use read-only Git commands as needed to inspect changes and history. Change Git state only when the user explicitly requests it. This includes staging, committing, switching or creating branches, merging, rebasing, resetting, pushing, and creating pull requests. Existing authorization remains valid for the requested workflow. Confirm the exact target before destructive operations such as hard resets or force pushes.

### Commits

- Keep commit messages concise and use Conventional Commits, such as `fix(parser): handle empty input`.
