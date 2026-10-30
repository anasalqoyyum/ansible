---
name: create-verification-skill
description: Generate a project-local verification skill that launches and drives the real application through its user-facing interfaces. Use when a project lacks a repeatable way to prove UI, CLI, service, or application behavior.
disable-model-invocation: true
---

# Create a verification skill

Create a verified project-local skill that another agent can follow cold. The skill owns launch, health checks, user-level actions, evidence, and cleanup. A feature map records the journeys it can prove.

## Inspect the project

Answer these questions from the repository. Ask only about facts the project cannot provide.

- **Interfaces:** what does a user touch? Identify the primary interface and any others that need separate drives.
- **Run:** which documented command starts the app or builds the CLI? Record required configuration, migrations, seed data, authentication, and ports.
- **Drive:** which existing tests or tools can act programmatically? Prefer the project's Playwright, Cypress, PTY, HTTP, debugger, or device tooling. For a browser with an existing login, use `browser-skill` when available. Use the runtime's browser or device controls when they are the requested environment. Otherwise choose the simplest installed tool that can observe the real interface.
- **Observe:** what proves each action? Use screenshots, terminal transcripts, responses, logs, exit codes, files, or database state.
- **Isolate:** can independent runs use separate ports, profiles, and data directories? If not, record a single-writer rule rather than risking the user's session.

Start from a working baseline. If checkout setup fails, repair it when that is in scope or report the exact blocker. Do not encode guesses about an app you could not run.

## Generate the skill

Use the target project's existing local skill root. Otherwise use `.agents/skills/verify-<app>/`. Do not convert another agent host's configuration or overwrite an existing verification skill without reconciling its contents.

Write `SKILL.md` with valid frontmatter and these operational sections:

- **Launch:** exact setup and start commands, readiness criteria, isolated state, and teardown. Readiness means the user journey is available, not only that a process or health endpoint responds.
- **Doctor:** one read-only command or procedure that checks process ownership, expected version, connectivity, and authentication before a drive and after a failure.
- **Drive:** the real commands, routes, prompts, selectors, or accessibility refs. Prefer stable selectors over coordinates. Name the available control skill or tool and its session lifecycle.
- **Evidence:** the proof location and what to capture for each action and resulting state. Include external side effects. Use mocks only at an existing production boundary. When using a dry run, observe what it skips.
- **Cleanup:** stop only processes and sessions started by the verification. Remove scratch state while preserving proof artifacts. Never kill by a broad process-name match.

Document every helper's invocation in the skill. Make scripts executable and keep their dependencies within the project's declared toolchain.

## Seed the feature map

Create `features/README.md` and files for the top three to five user journeys. Follow [the feature-map example](references/feature-map-example/README.md). Each feature records how a user reaches it, how to drive it, and which observable state proves success. Record missing prerequisites in `Gotchas` instead of weakening the journey.

## Prove the deliverable

Follow the generated instructions from launch through cleanup for one mapped feature. Capture evidence, run doctor, and confirm that the evidence remains after cleanup. Fix and rerun failures, including cleanup after failed attempts. A generated skill that has not run is a draft.

If the proof used a substitute environment, list the setup differences that remain unverified on the real target. Point the user to `maintain-verification-skill` for later drift checks. Do not create a PR unless separately authorized.
