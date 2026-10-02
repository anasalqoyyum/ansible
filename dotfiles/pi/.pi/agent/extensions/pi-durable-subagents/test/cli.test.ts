import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdtemp, mkdir, symlink, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const execute = promisify(execFile);

test('installed Pi CLI auto-discovers the local extension with no package declaration, one Agent and real Durable execution', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'durable-cli-'));

  try {
    await mkdir(join(directory, 'extensions'));
    await symlink(
      fileURLToPath(new URL('..', import.meta.url)),
      join(directory, 'extensions', 'pi-durable-subagents'),
      'dir',
    );
    await writeFile(join(directory, 'settings.json'), JSON.stringify({ packages: [] }));

    const command = execute(
      'pi',
      [
        '--offline',
        '--no-builtin-tools',
        '--no-skills',
        '--no-prompt-templates',
        '--no-context-files',
        '-e',
        fileURLToPath(new URL('./cli-driver.ts', import.meta.url)),
        '--provider',
        'faux',
        '--model',
        'faux-1',
        '--thinking',
        'off',
        '-p',
        'Delegate to a foreground agent',
      ],
      {
        cwd: directory,
        env: { ...process.env, PI_CODING_AGENT_DIR: directory },
        timeout: 12000,
        maxBuffer: 1024 * 1024,
      },
    );

    command.child.stdin?.end();
    const { stdout, stderr } = await command;
    assert.match(stdout, /CLI_PARENT_OK/);
    assert.doesNotMatch(stderr, /Failed to load extension|Duplicate|Another runtime owns|Error:/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
