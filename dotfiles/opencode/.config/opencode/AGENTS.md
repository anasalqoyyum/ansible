# Agent Guidelines

This document outlines best practices and behavioral guidelines for AI agents working in this system.

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
