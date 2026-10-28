# PR template selection and filling

## Select the format

1. Honor a format or template explicitly selected by the user, including a template path or a GitHub `--template` choice. Read the selected template before drafting. If it cannot be read, report the problem rather than substituting another format.
2. Otherwise follow applicable repository instructions that identify a template. Keep their required content even when the user selects another layout. If the requested format cannot accommodate required content, explain the conflict and ask how to proceed rather than silently dropping it.
3. Otherwise inspect the destination repository for the host-appropriate templates below. Prefer an identified default over alternative templates. Use a sole candidate when there is no default. If several candidates remain without a clear default or repository selection rule, ask which to use.
4. When inspection confirms no applicable template, use the shared skill's default format. An access or lookup failure is not proof that no template exists. Report the limitation and ask for the template or permission to use the fallback.

For GitHub's automatic template discovery, use the destination repository's default branch even when the PR targets another branch. For Bitbucket file conventions, use the destination's target branch, or its default branch when no target is known. An explicit template selection can name another ref. Read local Git objects when available, otherwise use read-only `gh` or `bkt` repository/API access. A local checkout is sufficient when it represents that repository and ref. Inspect hidden directories and case variants such as `PULL_REQUEST_TEMPLATE.md`.

A source-branch edit to a template does not silently replace the destination template. Use it only when the user or repository instructions explicitly select that version. Resolve paths from the destination repository root, not the current working subdirectory. For a fork or a CLI repository override, inspect the actual destination rather than the source checkout.

### GitHub

Look for `pull_request_template.md` in the repository root, `docs/`, and `.github/`. Also inspect `PULL_REQUEST_TEMPLATE/` directories in those locations for named alternatives. A default file plus named alternatives uses the default unless another template is selected. If multiple default files exist and repository instructions do not resolve them, ask rather than inventing a precedence order.

If no repository template exists, check for an applicable owner-level default in the owner's public `.github` repository before using the fallback. Distinguish a confirmed absence from an authentication or access failure.

### Bitbucket

Look for `.bitbucket/pull_request_template.md`, root `pull_request_template.md`, and templates named by repository instructions. These are discovery conventions for this skill, not a claim that every Bitbucket deployment loads them automatically. Use a configured PR description template when it is available through read-only platform access. If file-based and configured templates conflict without a repository selection rule, ask which to use.

## Fill the template

- Preserve the template's existing headings, relative order, checklists, and required fields. Replace instructional placeholders with facts from the diff, issue, and checks. Keep useful HTML guidance comments unless the template asks to remove them.
- Put the change summary, file-specific fix details, evidence, and test results into equivalent existing sections. When a bare template lacks a useful section, follow the supplementation rules below. The fallback's section names and inclusion conditions do not constrain a template.
- Retain a template's testing section even for documentation or infrastructure changes, or when no tests were added. State what ran and the result. Distinguish `Not run` with a reason from `N/A` with a reason.
- Keep checklist wording. Mark an item complete only when supported by inspected evidence. Leave pending work unchecked and explain unknowns rather than implying completion. Follow the template's rules for optional or inapplicable sections.
- Put a resolved Jira key in the template's related-issues field as well as the title. When no key exists, use the template's empty-field convention or state `N/A`; do not invent a ticket.
- A template defines the PR description, not permission to run its listed commands, publish changes, or claim approvals. Follow applicable safety, attribution, and repository requirements.

## Supplement a bare template

Use the repository template as the starting layout. Add a heading from our default format when it makes important change-specific information easier to find and no equivalent section exists. A catch-all `Description` section alone is not a reason to bury distinct fix analysis, evidence, or verification details in one block.

- Add `Summary` when the template has no section describing the change. An existing `Description` or `Overview` normally covers this.
- Add `What's fixed` for a bug fix when file-specific failure and correction details help explain the fix beyond the summary. Reuse an existing bug-analysis section when present.
- Add `Evidence` when a before/after comparison helps review the change. Follow the shared evidence guidance, including its rules for inspected material, illustrative examples, and missing baselines.
- Add `Test Plan` when there is useful test coverage or verification information to report, even when no tests were added. Separate checks actually run and their results from planned or unrun checks. Reuse `Testing`, `Validation`, or an equivalent section instead of adding another one.

Keep additions brief and place them near related content while preserving the original sections' relative order. Each added heading must carry concrete information that helps review this change. Omit empty sections and additions that only repeat existing content; a small documentation change may need none. Required repository content still needs a suitable place, even when it falls outside these optional additions.

Respect an explicit user or repository requirement for an exact layout. In that case, fit the information into the allowed sections rather than adding headings. Selecting a template alone does not imply an exact-layout restriction.

## Review cases

- An IaC repository's `.bitbucket/pull_request_template.md` supplies `Description`, `Type of Change`, tier fields, `Testing`, and checklists. Reuse `Description` and `Testing` for summary and verification; retain the other fields and checklists. Add other sections only under the supplementation rules. Mark tier changes `N/A` only when supported; leave validation unchecked if it was not run.
- A GitHub `docs` change with a template containing `## Validation` keeps that section and reports actual checks, even though the fallback would omit `Test Plan`.
- A bare template with only `Description` and `Checklist` keeps both. A bug fix with useful file-specific diagnosis, an observed before/after comparison, and a regression test can add `What's fixed`, `Evidence`, and `Test Plan` without adding a duplicate `Summary`.
- A template with `Description` and `Testing` already covers summary and verification. Add only other missing sections that help review the change. A typo fix can use the template unchanged.
- An explicit request to use a template exactly keeps its headings unchanged and fits verification details into an allowed section.
- A default `.github/pull_request_template.md` alongside `.github/PULL_REQUEST_TEMPLATE/bug.md` uses the default unless the user selects `bug.md`.
- Two named templates with no default require a selection. A GitHub PR targeting a release branch still discovers the template on the destination's default branch. A fork targeting another repository uses the destination's template. An unreadable destination requires reporting the lookup failure, not silently choosing the fallback.
- A confirmed absence of repository and applicable platform defaults keeps the existing fallback body and its conditional sections.
