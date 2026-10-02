import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, mkdir, writeFile, readFile, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createModels } from '@earendil-works/pi-ai';
import {
  fauxProvider,
  fauxAssistantMessage,
  fauxToolCall,
} from '@earendil-works/pi-ai/providers/faux';
import { applies, loadInstructions, resolveConfiguration } from '../src/configuration.ts';
import { openRuntime, context } from '../src/runtime.ts';

async function fixture() {
  const directory = await mkdtemp(join(tmpdir(), 'configuration-'));
  const project = join(directory, 'project');
  const agentDir = join(directory, 'user');
  await mkdir(project);
  await mkdir(join(agentDir, 'agents'), { recursive: true });
  const faux = fauxProvider();

  const parentModel = {
    ...faux.getModel(),
    id: 'gpt-parent',
    reasoning: true,
    thinkingLevelMap: { max: 'max' },
  };

  const policy = { ...parentModel, id: 'gpt-6-luna' };

  const registry = {
    getAll: () => [parentModel, policy, faux.getModel()],
    getApiKeyAndHeaders: async () => ({ ok: true as const }),
    getAvailableOfType: async () => [parentModel, policy, faux.getModel()],
  };

  const input = {
    project,
    agentDir,
    parentModel,
    parentThinking: 'high' as const,
    registry,
    role: 'general-purpose',
  };

  return { directory, project, agentDir, faux, registry, input };
}

test('project role overrides user role; request overrides frontmatter; GPT policy, unavailable models and credentials fail clearly', async () => {
  const f = await fixture();

  try {
    const config = await resolveConfiguration(f.input);
    assert.equal(config.model.modelId, 'gpt-6-luna');
    assert.equal(config.thinking, 'max');
    await writeFile(
      join(f.agentDir, 'agents', 'custom.md'),
      '---\nname: custom\nmodel: faux/faux-1\nthinking: off\ntools: read\n---\nUser role',
    );
    await mkdir(join(f.project, '.pi', 'agents'), { recursive: true });
    await writeFile(
      join(f.project, '.pi', 'agents', 'custom.md'),
      '---\nname: custom\nmodel: faux/faux-1\nthinking: off\ntools: [read, bash]\n---\nProject role',
    );
    const custom = await resolveConfiguration({ ...f.input, role: 'custom' });
    assert.ok(custom.instructions.startsWith('Project role'));
    assert.deepEqual(custom.tools, ['read', 'bash']);
    assert.equal(custom.model.modelId, 'faux-1');

    const requested = await resolveConfiguration({
      ...f.input,
      role: 'custom',
      model: 'gpt-6-luna',
      thinking: 'max',
    });

    assert.equal(requested.thinking, 'max');
    assert.equal(requested.model.modelId, 'gpt-6-luna');
    await assert.rejects(resolveConfiguration({ ...f.input, model: 'missing' }), /unavailable/);
    await assert.rejects(
      resolveConfiguration({
        ...f.input,
        registry: { ...f.registry, getAvailableOfType: async () => [] },
      }),
      /not available/,
    );
    await assert.rejects(
      resolveConfiguration({
        ...f.input,
        registry: {
          ...f.registry,
          getApiKeyAndHeaders: async () => ({ ok: false, error: 'no credentials' }),
        },
      }),
      /credentials/,
    );
    await writeFile(
      join(f.project, '.pi', 'agents', 'Explore.md'),
      '---\ntools: [read, write]\n---\nExplore',
    );
    await assert.rejects(
      resolveConfiguration({ ...f.input, role: 'Explore' }),
      /cannot have write/,
    );
  } finally {
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('role and scoped-rule schemas reject malformed values without coercion', async () => {
  const f = await fixture();

  try {
    const role = join(f.agentDir, 'agents', 'invalid.md');

    for (const fields of [
      'name: 42',
      'description: false',
      'model: 42',
      'thinking: [max]',
      'tools: [read, 42]',
    ]) {
      await writeFile(role, `---\n${fields}\n---\nInvalid role`);
      await assert.rejects(resolveConfiguration(f.input), /Invalid frontmatter/);
    }

    await writeFile(role, '---\nname: custom\ntools: read, bash\n---\nCustom role');
    assert.deepEqual((await resolveConfiguration({ ...f.input, role: 'custom' })).tools, [
      'read',
      'bash',
    ]);
    await mkdir(join(f.project, '.claude', 'rules'), { recursive: true });
    const rule = join(f.project, '.claude', 'rules', 'paths.md');

    for (const paths of ['42', '["src/**/*.ts", false]', 'null']) {
      await writeFile(rule, `---\npaths: ${paths}\n---\nInvalid scoped rule`);
      assert.throws(
        () => loadInstructions(f.project, f.agentDir),
        /paths must be a string or string array/,
      );
    }

    await writeFile(rule, '---\npaths: "src/a.ts,src/b.ts"\n---\nLiteral path pattern');
    assert.deepEqual(
      loadInstructions(f.project, f.agentDir).find((entry) => entry.path === rule)?.paths,
      ['src/a.ts,src/b.ts'],
    );
  } finally {
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('instructions load independently of history, realpath deduplication, override precedence and supported path rules', async () => {
  const f = await fixture();

  try {
    await writeFile(join(f.agentDir, 'AGENTS.md'), 'Global instructions');
    await writeFile(join(f.project, 'AGENTS.md'), 'Repository instructions');
    await symlink(join(f.project, 'AGENTS.md'), join(f.project, 'CLAUDE.md'));
    await mkdir(join(f.project, '.claude', 'rules'), { recursive: true });
    await writeFile(join(f.project, '.claude', 'CLAUDE.md'), 'Claude instructions');
    await writeFile(
      join(f.project, '.claude', 'rules', 'ts.md'),
      '---\npaths: ["src/**/*.{ts,tsx}"]\n---\nTypeScript rule',
    );
    const rules = loadInstructions(f.project, f.agentDir);
    assert.equal(rules.filter((rule) => rule.content === 'Repository instructions').length, 1);
    const scoped = rules.find((rule) => rule.paths.length)!;
    assert.ok(applies(scoped, join(f.project, 'src', 'a.ts')));
    assert.ok(applies(scoped, join(f.project, 'src', 'nested', 'a.tsx')));
    assert.ok(!applies(scoped, join(f.project, 'test', 'a.ts')));
    assert.ok(!applies(scoped, join(f.directory, 'src', 'a.ts')));
    const config = await resolveConfiguration(f.input);
    assert.equal(config.history, '');
    assert.ok(config.instructions.includes('Global instructions'));
    assert.ok(config.instructions.includes('Claude instructions'));
    assert.ok(config.instructions.includes('apply only to src/'));
    await writeFile(join(f.project, 'AGENTS.override.md'), 'Override');
    assert.ok(
      !loadInstructions(f.project, f.agentDir).some(
        (rule) => rule.content === 'Repository instructions',
      ),
    );
  } finally {
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('coding tools use recorded cwd, perform edits, bound output, and enforce Plan allowlist even for invented tool calls', async () => {
  const f = await fixture();
  const models = createModels();
  models.setProvider(f.faux.provider);

  const runtime = await openRuntime({
    directory: join(f.directory, 'state'),
    parentSession: 'tools',
    models,
  });

  try {
    const config = await resolveConfiguration({
      ...f.input,
      model: 'faux/faux-1',
      thinking: 'off',
    });

    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('write', { path: 'file.txt', content: 'one two' }), {
        stopReason: 'toolUse',
      }),
      fauxAssistantMessage(
        fauxToolCall('edit', {
          path: 'file.txt',
          edits: [
            { oldText: 'one', newText: 'three' },
            { oldText: 'two', newText: 'four' },
          ],
        }),
        { stopReason: 'toolUse' },
      ),
      fauxAssistantMessage(fauxToolCall('read', { path: 'file.txt' }), { stopReason: 'toolUse' }),
      (request) => {
        assert.ok(JSON.stringify(request.messages).includes('three four'));

        return fauxAssistantMessage('edited');
      },
    ]);

    const task = await runtime.start({
      requestId: 'tools',
      name: 'tools',
      description: 'tools',
      message: 'edit',
      background: false,
      configuration: config,
    });

    assert.equal((await runtime.wait(task)).text, 'edited');
    assert.equal(await readFile(join(f.project, 'file.txt'), 'utf8'), 'three four');

    const plan = await resolveConfiguration({
      ...f.input,
      role: 'Plan',
      model: 'faux/faux-1',
      thinking: 'off',
    });

    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('write', { path: 'file.txt', content: 'bad' }), {
        stopReason: 'toolUse',
      }),
      (request) => {
        assert.ok(
          request.messages.some((message) => message.role === 'toolResult' && message.isError),
        );

        return fauxAssistantMessage('blocked');
      },
    ]);
    await runtime.wait(
      await runtime.start({
        requestId: 'plan',
        name: 'plan',
        description: 'plan',
        message: 'plan',
        background: false,
        configuration: plan,
      }),
    );
    assert.equal(await readFile(join(f.project, 'file.txt'), 'utf8'), 'three four');
    await writeFile(join(f.project, 'large.txt'), 'line\n'.repeat(3000));
    f.faux.setResponses([
      fauxAssistantMessage(fauxToolCall('read', { path: 'large.txt' }), { stopReason: 'toolUse' }),
      (request) => {
        assert.ok(JSON.stringify(request.messages).length < 25000);

        return fauxAssistantMessage('bounded');
      },
    ]);

    const follow = await runtime.send({
      id: 'tools',
      requestId: 'read-large',
      message: 'read',
      followUp: true,
    });

    assert.equal((await runtime.wait(follow)).text, 'bounded');
    assert.ok(
      (await (await runtime.conversation(await runtime.get('tools'))).agent(context)).tools.every(
        (tool) => ['read', 'write', 'edit', 'bash'].includes(tool.name),
      ),
    );
  } finally {
    await runtime.close();
    await rm(f.directory, { recursive: true, force: true });
  }
});
