import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdir, open, readFile, realpath, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { promisify } from 'node:util';
import { Type } from 'typebox';
import { Check } from 'typebox/value';
import type { ResolvedConfiguration, Worktree } from './state.ts';

const ownershipRecord = Type.Object({
  repository: Type.String(),
  path: Type.String(),
  branch: Type.String(),
  baseCommit: Type.String(),
  owner: Type.String(),
});

const execute = promisify(execFile);

async function git(cwd: string, ...args: string[]) {
  const { stdout } = await execute('git', ['-C', cwd, ...args], {
    maxBuffer: 4 * 1024 * 1024,
    timeout: 30000,
  });

  return stdout.trimEnd();
}

function decode(content: string): Worktree {
  const value: unknown = JSON.parse(content);

  if (!Check(ownershipRecord, value)) throw new Error('Invalid worktree ownership record');

  return {
    repository: value.repository,
    path: value.path,
    branch: value.branch,
    baseCommit: value.baseCommit,
    owner: value.owner,
  };
}

async function exists(path: string) {
  try {
    await stat(path);

    return true;
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') return false;
    throw error;
  }
}

export function worktreeServices(directory: string, parentSession: string) {
  const owned = join(directory, 'worktrees');
  const intents = join(directory, 'worktree-intents');

  const token = (agentId: string) =>
    createHash('sha256').update(`${parentSession}\0${agentId}`).digest('hex');

  const intentPath = (owner: string) => join(intents, `${owner}.json`);

  const records = async (repository: string) => {
    const output = await git(repository, 'worktree', 'list', '--porcelain', '-z');

    return output
      .split('\0\0')
      .filter(Boolean)
      .map((record) => {
        const fields = record.split('\0');

        return {
          path: fields.find((field) => field.startsWith('worktree '))?.slice(9),
          branch: fields.find((field) => field.startsWith('branch '))?.slice(7),
        };
      });
  };

  const verifyRecord = async (worktree: Worktree) => {
    if (!/^[a-f0-9]{64}$/.test(worktree.owner)) throw new Error('Invalid worktree owner token');
    const saved = decode(await readFile(intentPath(worktree.owner), 'utf8'));

    if (
      JSON.stringify(saved) !== JSON.stringify(worktree) ||
      worktree.path !== join(owned, worktree.owner) ||
      worktree.branch !== `durable/${worktree.owner}`
    )
      throw new Error('Worktree ownership mismatch');
  };

  const verify = async (worktree: Worktree) => {
    await verifyRecord(worktree);

    if (!(await exists(worktree.path)))
      throw new Error(
        `Retained worktree is missing: ${worktree.path}. Refusing parent cwd fallback.`,
      );

    const entry = (await records(worktree.repository)).find(
      (entry) => entry.path === worktree.path,
    );

    if (!entry || entry.branch !== `refs/heads/${worktree.branch}`)
      throw new Error(`Worktree identity mismatch: ${worktree.path}`);

    const common = await realpath(
      await git(worktree.path, 'rev-parse', '--path-format=absolute', '--git-common-dir'),
    );

    const expected = await realpath(
      await git(worktree.repository, 'rev-parse', '--path-format=absolute', '--git-common-dir'),
    );

    if (
      common !== expected ||
      (await git(worktree.path, 'symbolic-ref', '--short', 'HEAD')) !== worktree.branch
    )
      throw new Error('Worktree repository or branch mismatch');
    await git(worktree.path, 'merge-base', '--is-ancestor', worktree.baseCommit, 'HEAD');
  };

  const prepare = async (
    agentId: string,
    configuration: ResolvedConfiguration,
  ): Promise<Worktree> => {
    await mkdir(owned, { recursive: true, mode: 0o700 });
    await mkdir(intents, { recursive: true, mode: 0o700 });
    const owner = token(agentId);
    const intent = intentPath(owner);
    let worktree: Worktree;

    if (await exists(intent)) {
      worktree = decode(await readFile(intent, 'utf8'));
      await verifyRecord(worktree);
    } else {
      const repository = await realpath(
        await git(configuration.project, 'rev-parse', '--show-toplevel'),
      );

      const baseCommit = await git(configuration.project, 'rev-parse', 'HEAD^{commit}');
      worktree = {
        repository,
        path: join(owned, owner),
        branch: `durable/${owner}`,
        baseCommit,
        owner,
      };

      const refs = await git(
        repository,
        'for-each-ref',
        '--format=%(refname)',
        `refs/heads/${worktree.branch}`,
      );

      if (refs || (await exists(worktree.path)))
        throw new Error(
          'Refusing to adopt a preexisting worktree or branch without an ownership intent',
        );
      const file = await open(intent, 'wx', 0o600);

      try {
        await file.writeFile(JSON.stringify(worktree));
        await file.sync();
      } finally {
        await file.close();
      }
    }

    const created = `${intent}.created`;

    const recordCreation = async () => {
      if (!(await exists(created))) {
        const receipt = await open(created, 'wx', 0o600);

        try {
          await receipt.writeFile(worktree.baseCommit);
          await receipt.sync();
        } finally {
          await receipt.close();
        }
      }
    };

    const entries = await records(worktree.repository);

    if (entries.some((entry) => entry.path === worktree.path)) {
      await verify(worktree);
      await recordCreation();

      return worktree;
    }

    if (await exists(created))
      throw new Error(`Retained worktree is missing: ${worktree.path}. Refusing to recreate it.`);

    if (await exists(worktree.path))
      throw new Error(`Owned worktree path exists but Git does not recognize it: ${worktree.path}`);

    const refs = await git(
      worktree.repository,
      'for-each-ref',
      '--format=%(objectname)',
      `refs/heads/${worktree.branch}`,
    );

    if (refs) {
      if (
        refs !== worktree.baseCommit ||
        entries.some((entry) => entry.branch === `refs/heads/${worktree.branch}`)
      )
        throw new Error('Interrupted worktree creation has an unexpected branch identity');
      await git(worktree.repository, 'worktree', 'add', worktree.path, worktree.branch);
    } else {
      await git(
        worktree.repository,
        'worktree',
        'add',
        '-b',
        worktree.branch,
        worktree.path,
        worktree.baseCommit,
      );
    }

    await verify(worktree);
    await recordCreation();

    return worktree;
  };

  const status = async (worktree: Worktree) => {
    await verify(worktree);

    return git(worktree.path, 'status', '--short', '--untracked-files=all');
  };

  const cleanup = async (worktree: Worktree) => {
    await verify(worktree);

    const dirty = await git(
      worktree.path,
      'status',
      '--porcelain',
      '--untracked-files=all',
      '--ignored=matching',
    );

    if (dirty) throw new Error(`Refusing cleanup of dirty worktree ${worktree.path}:\n${dirty}`);
    await git(worktree.repository, 'worktree', 'remove', worktree.path);

    return `Removed ${worktree.path}. Branch ${worktree.branch} and ownership intent retained. This agent cannot continue until its retained checkout is restored explicitly.`;
  };

  return { prepare, verify, status, cleanup };
}
