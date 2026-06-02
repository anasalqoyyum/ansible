---
name: gen-pr-title
description: Generate a PR title and summary from the current branch diff. Outputs a formatted block with a Conventional Commit title and concise bullet-point summary, then copies the result to the clipboard using the user's yank command.
---

Generate a PR title and summary for the current branch.

## Steps

1. Run `git diff main...HEAD` (or `git diff master...HEAD` if `main` doesn't exist) to understand all changes. Also run `git log main...HEAD --oneline` (or `master`) to see the commit history.
2. Read any touched files as needed to understand context beyond the diff.
3. Produce the output in **exactly** this format — no extra prose before or after:

```
## Title

<Conventional Commit title: type(scope): short imperative description, max 72 chars>

## Summary

- <bullet>
- <bullet>
- ...
```

**Title rules:**
- Use Conventional Commit format: `type(scope): description`
- Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `style`
- Scope: the area of the codebase (e.g. `release-management`, `auth`, `organizations`)
- Description: imperative mood, lowercase, no trailing period, max 72 chars total

**Summary rules:**
- Each bullet is one self-contained change — what changed and why, not how
- Clear and concise; no overexplaining
- Order by impact: most significant changes first
- Do not pad with filler bullets

4. Print the output to the terminal using a single `echo` or `cat` command so it is visible.
5. Pipe the **same output** through the user's `yank` function to copy it to the clipboard. The yank function reads from stdin and routes to the appropriate clipboard utility (`win32yank`, `pbcopy`, `xclip`, `xsel`, or `wl-copy` depending on the OS). Invoke it as a shell function — source it inline if needed:

```bash
yank() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    pbcopy
  elif [[ "$OSTYPE" == "linux"* ]]; then
    if command -v win32yank > /dev/null 2>&1; then win32yank -i
    elif command -v xclip > /dev/null 2>&1; then xclip -selection clipboard
    elif command -v xsel > /dev/null 2>&1; then xsel --clipboard --input
    elif command -v wl-copy > /dev/null 2>&1; then wl-copy
    else echo "No clipboard utility found" >&2; return 1
    fi
  fi
}
OUTPUT=$(cat << 'ENDOFOUTPUT'
<the generated output>
ENDOFOUTPUT
)
echo "$OUTPUT"
echo "$OUTPUT" | yank
```

Use `tee /dev/stderr` or a variable to both print and pipe without running the generation twice.
