# Authoring a skill

You own the skill's voice. Agent-facing prose changes behavior.

1. Apply `skill-creator` and `writing-for-agents` before editing.
2. Define the requests that trigger the skill, the branches it handles, and the requests that should not trigger it.
3. Preserve the existing workflow unless the requested change requires a behavioral redesign.
4. Keep the entrypoint focused. Put branch-specific detail behind explicit pointers when disclosure reduces load.
5. Remove generic advice, duplicated rules, stale caches of repository facts, unsupported tools, and hard-coded model selection.
6. Validate frontmatter, folder naming, references, invocation policy, and included scripts.
7. Run realistic cases when the change is structural. Skip behavior tests when the only question is subjective voice.
8. Run Opening a PR only when authorized.

Report the behavior preserved, behavior changed, validation, and any deliberate omissions.
