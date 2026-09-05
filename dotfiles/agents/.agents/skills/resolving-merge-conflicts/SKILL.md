---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

1. **See the current state** of the merge/rebase. Check git history, and the conflicting files.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, pick the one matching the merge's stated goal and note the trade-off. Do not invent new behavior. Do not abort unless the user asks. If a conflict cannot be resolved safely, stop and report it.

4. Discover the project's **automated checks** and run them — typically typecheck, then tests, then format. Fix anything the merge broke.

5. **Finish the merge/rebase when authorized.** Stage only files resolved as part of the operation. Complete the merge or rebase when the user authorized completing it. If commit authority is absent, leave the resolved index ready and report the command needed to continue or commit. If rebasing, continue until all commits are rebased when that operation is authorized.
