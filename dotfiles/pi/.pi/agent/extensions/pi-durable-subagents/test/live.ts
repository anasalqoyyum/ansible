import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ModelRuntime, ModelRegistry } from '@earendil-works/pi-coding-agent';
import { BACKGROUND_CONTEXT } from '@earendil-works/chord/context';
import { AssistantEntry, createRegistry, Harness } from '@earendil-works/pi-durable';
import { openNodeSqliteStorage } from '@earendil-works/pi-durable/storage/sqlite/node';
import { modelsFromPi } from '../src/models.ts';

const runtime = await ModelRuntime.create({ refreshOnCreate: false });

const registry = new ModelRegistry(runtime);

const model = registry.find('openai', 'gpt-6-luna');

assert.ok(model, 'Policy model openai/gpt-6-luna is unavailable');

const auth = await registry.getApiKeyAndHeaders(model);

assert.ok(auth.ok, 'Configured Pi credentials could not be resolved');

const directory = await mkdtemp(join(tmpdir(), 'durable-live-'));

const context = BACKGROUND_CONTEXT;

const bridge = modelsFromPi(registry);

const harness = await Harness.open(
  await openNodeSqliteStorage(join(directory, 'live.sqlite')),
  {
    models: {
      ...bridge,
      streamSimple: (model, input, options) =>
        bridge.streamSimple(model, input, { ...options, maxTokens: 512 }),
    },
    registry: createRegistry(),
    settings: {
      stream: { timeoutMs: 45000, maxRetries: 0 },
      retry: { enabled: false },
      compaction: { enabled: false },
    },
  },
  context,
);

try {
  const root = await harness.root(context);

  const child = await harness.createConversation(
    {
      ownership: { kind: 'ownerless' },
      agent: {
        model: { provider: model.provider, modelId: model.id },
        thinkingLevel: 'max',
        tools: [],
        instructions: 'Reply exactly DURABLE_OK. Do not use tools.',
      },
    },
    context,
  );

  const settled = await (
    await child.submit(
      { type: 'input', content: 'Return the requested marker.', requestId: 'live-proof' },
      context,
    )
  ).wait(context);

  assert.equal(settled.status, 'done', JSON.stringify(settled));
  assert.ok(settled.status === 'done' && settled.type === 'input');
  const entry = await child.commit((tx) => tx.entry(AssistantEntry, settled.answer), context);

  const text = entry?.model
    ?.flatMap((message) =>
      !Array.isArray(message.content)
        ? [message.content]
        : message.content.flatMap((part) => (part.type === 'text' ? [part.text] : [])),
    )
    .join('');

  assert.equal(text?.trim(), 'DURABLE_OK');
  console.log(
    `Durable child passed using ${model.provider}/${model.id}, max effort, and Pi's existing credential runtime. Root ${root.id}; child ${child.id}.`,
  );
} finally {
  await harness.close(context);
  await rm(directory, { recursive: true, force: true });
}
