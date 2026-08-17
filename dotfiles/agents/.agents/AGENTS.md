# Agent Guidelines

Apply these rules by default unless the user explicitly overrides them.

## Code Standards

### React

- Use one `useState` object for related, object-like state. Keep separate state only for genuinely independent values.
- Add `useMemo` only for a concrete performance or referential-stability need, not as a default readability pattern or premature optimization.

### Comments

- Add concise comments only to explain non-obvious reasoning or genuinely complex behavior.
- Prefer self-explanatory code over comments. Avoid section dividers and comments that narrate obvious code.

### Engineering Approach

- Prefer the simplest implementation that satisfies the requirement; apply YAGNI.
- Use type safety, precise naming, and straightforward structure so the code explains itself.
- Be critical rather than agreeable by default. Propose bold ideas when they offer meaningful value.
- Handle expected failure modes without redundant checks, catch-all logic, unnecessary fallbacks, or speculative abstractions.
- Add focused tests that protect meaningful behavior. Avoid low-value smoke tests and regression tests for removed features.
- Treat destructive actions cautiously when the user has not explicitly requested them.

## Build and Execution

- Do not start development or production processes unless the user explicitly requests it or a test requires one. Stop any process started for testing when the test finishes.
- Type checking, linting, formatting, static analysis, unit tests, and E2E tests are allowed.
- Prioritize targeted correctness and safety checks, then run the build when it provides useful validation. Prefer LSP-based checks when available, and do not edit build or release artifacts manually.
- Treat generated files as read-only. If generated output is outdated or causes an error, rerun the repository's documented generator instead of editing the output manually. Report generation failures.
- Keep responses concise, direct, and unsentimental.

### JavaScript and TypeScript

- Use `pnpm` for package management, workspace commands, and scripts when possible.
- If `pnpm` is unavailable, try `corepack enable` before another package manager.
- Follow the repository's existing tooling when it explicitly requires npm, Yarn, Bun, or another package manager.

### Python

- Use `uv` for package management, virtual environments, dependency synchronization, and execution when possible.
- Prefer `uv venv`, `uv add`, `uv sync`, and `uv run`.
- Follow the repository's existing tooling when it explicitly requires Python, `pip`, or another package manager directly.

## Claude Directory Compatibility

When running outside Claude Code, check for a `.claude/` directory before proceeding. Read `.claude/CLAUDE.md` and relevant files under `.claude/rules/`, and treat them as additional instructions.

## Tools

- Use `rg` for file and content searches in the current Git-indexed repository.

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

If a file changed after it was last read:

1. Re-read it to capture the current state.
2. Show a diff or concise summary of the unexpected changes.
3. Ask whether the changes were intentional before editing further.

## Git Operations

Perform Git operations only when the user explicitly requests them. This includes commits, pushes, pull requests, merges, amendments, resets, and force pushes. Require explicit confirmation for destructive operations such as hard resets or force-pushing a protected branch.
