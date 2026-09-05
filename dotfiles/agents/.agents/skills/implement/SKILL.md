---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use the TDD workflow when the user requests test-first work or when it materially improves the change. Test at public seams that match the behavior under change.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, invoke the code-review workflow when review is in scope for the current CLI.

Commit only when the user has authorized the commit. Otherwise leave the changes in the working tree and report them.
