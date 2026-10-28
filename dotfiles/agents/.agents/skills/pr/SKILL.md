---
name: pr
description: Generate a PR title and body from the current branch diff for GitHub or Bitbucket. Adapt to the target repository's PR template, falling back to a concise default format. Include a Jira key from the request or branch when present, and copy standalone drafts with the user's yank command.
---

Generate a PR title and body for the current branch.

For a body-only request, omit the Title section. When another skill uses this one to create a PR, return the title and body separately and skip clipboard steps unless requested. This skill alone does not authorize PR creation.

## Steps

1. Run `git branch --show-current`. Resolve a Jira key matching `[A-Z][A-Z0-9]+-[0-9]+`, case-insensitively, from an explicit key in the request or from the branch name. Normalize it to uppercase. If explicit and branch keys conflict, or the branch contains multiple keys without an explicit choice, ask which key to use. Continue without a Jira key when neither source contains one.
2. Identify the destination repository, host, and target branch from the request, calling workflow, and Git remotes. For forks, the destination repository owns the template. Resolve the base ref from an explicit PR target or user argument, the current branch's upstream, `main`, or `master`, in that order. Verify it with `git rev-parse`.
3. Run `git diff <base>...HEAD` to understand committed branch changes. Also run `git log <base>..HEAD --oneline` to see the commits. If the user wants working-tree changes included, inspect `git status --short`, `git diff`, `git diff --cached`, and untracked files that belong to the change.
4. Read any touched files as needed to understand context beyond the diff.
5. Before drafting, read [PR template selection and filling](references/templates.md) and resolve the body format. Use an explicitly requested format or selected template first, otherwise the destination repository's template. Keep required content from applicable repository instructions. Use the default below only when no template or custom format applies.

Apply the title rules below in both template and fallback modes. For standalone output, put `## Title` and the title before the body, unless the request is body-only. With a template, preserve its existing headings, relative order, and checklists. Supplement a bare template with useful missing sections from our default format as described in the template reference. Reuse equivalent sections rather than duplicating them. Default section-inclusion rules apply only to the fallback; use their writing guidance for template content and additions. Produce the requested draft without surrounding commentary.

### Default format

```
## Title

<Conventional Commit title: type(scope): short imperative description, max 72 chars>

## Summary

- <short bullet>
- <short bullet>

<optional small visual>

## What's fixed

- `<path>`: <what was wrong and how this file corrects it>

## Evidence

- **Before:** <observed behavior or result>
  **After:** <observed behavior or result after the change>

## Test Plan

- `<test path>`: <behavior covered by the added test>
```

**Title rules:**

- Follow an explicit user or repository title convention when present; otherwise use the defaults below. Include a resolved Jira key exactly once, in the convention's ticket position or after the colon by default.
- Default to Conventional Commit format: `type(scope): description`
- Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `style`
- Scope: the area of the codebase (e.g. `release-management`, `auth`, `organizations`)
- In the default format, place a resolved Jira key exactly once after the colon: `fix(test): DEX-2 - this is a test fix`
- Without a Jira key, omit the ticket segment
- Description: imperative mood, lowercase, no trailing period
- Keep the complete title at or below 72 characters, including the Jira key

**Summary rules:**

- Use as many short bullets as needed, usually 2–4, ordered by impact
- For features, cover each distinct user-facing capability or meaningful behavior change
- For fixes, summarize the affected behavior and outcome; leave file-level diagnosis for **What's fixed**
- Use plain, direct language; keep technical terms when they add useful precision
- Use the repository's domain language from `GLOSSARY.md` when present
- State the outcome and reason, rather than narrating implementation details
- Keep each bullet self-contained and avoid repeating the title or later sections
- Add a small visual when it clarifies ownership or flow in a complex change, following **Summary visuals** below; omit it when the bullets are sufficient
- Mention relevant checks that actually ran. Never claim a check passed unless you ran it.

**Summary visuals:**

- Pick the smallest view that explains the change and place it next to the text it supports
- Use pseudocode for logic or algorithms, a call tree for runtime control flow, or a component tree for UI structure and relevant state boundaries
- Use a shallow file tree for file responsibilities or a broad refactor, or Mermaid for interactions and data flow
- Use a `diff` sketch when the surrounding structure is familiar and the additions, removals, or ordering changes are the point. Sketch the relevant component tree, file layout, call tree, or state transition
- Show the whole block when most of it is new, omitted context would hide ownership or order, or reviewers need a copyable target shape
- Keep only the calls, files, props, states, and boundaries needed to understand the change
- When adding a visual, read [Summary visual examples](references/examples.md#summary-visuals) for concrete formats

**What's fixed rules:**

- Include this section only when the title type is `fix`
- Map each causally relevant source file to the bug it corrects; use backticked repository-relative paths
- State the previous failure and the correction in one concise bullet
- Group files in one bullet when they form a single fix, and leave test-only files for **Test Plan**
- Focus on the files that fix the bug rather than inventorying every touched file

**Evidence rules:**

- Include this section when a before/after comparison helps reviewers assess the change, such as a subtle bug fix, UI change, performance improvement, migration, or complex behavior change
- Choose based on review value; PR size alone does not require evidence
- Use the smallest useful comparison. Prefer screenshots for visual changes when capture is available, test or command output for behavior changes, and comparable measurements for performance changes
- Ground evidence in material you inspected or captured. Label illustrative examples and state when a comparison was not run; illustrations do not establish that the change works
- Keep it brief and avoid repeating the Summary or Test Plan
- Omit the section when it adds no useful information
- When including this section, read [Before/after evidence examples](references/examples.md#beforeafter-evidence) for concrete formats

**Test Plan rules:**

- Include this section only for a `feat` or `fix` that adds at least one test case or test file
- Map each relevant test file to the behavior or regression it covers; use backticked repository-relative paths
- Describe the added coverage without claiming tests passed or commands were run unless verified

6. When a calling workflow creates a PR, pass the generated title separately from the complete body. Exclude only the standalone title wrapper added for display. Keep any `## Title` heading that belongs to the repository template. Use `gh pr create --body-file <file>` for GitHub, or `bkt pr create --body "$BODY"` for Bitbucket after loading `BODY` from a file or a quoted heredoc. Treat Markdown as data, not executable shell text. Submit the filled body rather than relying on CLI autofill or template expansion. Preserve applicable attribution requirements. Return to the calling workflow without printing or copying a second draft.
7. For standalone drafting, print the output to the terminal using a single `echo` or `cat` command so it is visible.
8. Pipe the **same output** through the user's `yank` function to copy it to the clipboard. The yank function reads from stdin and routes to the appropriate clipboard utility (`win32yank`, `pbcopy`, `xclip`, `xsel`, or `wl-copy` depending on the OS). Invoke it as a shell function — source it inline if needed:

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
