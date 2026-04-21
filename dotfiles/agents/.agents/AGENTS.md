# Agent Guidelines

This document outlines best practices and behavioral guidelines for AI agents working in this system.

## Non-Negotiable Code Standards

Follow these rules by default. Do not deviate unless the user explicitly instructs you to.

### React

- Do not use `useMemo` unless it is clearly necessary.
- `useMemo` is not a default pattern, a readability tool, or a premature optimization.
- If there is no concrete performance or referential-stability reason, do not add it.

### Comments

- Do not place comments above functions or files unless the user asks for them.
- Do not use section-divider comments.
- Do not write comments that narrate obvious code.
- Comments are allowed only when they explain why a decision was made and that reasoning would otherwise be hard to infer.
- If a comment explains what the code does instead of why it exists, delete it.

### Expectations

- Write code that explains itself.
- Use precise naming and simple structure instead of commentary.
- Prefer the simplest implementation that satisfies the requirement.
- Do not add noise. Every line should earn its place.

## Code Build and Execution

### Build & Execution

- Do NOT run any dev or production start commands. (e.g. `dev`). Assume that the user will run these commands themselves after you have made code changes. Unless explicitly requested by the user.
- Do NOT run build scripts (e.g. `build`, `compile`, `bundle`, `release`).
- Do NOT run commands that produce production artifacts.

### Allowed Commands

- Type checking is allowed (e.g. `tsc --noEmit`, `mypy`, `pyright`).
- Linting, formatting, and static analysis are allowed.
- Tests that do not trigger a build step are allowed.

### Intent

- Agents should focus on code correctness and safety without generating build outputs or modifying release artifacts. (Use LSP if possible)
- Agents shouldn't perform any write actions against generated files. Especially if explicitly stated in the files as comment to NOT modify them. Reading should be allowed and if there's any error found then report it to the user.

## Tools

- For any file search or grep in the current git indexed directory use fff tools (if available).

## Claude Directory Compatibility

If you are not Claude Code and a `.claude/` directory exists in the current working directory, read the relevant files in that directory before proceeding.

- Read `.claude/CLAUDE.md` when it exists, along with any other relevant files in `.claude/`
- Treat rules in `.claude/` as additional instructions that must also be followed
- Do not ignore `.claude/` guidance just because you are running in a different agent

## Path Handling on WSL

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

