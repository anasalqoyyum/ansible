import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { createModels, Type } from '@earendil-works/pi-ai';
import {
  fauxProvider,
  fauxAssistantMessage,
  fauxToolCall,
} from '@earendil-works/pi-ai/providers/faux';
import { defineTool, defineTask } from '@earendil-works/pi-durable';
import { openRuntime, context } from '../src/runtime.ts';
import { reportDelivery } from '../src/reports.ts';
import { Fleet, type ResolvedConfiguration, type Result } from '../src/state.ts';

export const configuration: ResolvedConfiguration = {
  role: 'general-purpose',
  model: { provider: 'faux', modelId: 'faux-1' },
  thinking: 'off',
  instructions: 'Test',
  tools: [],
  cwd: tmpdir(),
  project: tmpdir(),
  isolation: 'off',
  history: '',
};

export async function until(check: () => Promise<boolean>) {
  for (let n = 0; n < 500; n++) {
    if (await check()) return;
    await delay(10);
  }

  throw new Error('Condition timed out');
}

async function fixture() {
  const directory = await mkdtemp(join(tmpdir(), 'fleet-tests-'));
  const faux = fauxProvider();
  const models = createModels();
  models.setProvider(faux.provider);
  const options = { directory, models, parentSession: 'parent-one' };

  return {
    directory,
    faux,
    options,
    cleanup: () => rm(directory, { recursive: true, force: true }),
  };
}

const spawn = (id: string, background = false, config = configuration) => ({
  requestId: id,
  name: id,
  description: 'test agent',
  message: id,
  background,
  configuration: config,
});

test('foreground actual answer, stable child ownership, result persistence, and exclusive parent scope', async () => {
  const f = await fixture();
  let runtime = await openRuntime(f.options);

  try {
    f.faux.setResponses([fauxAssistantMessage('real final answer')]);
    const task = await runtime.start(spawn('one'));
    assert.deepEqual(await runtime.wait(task), { status: 'completed', text: 'real final answer' });
    const first = await runtime.get('one');
    assert.equal(await runtime.start(spawn('one')), task);
    await assert.rejects(openRuntime(f.options), /Another runtime owns/);
    await runtime.close();
    runtime = await openRuntime(f.options);
    assert.equal((await runtime.get('one')).conversationId, first.conversationId);
    assert.equal((await runtime.get('one')).result?.text, 'real final answer');
    const other = await openRuntime({ ...f.options, parentSession: 'other' });
    assert.equal(Object.keys((await other.snapshot())!.agents).length, 0);
    await other.close();
  } finally {
    await runtime.close();
    await f.cleanup();
  }
});

test('background success and failure outbox, busy-parent queuing, reconciliation and ordinary deduplication', async () => {
  const f = await fixture();
  let runtime = await openRuntime(f.options);
  const seen = new Set<string>();
  const queued: string[] = [];
  let idle = false;

  try {
    f.faux.setResponses([
      fauxAssistantMessage('background answer'),
      fauxAssistantMessage('', { stopReason: 'error', errorMessage: 'provider rejected' }),
    ]);
    await runtime.wait(await runtime.start(spawn('ok', true)));
    const failure = await runtime.wait(await runtime.start(spawn('bad', true)));
    assert.equal(failure.status, 'failed');

    const parent = {
      seen: () => seen,
      send: (report: { id: string }) => {
        queued.push(report.id);

        if (idle) seen.add(report.id);
      },
    };

    const delivery = reportDelivery(runtime, parent);
    await delivery.flush();
    await delivery.flush();
    assert.equal(queued.length, 2);
    assert.equal(
      Object.values((await runtime.snapshot())!.outbox).filter(
        (report) => report.state === 'pending',
      ).length,
      2,
    );
    await delivery.close();
    await runtime.close();
    runtime = await openRuntime(f.options);
    idle = true;
    const reopened = reportDelivery(runtime, parent);
    await reopened.flush();
    await reopened.flush();
    assert.equal(
      Object.values((await runtime.snapshot())!.outbox).filter(
        (report) => report.state === 'delivered',
      ).length,
      2,
    );
    await reopened.settled();
    assert.equal(queued.length, 4);
    await reopened.close();
  } finally {
    await runtime.close();
    await f.cleanup();
  }
});

test('Esc aborts foreground ownership but leaves background running; stop cancels tools and queued inputs, then permits continuation', async () => {
  const f = await fixture();
  let calls = 0;
  let aborted = 0;

  const blocked = defineTool({
    name: 'block',
    description: 'wait',
    parameters: Type.Object({}),
    replay: 'unsafe',
    execute: async (_args, _api, ctx) => {
      calls++;

      try {
        await delay(60000, undefined, { signal: ctx.abortSignal });
      } catch (error) {
        aborted++;
        throw error;
      }

      return {};
    },
  });

  const runtime = await openRuntime({ ...f.options, extraTools: [blocked] });

  try {
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('block', {}), { stopReason: 'toolUse' }),
      fauxAssistantMessage(fauxToolCall('block', {}), { stopReason: 'toolUse' }),
    ]);

    const foreground = await runtime.start(
      spawn('fg', false, { ...configuration, tools: ['block'] }),
    );

    const background = await runtime.start(
      spawn('bg', true, { ...configuration, tools: ['block'] }),
    );

    await until(async () => calls === 2);
    const controller = new AbortController();
    const waiting = runtime.wait(foreground, controller.signal);
    controller.abort();
    assert.equal((await waiting).status, 'stopped');
    assert.equal(aborted, 1);

    const follow = await runtime.send({
      id: 'bg',
      requestId: 'bg-follow',
      message: 'queued',
      followUp: true,
    });

    await runtime.stop('bg');
    assert.equal((await runtime.wait(background)).status, 'stopped');
    assert.equal((await runtime.wait(follow)).status, 'stopped');
    assert.equal(aborted, 2);
    f.faux.setResponses([fauxAssistantMessage('continued')]);

    const next = await runtime.send({
      id: 'bg',
      requestId: 'continue',
      message: 'continue',
      followUp: true,
    });

    assert.equal((await runtime.wait(next)).text, 'continued');
    const child = await runtime.conversation(await runtime.get('bg'));
    assert.ok(
      (await child.context((await import('../src/runtime.ts')).context)).entries.length > 0,
    );
  } finally {
    await runtime.close();
    await f.cleanup();
  }
});

test('close pauses pending child; reopen does not rerun interrupted unsafe tools', async () => {
  const f = await fixture();
  let calls = 0;

  const unsafe = defineTool({
    name: 'unsafe',
    description: 'side effect',
    parameters: Type.Object({}),
    replay: 'unsafe',
    execute: async (_args, _api, ctx) => {
      calls++;
      await delay(60000, undefined, { signal: ctx.abortSignal });

      return {};
    },
  });

  const options = { ...f.options, extraTools: [unsafe] };
  let runtime = await openRuntime(options);

  try {
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('unsafe', {}), { stopReason: 'toolUse' }),
    ]);

    const task = await runtime.start(
      spawn('recover', true, { ...configuration, tools: ['unsafe'] }),
    );

    await until(async () => calls === 1);
    const childId = (await runtime.get('recover')).conversationId;
    await runtime.close();
    f.faux.setResponses([
      (request) => {
        assert.ok(
          request.messages.some((message) => message.role === 'toolResult' && message.isError),
        );

        return fauxAssistantMessage('interruption acknowledged');
      },
    ]);
    runtime = await openRuntime(options);
    assert.equal((await runtime.get('recover')).conversationId, childId);
    assert.equal((await runtime.wait(task)).text, 'interruption acknowledged');
    assert.equal(calls, 1);
    assert.equal(Object.values((await runtime.snapshot())!.outbox).length, 1);
  } finally {
    await runtime.close();
    await f.cleanup();
  }
});

test('faulted Runner receipts update the fleet and produce a deduplicated recoverable failure report', async () => {
  const f = await fixture();
  let runtime = await openRuntime(f.options);

  try {
    f.faux.setResponses([fauxAssistantMessage('initial')]);
    await runtime.wait(await runtime.start(spawn('fault', true)));

    const malformed = defineTask<{ agentId: string }, { phase: 'deliver' }, Result>({
      name: 'durable-subagents.runner',
      version: 1,
      initial: () => ({ phase: 'deliver' }),
      phases: {
        deliver: async () => {
          throw new Error('The registered real Runner must execute instead');
        },
      },
      abort: (_task, active, ctx) =>
        active.commit(() => ({ status: 'terminal', outcome: { status: 'aborted' } }), ctx),
    });

    const task = await runtime.root.commit(async (tx) => {
      const id = await tx.createTask(
        malformed,
        { agentId: 'missing-agent' },
        { ownership: { kind: 'conversation' }, background: true },
      );

      const record = (await tx.doc(Fleet, runtime.root.id)).agents.fault!;
      record.tasks.push(id);
      delete record.finishedAt;

      return id;
    }, context);

    await until(async () =>
      Object.values((await runtime.snapshot())!.outbox).some(
        (report) => report.id === `agent-fault:${task}`,
      ),
    );
    const record = await runtime.get('fault');
    assert.equal(record.result?.status, 'failed');
    assert.match(record.result!.text, /Missing agent missing-agent/);
    assert.ok(record.finishedAt);
    const receipt = await runtime.harness.getTask(task, context);
    assert.equal(receipt?.state.outcome?.status, 'faulted');
    await runtime.close();
    runtime = await openRuntime(f.options);
    assert.equal((await runtime.get('fault')).result?.status, 'failed');
    assert.equal(
      Object.values((await runtime.snapshot())!.outbox).filter(
        (report) => report.id === `agent-fault:${task}`,
      ).length,
      1,
    );
  } finally {
    await runtime.close();
    await f.cleanup();
  }
});
