---
name: why
description: Investigate why code or a decision has its current shape using repository history, GitHub or Bitbucket PR evidence, Jira or linked issues, and in-repo design documents. Use for design rationale, regressions, postmortems, or unexplained thresholds. Use how for runtime behavior.
---

# Why

Investigate motivation and intent behind code. Find the product, operational, and engineering constraints that shaped it. Separate documented decisions from later rationalization.

Companion to `how`. `how` explains what the code does. `why` explains the evidence behind its shape.

## Evidence lanes

Use the sources this workflow actually has:

1. **Repository and forge history.** Git history, code comments, tests, GitHub PRs and issues, or Bitbucket PRs and review threads.
2. **Jira.** Linked issues, epics, comments, labels, versions, and issue relationships.
3. **In-repo documents.** ADRs, RFCs, specs, postmortems, changelogs, and runbooks stored with the code.

Search available lanes in parallel when the question is broad. A missing provider is a gap to report, not a reason to invent context. A null result is evidence only when the search scope and query are named.

## Operating posture

- Collect evidence before forming a narrative.
- Cite every factual claim about intent with a commit, PR, issue, or file location.
- Label inference. Prefer “appears to,” “likely,” or “suggests” when evidence is indirect.
- Surface contradictions instead of choosing the tidier story.
- Name unavailable and empty sources.
- Do not cite code behavior as proof of its own motivation.

Read `references/epistemics.md` before synthesis. Its confidence tiers govern the final language.

## Step 1. Define the target

Identify the exact code, pattern, feature, or decision and the user's question. Common questions include:

- Why was this designed this way?
- Why did we choose this over an alternative?
- Which edge case or incident motivated this guard?
- Where did this threshold come from?
- Why does this code still exist?

If context makes one target likely, state that interpretation and proceed. Ask only when competing targets would produce materially different investigations.

## Step 2. Establish the code anchor

Capture:

- file paths and line ranges;
- key symbols;
- commits that introduced or materially changed the target;
- PR numbers or branch names;
- Jira keys or linked GitHub issues.

Use repository history through renames and inspect the actual patches. Determine whether the repository is on GitHub or Bitbucket before querying PRs.

- On GitHub, prefer connected GitHub tooling for context and use `gh` when local CLI or review-thread detail requires it.
- On Bitbucket, use `bkt pr view`, `bkt pr comments`, and structured output.
- Use `jira issue view KEY --plain --comments 20` for linked Jira issues.

Pass the anchor to every investigator so they do not rediscover it.

## Step 3. Investigate in parallel

Create one read-only investigator per evidence lane that is both relevant and available. Every investigator inherits the current session model. Omit model selection and model overrides.

Each investigator receives:

1. `references/investigator-prompt.md`;
2. the matching playbook from `references/source-playbook.md`;
3. `references/sources/incident-postmortem.md` when the target looks defensive;
4. the code anchor and original question.

Use these lanes:

- **Repository and forge investigator.** Always run. Search commits, blame, patches, tests, repository documents, and the matching GitHub or Bitbucket PR context.
- **Jira investigator.** Run when a Jira key exists or authenticated Jira search is available and the target has a plausible product or project history.
- **In-repo document investigator.** Run when the repository contains ADR, RFC, spec, postmortem, changelog, or runbook locations. Keep this lane separate from commit archaeology so documents get read as documents.

For a narrow single-commit change whose PR directly answers the question, one investigator may be enough. Say which lanes were unnecessary and why.

## Step 4. Synthesize

Use one independent synthesizer on the current session model. Give it:

- all findings and null results;
- skipped lanes with reasons;
- the code anchor and question;
- `references/epistemics.md`;
- `references/synthesizer-prompt.md`.

The synthesizer must spot-check load-bearing citations and keep direct evidence, supported conclusions, inference, speculation, and unknowns distinct.

## Step 5. Present

Present the synthesis without strengthening its confidence language.

Use this structure:

- **The question.** The target and the precise why question.
- **The code in question.** Paths, line ranges, and symbols.
- **What we found.** Direct or strongly supported claims with citations.
- **What we can reasonably infer.** Hedged claims with the inference chain.
- **Competing hypotheses.** Include when evidence supports more than one story.
- **What we do not know.** Missing evidence, unavailable providers, and empty searches.
- **Sources consulted.** One line per actual lane, including null results.

Example coverage lines:

- Repository and Bitbucket: inspected commits `abc123` and `def456`, PR 42, and its unresolved review threads.
- Repository and GitHub: inspected the introducing commit, PR 108, linked issue 77, and review discussion.
- Jira: inspected `DEX-204` and its parent epic. No comment explains the threshold value.
- In-repo documents: searched `docs/adr`, `docs/rfcs`, and changelogs for the feature name. No relevant document found.

When the user plans to change the code, end with Preserve, Change, Avoid, and Risk constraints derived from the evidence.

## Failure modes

- Confident storytelling from thin evidence.
- Treating the newest commit as the complete history.
- Treating a ticket template's generic “why” field as real rationale.
- Reading PR titles without review threads or linked issues.
- Citing current code as proof of original intent.
- Omitting searches that returned nothing.
- Collapsing all lanes into one large search that loses source-specific context.

## References

- `references/epistemics.md`. Confidence tiers and phrasing.
- `references/investigator-prompt.md`. Evidence-collection contract.
- `references/source-playbook.md`. Routing for available evidence lanes.
- `references/sources/code-archaeology.md`. Repository, GitHub, and Bitbucket history.
- `references/sources/jira.md`. Jira investigation.
- `references/sources/incident-postmortem.md`. Defensive-code incident angle.
- `references/synthesizer-prompt.md`. Final synthesis contract.
