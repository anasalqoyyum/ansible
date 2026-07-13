# Agent Guidelines

This document outlines best practices and behavioral guidelines for AI agents working in this system.

## Non-Negotiable Code Standards

Follow these rules by default. Do NOT deviate unless the user explicitly instructs you to.

### React

- Prefer a single `useState` object for object-like state instead of multiple related `useState` calls.
  - Keep separate `useState` calls only when the values are genuinely independent.
- Do NOT use `useMemo` unless it is clearly necessary.
  - `useMemo` is NOT a default pattern, a readability tool, or a premature optimization.
  - If there is no concrete performance or referential-stability reason, do NOT add it.

### Comments

- Comments are a great way to clarify functionality and how code is used. Don't comment every line, but feel free to describe (concisely) how functions are used above function definitions, classes, etc.
- Do NOT place comments above functions or files unless the user asks for them.
- Do NOT use section-divider comments.
- Do NOT write comments that narrate obvious code.
- Do NOT put a needless code comment. Code comment should be reserved for important parts and flow explanation.
- Comments are allowed only when they explain why a decision was made and that reasoning would otherwise be hard to infer.
  - If a comment explains what the code does instead of why it exists, delete it. Unless the code is complex enough that the "what" is NOT immediately clear, in which case it's fine to have a comment that explains the "what" as well as the "why".

### Expectations

- Keep things simple. Channel "YAGNI" energy unless told otherwise.
- Typesafety is useful, take advantage of it.
- Don't be scared to propose bold ideas if they can meaningfully benefit our work.
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good! Endless smoke tests, "regression tests" for feature deletions, etc, much less good. Tests should be focused, not slop.
- Write code that explains itself.
- Use precise naming and simple structure instead of commentary.
- Prefer the simplest implementation that satisfies the requirement.
- Do NOT be a yes-person. Be critical
- Do NOT add noise. Every line should earn its place.
- Do NOT write overly defensive code.
  - Handle expected failure modes, NOT every imaginable one.
  - Avoid redundant checks, generic catch-all logic, unnecessary fallback values, and abstractions whose only purpose is to guard against unlikely misuse.

## Code Build and Execution

### Build & Execution

- Do NOT run any dev or production start commands. (e.g. `dev`). Assume that the user will run these commands themselves after you have made code changes. Unless explicitly requested by the user.
- Do NOT run build scripts (e.g. `build`, `compile`, `bundle`, `release`).
- Do NOT run commands that produce production artifacts.

### Allowed Commands

- Type checking is allowed (e.g. `tsc --noEmit`, `mypy`, `pyright`).
- Linting, formatting, and static analysis are allowed.
- Tests that do NOT trigger a build step are allowed.

### Intent

- NEVER BE TOO WORDY. Ensure that what you spout is compact and easy to understand. Get to the point. Never sugarcoat. I don't need those.
- Agents should focus on code correctness and safety without generating build outputs or modifying release artifacts. (Use LSP if possible)
- Agents are prohibited from performing write actions on generated files, files located in directories with generated in the directory name, or files whose filenames contain gen. This restriction is especially strict when such files explicitly state, including via comments, that they must NOT be modified. Read-only access is permitted. If errors are identified, agents should report them to the user instead of making changes.

## Claude Directory Compatibility

If you are NOT Claude Code and a `.claude/` directory exists in the current working directory, read the relevant files in that directory before proceeding.

- Read `.claude/CLAUDE.md` when it exists, along with any other relevant files in `.claude/`
- Treat rules in `.claude/rules` as additional instructions that must also be followed
- Do NOT ignore `.claude/` guidance just because you are running in a different agent

## Tools

- For any file search or grep in the current git indexed directory use `rg`.

## Path Handling on WSL

### Windows-Native Agent with a WSL Workspace

When the agent is running as a Windows-native process while the workspace is stored in WSL:

- Modify workspace files through the Windows-accessible WSL path (for example, `Z:\home\real\work\project` or `\\wsl.localhost\Ubuntu\home\real\work\project`).
- Run repository commands in the appropriate WSL distribution with the Linux workspace path, for example: `wsl.exe -d Ubuntu --cd /home/real/work/project -- <command>`.
- Use Windows-native computer-use and browser tools when WSL-hosted agents cannot access them.
- Treat the Windows and WSL paths as views of the same files; do not copy the repository between environments.
- For a server explicitly authorized to run in WSL, prefer `localhost` from Windows and bind to `0.0.0.0` only when required for Windows access.
- Continue to follow project-specific restrictions on starting development servers, builds, and other commands.

When a user is on Windows Subsystem for Linux (WSL) and provides Windows file paths, automatically convert them to WSL-accessible paths.
**Windows Path Format:**

```
F:\path\to\file
C:\Users\username\file.txt
```

**WSL Conversion:**

```
/mnt/f/path/to/file
/mnt/c/Users/username/file.txt
```

**Rule:** Map Windows drive letters to `/mnt/<drive_letter>/` and replace backslashes with forward slashes.

### Example

- **User provides:** `F:\Libraries\Pictures\Screenshots\Screenshot.png`
- **Agent converts to:** `/mnt/f/Libraries/Pictures/Screenshots/Screenshot.png`


## File Change Confirmation

When you detect that a user has modified a file after your previous read, re-read the file and confirm with the user whether the changes are intended.

### Required Actions:

- Re-read the file to capture the current state
- Present a diff or summary of what changed
- Ask the user to confirm if changes were intentional

### Example:

- **Scenario:** You previously read `config.json`, then the user runs a command that modifies it
- **Action:** Re-read `config.json`, show what changed, ask: "I noticed changes in `config.json` — was this intentional?"

## Git Operations

Git operations should **only be performed when explicitly requested by the user**.

### Allowed Scenarios:

- User asks: "Create a commit"
- User asks: "Push changes to remote"
- User asks: "Create a pull request"
- User asks: "Merge this branch"

### Prohibited Scenarios:

- Do NOT commit changes automatically
- Do NOT push to remote without explicit request
- Do NOT amend commits without user approval
- Do NOT force push unless explicitly requested
- Do NOT perform destructive operations (hard resets, force pushes to main/master) without explicit user consent

### Best Practice:

Always ask for permission before performing any git operations unless the user has explicitly stated what they want done
