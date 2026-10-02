import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdtemp, mkdir, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createModels } from '@earendil-works/pi-ai';
import {
  fauxProvider,
  fauxAssistantMessage,
  fauxToolCall,
} from '@earendil-works/pi-ai/providers/faux';
import { openRuntime } from '../src/runtime.ts';
import { worktreeServices } from '../src/worktrees.ts';
import type { ResolvedConfiguration } from '../src/state.ts';

const execute = promisify(execFile);

const git = async (cwd: string, ...args: string[]) =>
  (await execute('git', ['-C', cwd, ...args])).stdout.trim();

async function fixture() {
  const directory = await mkdtemp(join(tmpdir(), 'worktrees-'));
  const project = join(directory, 'repo');
  await mkdir(project);
  await git(project, 'init', '-b', 'main');
  await writeFile(join(project, 'tracked.txt'), 'committed');
  await writeFile(join(project, '.gitignore'), 'ignored.txt\n');
  await git(project, 'add', '.');
  await git(
    project,
    '-c',
    'user.name=Test',
    '-c',
    'user.email=test@example.invalid',
    'commit',
    '-m',
    'initial',
  );
  const baseCommit = await git(project, 'rev-parse', 'HEAD');
  await writeFile(join(project, 'tracked.txt'), 'parent dirty');
  const state = join(directory, 'state');
  const services = worktreeServices(state, 'parent');

  const configuration: ResolvedConfiguration = {
    role: 'general-purpose',
    model: { provider: 'faux', modelId: 'faux-1' },
    thinking: 'off',
    instructions: 'Parent instructions',
    tools: ['read', 'write', 'bash'],
    cwd: project,
    project,
    isolation: 'worktree',
    history: '',
  };

  return { directory, project, state, services, configuration, baseCommit };
}

test('worktree uses explicit base without copying parent dirt; reconciles creation window and protects dirty, ignored and wrong-owned targets', async () => {
  const f = await fixture();

  try {
    const worktree = await f.services.prepare('agent', f.configuration);
    assert.equal(worktree.baseCommit, f.baseCommit);
    assert.equal(await readFile(join(worktree.path, 'tracked.txt'), 'utf8'), 'committed');
    assert.deepEqual(
      await worktreeServices(f.state, 'parent').prepare('agent', f.configuration),
      worktree,
    );
    assert.equal(
      (await git(f.project, 'worktree', 'list', '--porcelain')).split('worktree ').length,
      3,
    );
    await rm(join(f.state, 'worktree-intents', `${worktree.owner}.json.created`));
    assert.deepEqual(await f.services.prepare('agent', f.configuration), worktree);
    await writeFile(join(worktree.path, 'untracked.txt'), 'keep');
    await assert.rejects(f.services.cleanup(worktree), /dirty/);
    await rm(join(worktree.path, 'untracked.txt'));
    await writeFile(join(worktree.path, 'ignored.txt'), 'keep ignored');
    await assert.rejects(f.services.cleanup(worktree), /dirty/);
    await rm(join(worktree.path, 'ignored.txt'));
    await assert.rejects(
      f.services.cleanup({ ...worktree, path: f.project }),
      /ownership mismatch/,
    );
    await f.services.cleanup(worktree);
    await assert.rejects(f.services.verify(worktree), /missing/);
    await assert.rejects(f.services.prepare('agent', f.configuration), /missing/);
    assert.equal(await readFile(join(f.project, 'tracked.txt'), 'utf8'), 'parent dirty');
  } finally {
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('ownership records reject malformed JSON values and retain the recorded checkout', async () => {
  const f = await fixture();

  try {
    const worktree = await f.services.prepare('agent', f.configuration);
    const intent = join(f.state, 'worktree-intents', `${worktree.owner}.json`);
    const before = await readFile(intent, 'utf8');

    for (const value of [
      null,
      [],
      { ...worktree, owner: 42 },
      { ...worktree, path: null },
      { repository: f.project },
    ]) {
      await writeFile(intent, JSON.stringify(value));
      await assert.rejects(f.services.verify(worktree), /Invalid worktree ownership record/);
      await assert.rejects(
        f.services.prepare('agent', f.configuration),
        /Invalid worktree ownership record/,
      );
      assert.equal(await readFile(join(worktree.path, 'tracked.txt'), 'utf8'), 'committed');
    }

    await writeFile(intent, before);
    await f.services.verify(worktree);
    await f.services.cleanup(worktree);
  } finally {
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('runtime records worktree cwd and change status, recovers it, and missing checkout produces failure rather than parent fallback', async () => {
  const f = await fixture();
  const faux = fauxProvider();
  const models = createModels();
  models.setProvider(faux.provider);
  const options = { directory: f.state, parentSession: 'parent', models, isolation: f.services };
  let runtime = await openRuntime(options);

  try {
    faux.setResponses([
      fauxAssistantMessage(fauxToolCall('write', { path: 'child.txt', content: 'child change' }), {
        stopReason: 'toolUse',
      }),
      fauxAssistantMessage('finished child'),
    ]);

    const task = await runtime.start({
      requestId: 'isolated',
      name: 'isolated',
      description: 'isolated',
      message: 'write',
      configuration: f.configuration,
      background: true,
    });

    assert.equal((await runtime.wait(task)).status, 'completed');
    const agent = await runtime.get('isolated');
    assert.ok(agent.worktree);
    assert.equal(agent.configuration.cwd, agent.worktree.path);
    assert.ok(agent.changedFiles?.includes('child.txt'));
    const report = Object.values((await runtime.snapshot())!.outbox)[0]!;
    assert.deepEqual(report.worktree, agent.worktree);
    assert.ok(report.changedFiles?.includes('child.txt'));
    await assert.rejects(readFile(join(f.project, 'child.txt')), /ENOENT/);
    await runtime.close();
    runtime = await openRuntime(options);
    assert.deepEqual((await runtime.get('isolated')).worktree, agent.worktree);
    await rm(agent.worktree.path, { recursive: true, force: true });

    const continuation = await runtime.send({
      id: 'isolated',
      requestId: 'missing',
      message: 'continue',
      followUp: true,
    });

    const failure = await runtime.wait(continuation);
    assert.equal(failure.status, 'failed');
    assert.match(failure.text, /missing/);
    assert.equal(await readFile(join(f.project, 'tracked.txt'), 'utf8'), 'parent dirty');
  } finally {
    await runtime.close();
    await rm(f.directory, { recursive: true, force: true });
  }
});

test('concurrent same-name admission rejects before creating an orphaned branch or worktree', async () => {
  const f = await fixture();
  const faux = fauxProvider();
  const models = createModels();
  models.setProvider(faux.provider);

  const runtime = await openRuntime({
    directory: f.state,
    parentSession: 'parent',
    models,
    isolation: f.services,
  });

  try {
    faux.setResponses([fauxAssistantMessage('first'), fauxAssistantMessage('third')]);

    const request = {
      name: 'shared',
      description: 'isolated',
      message: 'inspect',
      configuration: f.configuration,
      background: true,
    };

    const outcomes = await Promise.allSettled([
      runtime.start({ ...request, requestId: 'first' }),
      runtime.start({ ...request, requestId: 'second' }),
    ]);

    const first = outcomes[0];
    assert.ok(first && first.status === 'fulfilled');
    const second = outcomes[1];
    assert.ok(second && second.status === 'rejected');
    assert.match(String(second.reason), /already exists/);
    await runtime.wait(first.value);
    assert.equal(
      (await git(f.project, 'worktree', 'list', '--porcelain')).split('worktree ').length,
      3,
    );
    assert.equal(
      (await git(f.project, 'for-each-ref', '--format=%(refname)', 'refs/heads/durable')).split(
        '\n',
      ).length,
      1,
    );
    assert.equal((await runtime.snapshot())!.requests.second, undefined);
    await runtime.wait(await runtime.start({ ...request, name: 'third', requestId: 'third' }));
    assert.equal(Object.keys((await runtime.snapshot())!.agents).length, 2);
    assert.equal(await readFile(join(f.project, 'tracked.txt'), 'utf8'), 'parent dirty');
  } finally {
    await runtime.close();
    await rm(f.directory, { recursive: true, force: true });
  }
});
