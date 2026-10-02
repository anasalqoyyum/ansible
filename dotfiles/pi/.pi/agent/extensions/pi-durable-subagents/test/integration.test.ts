import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { BACKGROUND_CONTEXT } from '@earendil-works/chord/context';
import { createModels } from '@earendil-works/pi-ai/models';
import { fauxProvider, fauxAssistantMessage } from '@earendil-works/pi-ai/providers/faux';
import {
  AssistantEntry,
  createRegistry,
  defineTask,
  defineExtension,
  Harness,
} from '@earendil-works/pi-durable';
import { openNodeSqliteStorage } from '@earendil-works/pi-durable/storage/sqlite/node';

const context = BACKGROUND_CONTEXT;

test('SQLite reopens pending task and model submission without duplicate admission', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'durable-proof-'));
  const models = createModels();
  const faux = fauxProvider();
  models.setProvider(faux.provider);
  let release = false;
  let entered!: () => void;

  const started = new Promise<void>((resolve) => {
    entered = resolve;
  });

  const Task = defineTask<null, { phase: 'work' }, string>({
    name: 'proof.pending',
    version: 1,
    initial: () => ({ phase: 'work' }),
    phases: {
      work: async (_task, runtime, ctx) => {
        entered();

        if (!release) await runtime.sleep(runtime.now() + 60000, ctx);
        await runtime.commit(
          () => ({ status: 'terminal', outcome: { status: 'completed', result: 'recovered' } }),
          ctx,
        );
      },
    },
    abort: async (_task, runtime, ctx) => {
      await runtime.commit(() => ({ status: 'terminal', outcome: { status: 'aborted' } }), ctx);
    },
  });

  const registry = createRegistry();
  registry.install(defineExtension({ name: 'proof', tasks: [Task] }));

  const open = () =>
    openNodeSqliteStorage(join(directory, 'state.sqlite')).then((storage) =>
      Harness.open(storage, { models, registry }, context),
    );

  let harness = await open();

  try {
    const root = await harness.root(context, {
      agent: { model: { provider: 'faux', modelId: 'faux-1' } },
    });

    const taskId = await root.commit(
      (tx) => tx.createTask(Task, null, { ownership: { kind: 'conversation' } }),
      context,
    );

    harness.resume();
    await started;
    await harness.close(context);
    release = true;
    harness = await open();
    const reopened = await harness.root(context);
    assert.equal(reopened.id, root.id);
    const task = await harness.waitForTask(taskId, context);
    assert.deepEqual(task.state.outcome, { status: 'completed', result: 'recovered' });
    faux.setResponses([fauxAssistantMessage('actual answer')]);
    const input = { type: 'input', content: 'hello', requestId: 'stable-id' } as const;
    const submission = await reopened.submit(input, context);
    const settled = await submission.wait(context);
    assert.ok(settled.status === 'done' && settled.type === 'input');
    await harness.close(context);
    harness = await open();
    const resumed = await harness.root(context);
    const duplicate = await resumed.submit(input, context);
    assert.equal(duplicate.id, submission.id);
    const entry = await resumed.commit((tx) => tx.entry(AssistantEntry, settled.answer), context);
    assert.equal(entry?.model?.[0]?.role, 'assistant');
    assert.equal(faux.state.callCount, 1);
  } finally {
    await harness.close(context);
    await rm(directory, { recursive: true, force: true });
  }
});
