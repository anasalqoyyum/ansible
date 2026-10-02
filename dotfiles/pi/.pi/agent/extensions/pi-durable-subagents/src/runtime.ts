import { createHash } from 'node:crypto';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { BACKGROUND_CONTEXT } from '@earendil-works/chord/context';
import type { Models } from '@earendil-works/pi-ai';
import {
  configure,
  createRegistry,
  defineExtension,
  defineTask,
  Harness,
  watchEvents,
  type Conversation,
  type TaskId,
  type ToolRegistration,
} from '@earendil-works/pi-durable';
import { openNodeSqliteStorage } from '@earendil-works/pi-durable/storage/sqlite/node';
import { NodeExecutionEnv } from '@earendil-works/pi-durable/env/node';
import { codingTools } from './tools.ts';
import {
  Fleet,
  type AgentRecord,
  type ResolvedConfiguration,
  type Result,
  type Report,
  type Worktree,
} from './state.ts';

export const context = BACKGROUND_CONTEXT;

export type IsolationServices = {
  prepare: (agentId: string, configuration: ResolvedConfiguration) => Promise<Worktree>;
  verify: (worktree: Worktree) => Promise<void>;
  status: (worktree: Worktree) => Promise<string>;
};

export type RuntimeOptions = {
  directory: string;
  parentSession: string;
  models: Models;
  isolation?: IsolationServices;
  extraTools?: ToolRegistration[];
};

export async function openRuntime(options: RuntimeOptions) {
  await mkdir(options.directory, { recursive: true, mode: 0o700 });
  const key = createHash('sha256').update(options.parentSession).digest('hex');
  const path = join(options.directory, `${key}.sqlite`);
  const lease = new DatabaseSync(`${path}.owner`);

  try {
    lease.exec('PRAGMA busy_timeout=0; BEGIN EXCLUSIVE');
  } catch (error) {
    lease.close();
    throw new Error(`Another runtime owns Durable storage for parent ${options.parentSession}`, {
      cause: error,
    });
  }

  let harness: Harness | undefined;

  try {
    const registry = createRegistry();

    const coding = defineExtension({
      name: 'durable-subagents.coding',
      tools: [...codingTools, ...(options.extraTools ?? [])],
    });

    registry.install(coding);

    const Anchor = defineTask<null, { phase: 'done' }, null>({
      name: 'durable-subagents.anchor',
      version: 1,
      initial: () => ({ phase: 'done' }),
      phases: {
        done: (_task, runtime, ctx) =>
          runtime.commit(
            () => ({ status: 'terminal', outcome: { status: 'completed', result: null } }),
            ctx,
          ),
      },
      abort: (_task, runtime, ctx) =>
        runtime.commit(() => ({ status: 'terminal', outcome: { status: 'aborted' } }), ctx),
    });

    type Input = {
      agentId: string;
      message: string;
      mode: 'steer' | 'followUp';
      background: boolean;
    };

    const Runner = defineTask<Input, { phase: 'deliver' }, Result>({
      name: 'durable-subagents.runner',
      version: 1,
      initial: () => ({ phase: 'deliver' }),
      phases: {
        deliver: async (task, runtime, ctx) => {
          const agent = (await runtime.snapshot(Fleet, runtime.conversationId, ctx))?.agents[
            task.input.agentId
          ];

          if (!agent) throw new Error(`Missing agent ${task.input.agentId}`);
          const child = await runtime.conversation(agent.conversationId, ctx);

          if (!child) throw new Error(`Missing child conversation ${agent.conversationId}`);

          const settled = await (
            await child.submit(
              {
                type: 'input',
                content: task.input.message,
                whenBusy: task.input.mode,
                requestId: `agent-input:${task.id}`,
              },
              ctx,
            )
          ).wait(ctx);

          let result: Result;
          let reportId = `agent-report:${task.id}`;

          if (settled.status === 'done' && settled.type === 'input') {
            const entry = (await runtime.context(agent.conversationId, ctx)).entries.find(
              (entry) => entry.id === settled.answer,
            );

            const text =
              entry?.model
                ?.flatMap((message) =>
                  !Array.isArray(message.content)
                    ? [message.content]
                    : message.content.flatMap((part) => (part.type === 'text' ? [part.text] : [])),
                )
                .join('') ?? '';

            result = { status: 'completed', text };
            reportId = `agent-answer:${agent.conversationId}:${settled.answer}`;
          } else {
            const reason =
              settled.status === 'unanswered' ? settled.reason : 'unexpected submission';

            result = {
              status: reason === 'aborted' ? 'stopped' : 'failed',
              text: `Agent ${agent.name} ${reason === 'aborted' ? 'stopped' : `failed: ${reason}`}`,
            };
          }

          let changedFiles: string | undefined;

          if (agent.worktree && options.isolation) {
            try {
              changedFiles = await options.isolation.status(agent.worktree);
            } catch (error) {
              const message = error instanceof Error ? error.message : String(error);
              result = {
                status: 'failed',
                text: `${result.text}\nWorktree inspection failed: ${message}`,
              };
              changedFiles = message;
            }
          }

          await runtime.commit(async (tx) => {
            const fleet = await tx.doc(Fleet, runtime.conversationId);
            const record = fleet.agents[agent.id]!;

            if (record.tasks.at(-1) === task.id) {
              record.result = result;
              record.finishedAt = runtime.now();
            }

            if (changedFiles !== undefined) record.changedFiles = changedFiles;

            if (task.input.background && !fleet.outbox[reportId]) {
              const report: Report = { id: reportId, agentId: agent.id, result, state: 'pending' };

              if (agent.worktree) {
                report.worktree = agent.worktree;
                report.changedFiles = changedFiles ?? '';
              }

              fleet.outbox[reportId] = report;
            }

            return { status: 'terminal', outcome: { status: 'completed', result } };
          }, ctx);
        },
      },
      abort: async (task, runtime, ctx) => {
        const result: Result = { status: 'stopped', text: 'Agent stopped' };
        await runtime.commit(async (tx) => {
          const agent = (await tx.doc(Fleet, runtime.conversationId)).agents[task.input.agentId];

          if (agent?.tasks.at(-1) === task.id) {
            agent.result = result;
            agent.finishedAt = runtime.now();
          }

          return { status: 'terminal', outcome: { status: 'aborted' } };
        }, ctx);
      },
    });

    registry.install(
      defineExtension({ name: 'durable-subagents.execution', tasks: [Anchor, Runner] }),
    );
    harness = await Harness.open(
      await openNodeSqliteStorage(path),
      {
        models: options.models,
        registry,
        settings: {
          retry: { enabled: false },
          stream: { timeoutMs: 120000 },
          toolExecution: 'parallel',
        },
        env: async ({ cwd, conversationId, read }, ctx) => {
          const fleet = await read.snapshot(Fleet, root.id, ctx);

          const agent = Object.values(fleet?.agents ?? {}).find(
            (agent) => agent.conversationId === conversationId,
          );

          if (agent?.worktree) {
            if (!options.isolation)
              throw new Error('Worktree support is unavailable. Refusing parent cwd fallback.');
            await options.isolation.verify(agent.worktree);
          }

          if (!cwd) throw new Error('Agent has no recorded cwd');

          return new NodeExecutionEnv({ cwd });
        },
      },
      context,
    );
    const active = harness;
    const root = await active.root(context);
    await root.commit(async (tx) => {
      const fleet = await tx.doc(Fleet, root.id);

      if (fleet.parentSession && fleet.parentSession !== options.parentSession)
        throw new Error('Parent session mismatch');
      fleet.parentSession = options.parentSession;
    }, context);
    let closed = false;
    const disposers = new Set<() => void>();
    const snapshot = () => active.snapshot(Fleet, root.id, context);

    const reconcileFailures = async () => {
      for (const agent of Object.values((await snapshot())?.agents ?? {})) {
        for (const id of agent.tasks) {
          const task = await active.getTask(id, context);

          if (!task || task.state.status !== 'terminal') continue;
          const outcome = task.state.outcome;

          if (
            outcome.status !== 'faulted' &&
            outcome.status !== 'failed' &&
            outcome.status !== 'orphaned'
          )
            continue;

          const result: Result = {
            status: 'failed',
            text: `Agent ${agent.name} ${outcome.status}: ${outcome.status === 'orphaned' ? outcome.reason : outcome.error.message}`,
          };

          const reportId = `agent-fault:${id}`;
          await root.commit(async (tx) => {
            const fleet = await tx.doc(Fleet, root.id);
            const record = fleet.agents[agent.id]!;

            if (record.tasks.at(-1) === id && !record.finishedAt) {
              record.result = result;
              record.finishedAt = Date.now();
            }

            if (task.background && !fleet.outbox[reportId]) {
              const report: Report = { id: reportId, agentId: agent.id, result, state: 'pending' };

              if (agent.worktree) {
                report.worktree = agent.worktree;
                report.changedFiles = agent.changedFiles ?? '';
              }

              fleet.outbox[reportId] = report;
            }
          }, context);
        }
      }
    };

    const events = await watchEvents(active, root.id, context);
    let reconciling = Promise.resolve();
    events.start((batch) => {
      if (batch.some((event) => event.type === 'task_failed' || event.type === 'snapshot'))
        reconciling = reconciling.then(reconcileFailures);

      return reconciling;
    });
    await reconcileFailures();

    const get = async (id: string) => {
      const fleet = await snapshot();
      const direct = fleet?.agents[id];

      if (direct) return direct;
      const matches = Object.values(fleet?.agents ?? {}).filter((agent) => agent.name === id);

      if (matches.length !== 1) throw new Error(`Unknown or ambiguous agent: ${id}`);

      return matches[0]!;
    };

    const conversation = async (agent: AgentRecord): Promise<Conversation> => {
      const child = await active.conversation(agent.conversationId, context);

      if (!child) throw new Error(`Missing conversation for ${agent.id}`);

      return child;
    };

    let admissions = Promise.resolve();

    const start = async (input: {
      requestId: string;
      name: string;
      description: string;
      message: string;
      configuration: ResolvedConfiguration;
      background: boolean;
    }) => {
      if (closed) throw new Error('Durable runtime is closed');

      const admission = admissions.then(async () => {
        const fleet = await snapshot();
        const previous = fleet?.requests[input.requestId];

        if (previous) return previous;

        if (Object.values(fleet?.agents ?? {}).some((agent) => agent.name === input.name))
          throw new Error(`Agent name ${input.name} already exists. Use resume or steer.`);

        const worktree =
          input.configuration.isolation === 'worktree'
            ? await options.isolation?.prepare(input.requestId, input.configuration)
            : undefined;

        if (input.configuration.isolation === 'worktree' && !worktree)
          throw new Error('Worktree support is unavailable');

        return root.commit(async (tx) => {
          const fleet = await tx.doc(Fleet, root.id);

          const runner = await tx.createTask(
            Runner,
            {
              agentId: input.requestId,
              message: input.message,
              background: input.background,
              mode: 'followUp',
            } satisfies Input,
            { ownership: { kind: 'conversation' }, background: input.background },
          );

          const owner = input.background
            ? await tx.createTask(Anchor, null, {
                ownership: { kind: 'conversation' },
                background: true,
              })
            : runner;

          const configuration = {
            ...input.configuration,
            cwd: worktree?.path ?? input.configuration.cwd,
          };

          const selectedTools =
            coding.tools?.filter((tool) => configuration.tools.includes(tool.name)) ?? [];

          if (selectedTools.length !== configuration.tools.length)
            throw new Error('Unknown tool in saved allowlist');
          const child = await tx.createConversation({ ownership: { kind: 'task', taskId: owner } });
          await configure(tx, child.id, {
            model: configuration.model,
            thinkingLevel: configuration.thinking,
            instructions:
              configuration.instructions +
              (configuration.history
                ? `\n\nParent history, supplied as context:\n${configuration.history}`
                : ''),
            cwd: configuration.cwd,
            extensions: [coding],
            tools: selectedTools,
          });
          fleet.requests[input.requestId] = runner;

          const record: AgentRecord = {
            id: input.requestId,
            name: input.name,
            description: input.description,
            configuration,
            conversationId: child.id,
            ownerTask: owner,
            tasks: [runner],
            startedAt: Date.now(),
          };

          if (worktree) record.worktree = worktree;
          fleet.agents[input.requestId] = record;

          return runner;
        }, context);
      });

      admissions = admission.then(
        () => undefined,
        () => undefined,
      );

      return admission;
    };

    const send = async (input: {
      id: string;
      requestId: string;
      message: string;
      followUp: boolean;
      background?: boolean;
    }) => {
      if (closed) throw new Error('Durable runtime is closed');
      const agent = await get(input.id);

      return root.commit(async (tx) => {
        const fleet = await tx.doc(Fleet, root.id);
        const existing = fleet.requests[input.requestId];

        if (existing) return existing;

        const task = await tx.createTask(
          Runner,
          {
            agentId: agent.id,
            message: input.message,
            mode: input.followUp ? 'followUp' : 'steer',
            background: input.background ?? true,
          } satisfies Input,
          { ownership: { kind: 'conversation' }, background: input.background ?? true },
        );

        fleet.requests[input.requestId] = task;
        fleet.agents[agent.id]!.tasks.push(task);
        delete fleet.agents[agent.id]!.finishedAt;

        return task;
      }, context);
    };

    const wait = async (taskId: TaskId<Result>, signal?: AbortSignal): Promise<Result> => {
      let cancellation = Promise.resolve();

      const cancel = () => {
        cancellation = (async () => {
          const agent = Object.values((await snapshot())?.agents ?? {}).find((agent) =>
            agent.tasks.includes(taskId),
          );

          if (agent) await stop(agent.id);
          else await active.abortTask(taskId, context);
        })();
      };

      signal?.addEventListener('abort', cancel, { once: true });

      if (signal?.aborted) cancel();

      try {
        const task = await active.waitForTask(taskId, context);
        await cancellation;
        const outcome = task.state.outcome;

        if (
          outcome.status === 'faulted' ||
          outcome.status === 'failed' ||
          outcome.status === 'orphaned'
        )
          await reconcileFailures();

        if (outcome.status === 'completed') return outcome.result;

        return {
          status: outcome.status === 'aborted' ? 'stopped' : 'failed',
          text: `Agent task ${outcome.status}`,
        };
      } finally {
        signal?.removeEventListener('abort', cancel);
      }
    };

    const stop = async (id: string) => {
      const agent = await get(id);
      await Promise.all(agent.tasks.map((task) => active.abortTask(task, context)));
      await (await conversation(agent)).abort(context);
      await Promise.all(agent.tasks.map((task) => active.waitForTask(task, context)));
    };

    const subscribe = async (listener: () => void) => {
      const state = await active.documentState(Fleet, root.id, context);

      if (!state) throw new Error('Fleet document is missing');
      const unsubscribe = state.subscribe(() => listener());

      const dispose = () => {
        unsubscribe();
        state.dispose();
        disposers.delete(dispose);
      };

      disposers.add(dispose);

      return dispose;
    };

    active.resume();

    return {
      harness: active,
      root,
      snapshot,
      get,
      conversation,
      start,
      send,
      wait,
      stop,
      subscribe,
      async acknowledge(reportId: string) {
        await root.commit(async (tx) => {
          const report = (await tx.doc(Fleet, root.id)).outbox[reportId];

          if (report) report.state = 'delivered';
        }, context);
      },
      async close() {
        if (closed) return;
        closed = true;

        for (const dispose of disposers) dispose();

        try {
          await admissions;
          await events.stop();
          await reconciling;
        } finally {
          try {
            await active.close(context);
          } finally {
            lease.close();
          }
        }
      },
    };
  } catch (error) {
    try {
      await harness?.close(context);
    } finally {
      lease.close();
    }

    throw error;
  }
}

export type Runtime = Awaited<ReturnType<typeof openRuntime>>;
