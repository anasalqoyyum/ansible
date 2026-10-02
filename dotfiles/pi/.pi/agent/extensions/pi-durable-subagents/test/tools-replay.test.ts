import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { withFileMutationQueue } from '@earendil-works/pi-coding-agent';
import { createModels } from '@earendil-works/pi-ai';
import {
  fauxProvider,
  fauxAssistantMessage,
  fauxToolCall,
} from '@earendil-works/pi-ai/providers/faux';
import { LiveDoc } from '@earendil-works/pi-durable';
import { openRuntime, context } from '../src/runtime.ts';
import type { ResolvedConfiguration } from '../src/state.ts';

async function until(check: () => Promise<boolean>) {
  for (let n = 0; n < 500; n++) {
    if (await check()) return;
    await delay(10);
  }

  throw new Error('Tool condition timed out');
}

async function fixture() {
  const directory = await mkdtemp(join(tmpdir(), 'tools-replay-'));
  const faux = fauxProvider();
  const models = createModels();
  models.setProvider(faux.provider);

  const configuration: ResolvedConfiguration = {
    role: 'general-purpose',
    model: { provider: 'faux', modelId: 'faux-1' },
    thinking: 'off',
    tools: ['read', 'write', 'edit', 'bash'],
    instructions: 'tools',
    cwd: directory,
    project: directory,
    history: '',
    isolation: 'off',
  };

  return {
    directory,
    faux,
    configuration,
    options: { directory: join(directory, 'state'), parentSession: 'tools', models },
  };
}

test('interrupted real shell is killed and is not replayed after reopen', async () => {
  const f = await fixture();
  let runtime = await openRuntime(f.options);

  try {
    f.faux.setResponses([
      fauxAssistantMessage(
        fauxToolCall('bash', { command: 'printf x >> count; printf READY; sleep 60' }),
        { stopReason: 'toolUse' },
      ),
    ]);

    const task = await runtime.start({
      requestId: 'shell',
      name: 'shell',
      description: 'shell',
      message: 'run',
      configuration: f.configuration,
      background: true,
    });

    const agent = await runtime.get('shell');
    await until(
      async () =>
        (await runtime.harness.snapshot(LiveDoc, agent.conversationId, context))?.tools?.some(
          (tool) => tool.output?.includes('READY'),
        ) ?? false,
    );
    await runtime.close();
    assert.equal(await readFile(join(f.directory, 'count'), 'utf8'), 'x');
    f.faux.setResponses([
      (request) => {
        assert.ok(
          request.messages.some((message) => message.role === 'toolResult' && message.isError),
        );

        return fauxAssistantMessage('shell interruption reported');
      },
    ]);
    runtime = await openRuntime(f.options);
    assert.equal((await runtime.wait(task)).text, 'shell interruption reported');
    assert.equal(await readFile(join(f.directory, 'count'), 'utf8'), 'x');
  } finally {
    await runtime.close();
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('file tools coordinate the full mutation with the parent SDK queue', async () => {
  const f = await fixture();
  const runtime = await openRuntime(f.options);
  let release!: () => void;

  const gate = new Promise<void>((resolve) => {
    release = resolve;
  });

  try {
    const path = join(f.directory, 'shared.txt');
    await writeFile(path, 'initial');

    const parent = withFileMutationQueue(path, async () => {
      await gate;
      await writeFile(path, 'parent');
    });

    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('write', { path: 'shared.txt', content: 'child' }), {
        stopReason: 'toolUse',
      }),
      fauxAssistantMessage('wrote'),
    ]);

    const task = await runtime.start({
      requestId: 'write',
      name: 'write',
      description: 'write',
      message: 'write',
      configuration: f.configuration,
      background: true,
    });

    const agent = await runtime.get('write');
    await until(
      async () =>
        (await runtime.harness.snapshot(LiveDoc, agent.conversationId, context))?.tools?.some(
          (tool) => tool.status === 'running',
        ) ?? false,
    );
    assert.equal(await readFile(path, 'utf8'), 'initial');
    release();
    await parent;
    await runtime.wait(task);
    assert.equal(await readFile(path, 'utf8'), 'child');
  } finally {
    release?.();
    await runtime.close();
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('steering and queued follow-ups reach only the intended child; resolved permissions and instructions survive reopen', async () => {
  const f = await fixture();
  let runtime = await openRuntime(f.options);

  try {
    f.faux.setResponses([fauxAssistantMessage('A first'), fauxAssistantMessage('B first')]);

    const a = await runtime.start({
      requestId: 'a',
      name: 'a',
      description: 'a',
      message: 'A original',
      configuration: f.configuration,
      background: true,
    });

    await runtime.wait(a);
    await runtime.wait(
      await runtime.start({
        requestId: 'b',
        name: 'b',
        description: 'b',
        message: 'B original',
        configuration: f.configuration,
        background: true,
      }),
    );
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('bash', { command: 'sleep 0.15' }), {
        stopReason: 'toolUse',
      }),
      (request) => {
        assert.ok(JSON.stringify(request.messages).includes('A steer'));
        assert.ok(!JSON.stringify(request.messages).includes('B original'));

        return fauxAssistantMessage('A steered');
      },
      (request) => {
        assert.ok(JSON.stringify(request.messages).includes('A queued'));

        return fauxAssistantMessage('A follow-up');
      },
    ]);

    const run = await runtime.send({
      id: 'a',
      requestId: 'a-run',
      message: 'A run',
      followUp: true,
    });

    const agent = await runtime.get('a');
    await until(
      async () =>
        (await runtime.harness.snapshot(LiveDoc, agent.conversationId, context))?.tools?.some(
          (tool) => tool.status === 'running',
        ) ?? false,
    );

    const steer = await runtime.send({
      id: 'a',
      requestId: 'a-steer',
      message: 'A steer',
      followUp: false,
    });

    const follow = await runtime.send({
      id: 'a',
      requestId: 'a-follow',
      message: 'A queued',
      followUp: true,
    });

    assert.equal((await runtime.wait(run)).text, 'A steered');
    assert.equal((await runtime.wait(steer)).text, 'A steered');
    assert.equal((await runtime.wait(follow)).text, 'A follow-up');
    assert.equal((await runtime.get('b')).result?.text, 'B first');
    const saved = (await runtime.get('a')).configuration;
    await runtime.close();
    runtime = await openRuntime(f.options);
    assert.deepEqual((await runtime.get('a')).configuration, saved);
    const restored = await (await runtime.conversation(await runtime.get('a'))).agent(context);
    assert.equal(restored.instructions, saved.instructions);
    assert.deepEqual(
      restored.tools.map((tool) => tool.name),
      saved.tools,
    );
    assert.equal(restored.cwd, saved.cwd);
  } finally {
    await runtime.close();
    await rm(f.directory, { recursive: true, force: true });
  }
});
