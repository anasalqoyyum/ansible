import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { setTimeout as delay } from 'node:timers/promises';
import {
  createAgentSessionRuntime,
  createAgentSessionServices,
  createAgentSessionFromServices,
  ModelRuntime,
  SettingsManager,
  SessionManager,
  type CreateAgentSessionRuntimeFactory,
} from '@earendil-works/pi-coding-agent';
import {
  fauxProvider,
  fauxAssistantMessage,
  fauxToolCall,
} from '@earendil-works/pi-ai/providers/faux';

async function until(check: () => boolean) {
  for (let n = 0; n < 500; n++) {
    if (check()) return;
    await delay(10);
  }

  throw new Error('SDK condition timed out');
}

async function fixture(
  options: {
    allowWrites?: boolean;
    agents?: Record<string, string>;
    projectAgents?: Record<string, string>;
  } = {},
) {
  const directory = await mkdtemp(join(tmpdir(), 'extension-test-'));
  const previous = process.env.PI_CODING_AGENT_DIR;
  process.env.PI_CODING_AGENT_DIR = directory;

  for (const [location, agents] of [
    ['agents', options.agents],
    [join('.pi', 'agents'), options.projectAgents],
  ] as const) {
    if (!agents) continue;
    await mkdir(join(directory, location), { recursive: true });

    for (const [name, content] of Object.entries(agents))
      await writeFile(join(directory, location, `${name}.md`), content);
  }

  const faux = fauxProvider();

  const models = await ModelRuntime.create({
    authPath: join(directory, 'auth.json'),
    modelsPath: null,
    refreshOnCreate: false,
  });

  models.registerNativeProvider(faux.provider);

  const create: CreateAgentSessionRuntimeFactory = async ({
    cwd,
    agentDir,
    sessionManager,
    sessionStartEvent,
  }) => {
    const services = await createAgentSessionServices({
      cwd,
      agentDir,
      modelRuntime: models,
      settingsManager: SettingsManager.inMemory({
        defaultThinkingLevel: 'off',
        compaction: { enabled: false },
        retry: { enabled: false },
      }),
      resourceLoaderOptions: {
        noExtensions: true,
        noSkills: true,
        noPromptTemplates: true,
        noThemes: true,
        noContextFiles: true,
        additionalExtensionPaths: [fileURLToPath(new URL('../src/extension.ts', import.meta.url))],
      },
    });

    return {
      ...(await createAgentSessionFromServices({
        services,
        sessionManager,
        sessionStartEvent,
        model: faux.getModel(),
        thinkingLevel: 'off',
        tools: [
          'Agent',
          'get_subagent_result',
          'steer_subagent',
          'stop_subagent',
          'cleanup_subagent_worktree',
        ],
      })),
      services,
      diagnostics: services.diagnostics,
    };
  };

  const sessionManager = SessionManager.create(directory, join(directory, 'sessions'));

  if (options.allowWrites !== false)
    sessionManager.appendCustomEntry('durable-subagents.policy', { allowWrites: true });

  const runtime = await createAgentSessionRuntime(create, {
    cwd: directory,
    agentDir: directory,
    sessionManager,
  });

  const errors: string[] = [];

  const bind = async () => {
    await runtime.session.bindExtensions({
      mode: 'json',
      onError: (error) => errors.push(error.error),
    });
  };

  await bind();

  return {
    directory,
    faux,
    runtime,
    bind,
    errors,
    cleanup: async () => {
      await runtime.dispose();

      if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR;
      else process.env.PI_CODING_AGENT_DIR = previous;
      await rm(directory, { recursive: true, force: true });
    },
  };
}

test('isolated real Pi loader has one implementation, foreground answer, strict legacy rejection, reload and session-scoped retrieval', async () => {
  const f = await fixture();

  try {
    const expected = [
      'Agent',
      'get_subagent_result',
      'steer_subagent',
      'stop_subagent',
      'cleanup_subagent_worktree',
    ];

    assert.deepEqual(f.runtime.session.getActiveToolNames().sort(), expected.sort());
    f.faux.setResponses([
      fauxAssistantMessage(
        fauxToolCall('Agent', {
          prompt: 'task',
          description: 'task',
          name: 'worker',
          run_in_background: false,
        }),
        { stopReason: 'toolUse' },
      ),
      fauxAssistantMessage('child actual answer'),
      (request) => {
        assert.ok(JSON.stringify(request.messages).includes('child actual answer'));

        return fauxAssistantMessage('parent done');
      },
    ]);
    await f.runtime.session.prompt('Delegate foreground');
    assert.equal(f.runtime.session.getLastAssistantText(), 'parent done');
    await f.runtime.session.reload();
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('get_subagent_result', { agent_id: 'worker' }), {
        stopReason: 'toolUse',
      }),
      (request) => {
        assert.ok(JSON.stringify(request.messages).includes('child actual answer'));

        return fauxAssistantMessage('retrieved');
      },
    ]);
    await f.runtime.session.prompt('Retrieve after reload');
    assert.equal(f.runtime.session.getLastAssistantText(), 'retrieved');
    f.faux.setResponses([
      fauxAssistantMessage(
        fauxToolCall('Agent', { prompt: 'task', description: 'task', schedule: '5m' }),
        { stopReason: 'toolUse' },
      ),
      (request) => {
        assert.ok(
          request.messages.some((message) => message.role === 'toolResult' && message.isError),
        );

        return fauxAssistantMessage('unsupported field rejected');
      },
    ]);
    await f.runtime.session.prompt('Reject legacy schedule');
    const original = f.runtime.session.sessionFile!;
    await f.runtime.newSession();
    await f.bind();
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('get_subagent_result', { agent_id: 'worker' }), {
        stopReason: 'toolUse',
      }),
      (request) => {
        assert.ok(
          request.messages.some((message) => message.role === 'toolResult' && message.isError),
        );

        return fauxAssistantMessage('separate parent');
      },
    ]);
    await f.runtime.session.prompt('Other parent cannot retrieve worker');
    await f.runtime.switchSession(original);
    await f.bind();
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('get_subagent_result', { agent_id: 'worker' }), {
        stopReason: 'toolUse',
      }),
      fauxAssistantMessage('resumed original parent'),
    ]);
    await f.runtime.session.prompt('Original parent can retrieve');
    assert.deepEqual(f.errors, []);
    assert.ok(!f.runtime.diagnostics.some((diagnostic) => diagnostic.type === 'error'));
  } finally {
    await f.cleanup();
  }
});

test('write-capable subagents are blocked without session authorization while read-only roles run', async () => {
  const f = await fixture({ allowWrites: false });

  try {
    f.faux.setResponses([
      fauxAssistantMessage(
        fauxToolCall('Agent', {
          prompt: 'child task',
          description: 'blocked child',
          name: 'blocked',
          run_in_background: false,
        }),
        { stopReason: 'toolUse' },
      ),
      (request) => {
        assert.ok(
          request.messages.some(
            (message) =>
              message.role === 'toolResult' &&
              message.isError &&
              JSON.stringify(message).includes('implement on'),
          ),
        );

        return fauxAssistantMessage('parent implemented');
      },
      fauxAssistantMessage(
        fauxToolCall('Agent', {
          prompt: 'inspect files',
          description: 'read-only child',
          subagent_type: 'Explore',
          name: 'scout',
          run_in_background: false,
        }),
        { stopReason: 'toolUse' },
      ),
      fauxAssistantMessage('scout answer'),
      (request) => {
        assert.ok(JSON.stringify(request.messages).includes('scout answer'));

        return fauxAssistantMessage('parent done');
      },
    ]);
    await f.runtime.session.prompt('Delegate write work');
    assert.equal(f.runtime.session.getLastAssistantText(), 'parent implemented');
    await f.runtime.session.prompt('Delegate read-only work');
    assert.equal(f.runtime.session.getLastAssistantText(), 'parent done');
    assert.deepEqual(f.errors, []);
  } finally {
    await f.cleanup();
  }
});

test('background reports reach real idle SDK parent and queue behind a busy turn', async () => {
  const f = await fixture();
  let release!: () => void;
  let childReady!: () => void;

  const ready = new Promise<void>((resolve) => {
    childReady = resolve;
  });

  const held = new Promise<void>((resolve) => {
    release = resolve;
  });

  try {
    let reportCount = 0;
    f.runtime.session.subscribe((event) => {
      if (
        event.type === 'message_end' &&
        event.message.role === 'custom' &&
        event.message.customType === 'durable-subagent-result'
      )
        reportCount++;
    });
    f.faux.setResponses(
      Array.from({ length: 20 }, () => async (request) => {
        const last = request.messages.findLast((message) => message.role !== 'system');
        const text = JSON.stringify(last);
        const instructions = JSON.stringify(request.messages);

        if (instructions.includes('Complete the assigned task.')) {
          childReady();
          await held;

          return fauxAssistantMessage('background actual answer');
        }

        if (text.includes('Start background'))
          return fauxAssistantMessage(
            fauxToolCall('Agent', {
              prompt: 'child task',
              description: 'background child',
              name: 'background',
            }),
            { stopReason: 'toolUse' },
          );

        if (text.includes('Busy parent')) {
          release();
          await delay(100);

          return fauxAssistantMessage('busy turn finished');
        }

        return fauxAssistantMessage('parent acknowledged');
      }),
    );
    await f.runtime.session.prompt('Start background');
    await ready;
    assert.equal(reportCount, 0);
    await f.runtime.session.prompt('Busy parent');
    await until(() => reportCount === 1 && !f.runtime.session.isStreaming);
    const messages = f.runtime.session.messages;

    const report = messages.findIndex(
      (message) => message.role === 'custom' && message.customType === 'durable-subagent-result',
    );

    const finish = messages.findIndex(
      (message) =>
        message.role === 'assistant' &&
        JSON.stringify(message.content).includes('busy turn finished'),
    );

    assert.ok(report > finish);
    await f.runtime.session.reload();
    await delay(50);
    assert.equal(reportCount, 1);
    assert.deepEqual(f.errors, []);
  } finally {
    release?.();
    await f.cleanup();
  }
});

test('real SDK Esc cancels a foreground child but not a background child; failure reports reach an idle parent', async () => {
  const f = await fixture();
  let releaseBackground!: () => void;
  let releaseFailure!: () => void;

  const backgroundGate = new Promise<void>((resolve) => {
    releaseBackground = resolve;
  });

  const failureGate = new Promise<void>((resolve) => {
    releaseFailure = resolve;
  });

  let foregroundStarted = false;
  let backgroundStarted = false;
  let failureStarted = false;
  let foregroundAborted = false;
  const reports: string[] = [];

  try {
    f.runtime.session.subscribe((event) => {
      if (
        event.type === 'message_end' &&
        event.message.role === 'custom' &&
        event.message.customType === 'durable-subagent-result'
      )
        reports.push(JSON.stringify(event.message));
    });
    f.faux.setResponses(
      Array.from({ length: 30 }, () => async (request, options) => {
        const text = JSON.stringify(
          request.messages.findLast((message) => message.role !== 'system'),
        );

        if (JSON.stringify(request.messages).includes('Complete the assigned task.')) {
          if (text.includes('fg work')) {
            foregroundStarted = true;

            try {
              await delay(60000, undefined, { signal: options?.signal });
            } catch (error) {
              foregroundAborted = true;
              throw error;
            }

            return fauxAssistantMessage('unexpected foreground answer');
          }

          if (text.includes('bad work')) {
            failureStarted = true;
            await failureGate;

            return fauxAssistantMessage('', {
              stopReason: 'error',
              errorMessage: 'expected failure',
            });
          }

          backgroundStarted = true;
          await backgroundGate;

          return fauxAssistantMessage('background survived');
        }

        if (text.includes('Launch bg'))
          return fauxAssistantMessage(
            fauxToolCall('Agent', { prompt: 'bg work', description: 'bg', name: 'bg' }),
            { stopReason: 'toolUse' },
          );

        if (text.includes('Launch fg'))
          return fauxAssistantMessage(
            fauxToolCall('Agent', {
              prompt: 'fg work',
              description: 'fg',
              name: 'fg',
              run_in_background: false,
            }),
            { stopReason: 'toolUse' },
          );

        if (text.includes('Launch failure'))
          return fauxAssistantMessage(
            fauxToolCall('Agent', { prompt: 'bad work', description: 'failure', name: 'bad' }),
            { stopReason: 'toolUse' },
          );

        return fauxAssistantMessage('acknowledged');
      }),
    );
    await f.runtime.session.prompt('Launch bg');
    await until(() => backgroundStarted);
    const foreground = f.runtime.session.prompt('Launch fg');
    await until(() => foregroundStarted);
    await f.runtime.session.abort();
    await foreground;
    assert.equal(foregroundAborted, true);
    assert.equal(reports.length, 0);
    releaseBackground();
    await until(
      () =>
        reports.some((report) => report.includes('background survived')) &&
        !f.runtime.session.isStreaming,
    );
    await f.runtime.session.prompt('Launch failure');
    await until(() => failureStarted);
    assert.equal(f.runtime.session.isStreaming, false);
    releaseFailure();
    await until(
      () => reports.some((report) => report.includes('failed')) && !f.runtime.session.isStreaming,
    );
    assert.equal(reports.length, 2);
    assert.deepEqual(f.errors, []);
  } finally {
    releaseBackground?.();
    releaseFailure?.();
    await f.cleanup();
  }
});

test('Agent tool advertises discovered role descriptions and delegation guidelines', async () => {
  const f = await fixture({
    agents: {
      auditor: '---\nname: auditor\ndescription: Audit authentication code\n---\nAudit.',
    },
  });

  try {
    const definition = f.runtime.session.getToolDefinition('Agent');

    assert.ok(definition);
    assert.match(definition.description, /- general-purpose: Research and implementation\./);
    assert.match(definition.description, /- Explore: Locate files, symbols, and references\./);
    assert.match(
      definition.description,
      /- Plan: Design implementation plans with affected files, risks, and validation\./,
    );
    assert.match(definition.description, /- auditor: Audit authentication code/);
    assert.match(
      definition.description,
      /implement changes in the parent unless the user asks for a subagent\./,
    );
    assert.equal(
      definition.promptSnippet,
      'Launch a persistent Durable child for investigation or a delegated task',
    );
    assert.deepEqual(definition.promptGuidelines, [
      'When the target is known, use a direct tool such as read, grep, or bash. Reserve Agent for open-ended search or a task that matches a role.',
      'Never delegate understanding. Do not ask a child to implement "based on the findings." Reach the conclusion yourself, then implement in the parent or hand the child the specific change with paths and line numbers.',
      "Trust but verify. A child's summary describes intent, not outcome. Before reporting delegated code as done, inspect the changed files, the worktree status, or the transcript.",
    ]);
    assert.deepEqual(f.errors, []);
  } finally {
    await f.cleanup();
  }
});

test('session start rebuilds the Agent description from the session cwd', async () => {
  const f = await fixture({
    projectAgents: {
      'project-reader':
        '---\nname: project-reader\ndescription: Read project files\ntools: [read]\n---\nRead.',
    },
  });

  try {
    const declared = f.runtime.session.state.tools.find((tool) => tool.name === 'Agent');

    assert.ok(declared);
    assert.match(declared.description, /- project-reader: Read project files/);
    assert.deepEqual(f.errors, []);
  } finally {
    await f.cleanup();
  }
});
