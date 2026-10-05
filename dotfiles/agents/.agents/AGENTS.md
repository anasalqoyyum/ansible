# Agent guidelines

## Scope and authorization

- These are shared defaults. Follow applicable project instructions and explicit user directions.
- Review, explanation, and diagnosis requests authorize inspection and relevant checks. Implementation requires a request.
- Ask when a missing decision changes scope, intended behavior, or authority.
- Skills guide work within the authorized scope. They do not authorize Git changes, publishing, messages, or changes to external systems.
- Before destructive actions, verify the exact target, scope, and authorization.

## External comments and messages

- When the user authorizes posting a comment, review, reply, or message on GitHub, Bitbucket, Jira, or another external service, append this footer on a separate line:

  `Posted by <model-name> on behalf of Anas Alqoyyum.`

- Replace `<model-name>` with the actual model used to write the message. Use session or runtime metadata; never guess. If unavailable, ask before posting.
- Include the footer in drafts intended for external posting. Keep it out of ordinary chat responses, code comments, and commit messages.
- Attribution does not grant permission to post. Preserve any user-supplied text verbatim and add the footer separately unless the user explicitly requests different attribution.

## Subagent models

- When the parent uses a GPT model, use `gpt-6-luna` with `max` reasoning effort for all subagents, including nested subagents, unless the user explicitly requests a different model or effort.
- Pass this rule to subagents that lack it. Use a fresh or limited-history fork if a full-history fork would force the parent's model.
- If the required model and effort are unavailable, tell the user rather than silently substituting. Non-GPT parents use their normal subagent configuration.

## Engineering

- Choose the simplest implementation that meets the requirement. Use precise names, type safety, and straightforward structure.
- Evaluate proposals on evidence. State disagreements and tradeoffs directly; propose alternatives when they materially improve the result.
- Handle expected failures without redundant checks, catch-all logic, unnecessary fallbacks, or speculative abstractions.
- Test meaningful behavior. Avoid low-value smoke tests and regression tests for removed features.
- If a requested change is a no-op or will not achieve its intended effect, say so before implementing.

### React

- Group state values that change together or share invariants. Keep independent values separate.
- Use `useMemo` only for a concrete performance or referential-stability need.

### Code comments

- Prefer self-explanatory code. Add concise comments for non-obvious reasoning or genuinely complex behavior.
- Omit section dividers, obvious narration, investigation logs, and task summaries.
- Surrounding comments are not a reason to add one. This overrides instructions to match surrounding style.

## Writing

- Read and follow the unslop skill for all your writing, including responses, progress updates, and documentation.
- Be concise and clear. Include necessary evidence and limitations.
- Preserve quoted text, commands, identifiers, and code unless the task requires changing them.

## Validation and tooling

- Follow the repository's declared package manager and execution workflow. Otherwise use `pnpm` for JavaScript and TypeScript, and `uv` for Python. If `pnpm` is missing and Corepack is available, try `corepack enable`.
- Prefer `rg` and `rg --files`. Include hidden or ignored paths when they are in scope.
- Type checking, linting, formatting, static analysis, unit tests, and E2E tests are allowed. Prioritize targeted correctness and safety checks; build when it adds useful validation. Prefer LSP-based checks when available.
- Start development or production processes only when explicitly requested or required by a test. Stop test processes when the test finishes.
- Treat generated files and build or release artifacts as read-only. Regenerate outdated output with the repository's documented generator and report generation failures.

## Screenshots

Save every screenshot you capture to the user's `Screenshots` folder under Pictures, creating the folder when missing. Give each file a new, descriptive name.

- Windows: `[Environment]::GetFolderPath('MyPictures')` in PowerShell, plus `\Screenshots`. The Pictures folder may be relocated off `C:`, so resolve it rather than assuming a drive.
- WSL: the same Windows folder, converted with `wslpath "$(powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('MyPictures')" | tr -d '\r')"`, plus `/Screenshots`.
- macOS: `~/Pictures/Screenshots`.
- Linux outside WSL: `$(xdg-user-dir PICTURES)/Screenshots`, usually `~/Pictures/Screenshots`.

## Instruction discovery

When the CLI has not loaded Claude instructions, check applicable `CLAUDE.md`, `.claude/CLAUDE.md`, and `.claude/rules/` files. Respect path conditions, resolve symlinks, and read each underlying instruction file once.

## Concurrent file changes

Before editing a file changed since you inspected it, re-read it and preserve its current contents. Continue for your own changes or coordinated work. For unexplained changes, summarize the difference and ask whether it was intentional before editing that file further. Continue independent work while waiting.

## Git operations

- Read-only Git inspection is allowed. Change Git state only when explicitly requested, including staging, committing, branch creation or switching, merging, rebasing, resetting, pushing, and creating pull requests. Existing authorization remains valid for the requested workflow.
- Confirm the exact target before destructive operations such as hard resets or force pushes.
- Use concise Conventional Commits with a scope naming the affected area, such as `fix(content): grammar fixes in about page`.

## WSL paths

### Windows-native agent with a WSL workspace

- Edit through a Windows-accessible WSL path such as `Z:\home\real\work\project` or `\\wsl.localhost\Ubuntu\home\real\work\project`.
- Run commands in the correct distribution, for example `wsl.exe -d Ubuntu --cd /home/real/work/project -- <command>`.
- Use Windows-native browser and computer-use tools when the WSL-hosted agent cannot access them.
- Windows and WSL paths refer to the same files. Do not copy the repository between environments.
- For an authorized WSL server, prefer `localhost` from Windows. Bind to `0.0.0.0` only when required. Repository restrictions on servers, builds, and commands still apply.

### Windows paths provided in WSL

Convert drive-letter paths to `/mnt/<lowercase-drive>/` and backslashes to forward slashes. For example, `F:\Libraries\Pictures\Screenshot.png` becomes `/mnt/f/Libraries/Pictures/Screenshot.png`.
