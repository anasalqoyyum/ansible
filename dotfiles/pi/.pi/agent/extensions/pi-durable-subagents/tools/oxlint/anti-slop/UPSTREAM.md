# Anti-slop source

Source repository: https://github.com/dmmulroy/anti-slop

Copied from `/home/real/.agents/skills/install-anti-slop/assets/anti-slop/` using the skill's installer. The installed skill lock records folder hash `89044d21c75a367eac1ddbaf208e650b1a7d5820`. That is a folder hash, not a Git commit. The exact upstream commit is unknown.

`SHA256SUMS` records every pristine copied asset. The files are retained unchanged here, providing a recoverable source snapshot. Verify them from this directory with `sha256sum --check SHA256SUMS`.

Installed entry points:

- `tools/oxlint/anti-slop/index.ts`, registered as `anti-slop` in `.oxlintrc.json`.
- `tools/oxlint/anti-slop/effect/index.ts`, retained but not registered. This package has no direct Effect dependency.

All generic rules are enabled at error severity, alongside `oxc/no-accumulating-spread`. There are no source adaptations. `UPSTREAM.md` and `SHA256SUMS` were added locally. The plugin is excluded from linting and formatting.

The nested `vendor/eslint-stylistic/LICENSE` and `vendor/eslint-stylistic/UPSTREAM.md` are retained. The nested record identifies that rule's upstream commit and its existing Oxlint adaptations.
