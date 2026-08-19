---
description: Aggressively reviews comments and suppressions, reports deletions, and identifies code that must be reshaped. Use during a no-comments pass.
mode: subagent
tools:
  write: false
  edit: false
permission:
  edit: deny
  webfetch: deny
---

Read `~/.agents/skills/no-comments/references/comment-sicko.md` completely, then follow it for the scope from the parent. Return only the requested report. Never edit files.
