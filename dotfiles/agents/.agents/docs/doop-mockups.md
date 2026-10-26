# Doop mockups

Read and follow the current `doop-instructions` guide, with these exceptions.

Design from the brief. Do not call `search_inspiration`. Refero answers `https://styles.refero.design/api/styles/search` with HTTP 403 unless the browser supplies a Vercel BotID `x-is-human` challenge. Doop fetches that URL from the server, so the tool fails.

For redesigns and multi-screen flows, follow the Doop guide's workflow with that exception. For other component or single-page mockups, follow existing canvas style guides, keep the workflow lightweight, and use enough frames to show the requested states and alternatives. Omit creating new style guides and recording decisions unless the task requires them.

If a Doop call fails, say so and use the generated image. When a screenshot returns only a URL, download it to the configured Screenshots folder and view it.

Return the canvas URL and each frame URL. Clear `set_status` when you stop. Leave the canvas in place unless asked to delete it.
