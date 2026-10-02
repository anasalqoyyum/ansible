import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createModels, fauxProvider, fauxAssistantMessage } from '@earendil-works/pi-ai';
import { openRuntime, context } from '../src/runtime.ts';

const execute = promisify(execFile);

test('SIGKILL releases session ownership and recovery reuses the same foreground child and submission', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'durable-crash-'));

  try {
    await assert.rejects(
      execute(
        process.execPath,
        [
          '--experimental-strip-types',
          fileURLToPath(new URL('./crash-driver.ts', import.meta.url)),
          directory,
        ],
        { timeout: 12000 },
      ),
      { signal: 'SIGKILL', stdout: /CRASH_READY/ },
    );
    const faux = fauxProvider();
    const models = createModels();
    models.setProvider(faux.provider);
    faux.setResponses([fauxAssistantMessage('recovered from process crash')]);
    const runtime = await openRuntime({ directory, parentSession: 'crash-parent', models });

    try {
      const before = await runtime.get('crash');
      const initial = await runtime.snapshot();
      assert.ok(initial);
      const task = initial.requests.crashforeground;
      assert.ok(task);

      const replay = await runtime.start({
        requestId: 'crashforeground',
        name: 'crash',
        description: 'crash',
        message: 'answer',
        configuration: before.configuration,
        background: false,
      });

      assert.equal(replay, task);
      assert.equal((await runtime.wait(task)).text, 'recovered from process crash');
      const fleet = await runtime.snapshot();
      assert.ok(fleet);
      assert.equal(Object.keys(fleet.agents).length, 1);
      assert.equal((await runtime.get('crash')).conversationId, before.conversationId);
      const saved = await (await runtime.conversation(await runtime.get('crash'))).context(context);
      assert.equal(saved.entries.filter((entry) => entry.kind === 'pi.user').length, 1);
    } finally {
      await runtime.close();
    }
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
