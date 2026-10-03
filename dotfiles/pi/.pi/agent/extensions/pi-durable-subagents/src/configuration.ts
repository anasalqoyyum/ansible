import { existsSync, readFileSync, readdirSync, realpathSync } from 'node:fs';
import { basename, dirname, join, matchesGlob, relative, resolve } from 'node:path';
import { getAgentDir, parseFrontmatter, type ModelRegistry } from '@earendil-works/pi-coding-agent';
import { getSupportedThinkingLevels } from '@earendil-works/pi-ai';
import type { Api, Model, ModelThinkingLevel } from '@earendil-works/pi-ai';
import type { ResolvedConfiguration } from './state.ts';
import { Type } from 'typebox';
import { Check } from 'typebox/value';

const stringList = Type.Union([Type.String(), Type.Array(Type.String())]);

const roleFrontmatter = Type.Object({
  name: Type.Optional(Type.String()),
  description: Type.Optional(Type.String()),
  model: Type.Optional(Type.String()),
  thinking: Type.Optional(Type.String()),
  tools: Type.Optional(stringList),
  approved: Type.Optional(Type.Boolean()),
});

const ruleFrontmatter = Type.Object({ paths: Type.Optional(stringList) });

const availableTools = ['read', 'write', 'edit', 'bash'];

const thoughts = ['off', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max'] as const;

export function thinking(value: string): ModelThinkingLevel {
  const found = thoughts.find((level) => level === value);

  if (!found) throw new Error(`Unsupported thinking level: ${String(value)}`);

  return found;
}

function strings(value: string | string[]): string[] {
  if (Array.isArray(value)) return value;

  return value
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean);
}

export type RoleSource = 'builtin' | 'user' | 'project';

export type Role = {
  name: string;
  description: string;
  instructions: string;
  tools: string[];
  source: RoleSource;
  approved: boolean;
  model?: string;
  thinking?: ModelThinkingLevel;
  error?: string;
};

const defaults: Role[] = [
  {
    name: 'general-purpose',
    description: 'Research and implementation. Write-capable; calls require authorization.',
    instructions:
      'Complete the assigned task. Make only authorized changes. Report what changed, checks run, and limitations. Do not delegate or change Git state without explicit authorization.',
    tools: availableTools,
    source: 'builtin',
    approved: false,
  },
  {
    name: 'Explore',
    description:
      'Locate files, symbols, and references. Read-only; not for code review or open-ended analysis.',
    instructions:
      'Inspect the repository to locate files, symbols, and references. Do not edit files or change Git state. Use bash only for read-only inspection. Report precise paths and evidence.',
    tools: ['read', 'bash'],
    source: 'builtin',
    approved: false,
  },
  {
    name: 'Plan',
    description:
      'Design implementation plans with affected files, risks, and validation. Read-only.',
    instructions:
      'Inspect the repository and propose an implementation plan with affected files, risks, and validation. Do not implement changes or change Git state. Use bash only for read-only inspection.',
    tools: ['read', 'bash'],
    source: 'builtin',
    approved: false,
  },
];

export function loadRoles(project: string, agentDir = getAgentDir()): Map<string, Role> {
  const roles = new Map(defaults.map((role) => [role.name, role]));

  const directories: { path: string; source: RoleSource }[] = [
    { path: join(agentDir, 'agents'), source: 'user' },
    { path: join(project, '.pi', 'agents'), source: 'project' },
  ];

  for (const directory of directories) {
    if (!existsSync(directory.path)) continue;

    for (const file of readdirSync(directory.path)
      .filter((file) => file.endsWith('.md'))
      .sort()) {
      const path = join(directory.path, file);
      const { frontmatter, body } = parseFrontmatter(readFileSync(path, 'utf8'));

      if (!Check(roleFrontmatter, frontmatter)) throw new Error(`Invalid frontmatter in ${path}`);

      const extra = Object.keys(frontmatter).filter(
        (key) => !['name', 'description', 'model', 'thinking', 'tools', 'approved'].includes(key),
      );

      const name = frontmatter.name ?? basename(file, '.md');

      const role: Role = {
        name,
        description: frontmatter.description ?? name,
        instructions: body,
        tools: frontmatter.tools === undefined ? availableTools : strings(frontmatter.tools),
        source: directory.source,
        approved: frontmatter.approved === true,
      };

      if (extra.length) role.error = `Unsupported frontmatter in ${path}: ${extra.join(', ')}`;

      if (frontmatter.model !== undefined) role.model = frontmatter.model;

      if (frontmatter.thinking !== undefined) role.thinking = thinking(frontmatter.thinking);
      roles.set(name, role);
    }
  }

  return roles;
}

export type Rule = { path: string; base: string; paths: string[]; content: string };

export function applies(rule: Rule, target: string) {
  const path = relative(rule.base, resolve(target)).replaceAll('\\', '/');

  return (
    !path.startsWith('../') &&
    (rule.paths.length === 0 || rule.paths.some((pattern) => matchesGlob(path, pattern)))
  );
}

function markdownFiles(directory: string): string[] {
  if (!existsSync(directory)) return [];

  return readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const path = join(directory, entry.name);

      return entry.isDirectory() ? markdownFiles(path) : entry.name.endsWith('.md') ? [path] : [];
    })
    .sort();
}

export function loadInstructions(project: string, agentDir = getAgentDir()): Rule[] {
  const rules: Rule[] = [];
  const seen = new Set<string>();

  const add = (path: string, base: string, scoped = false) => {
    if (!existsSync(path)) return;
    const physical = realpathSync(path);

    if (seen.has(physical)) return;
    seen.add(physical);
    const content = readFileSync(path, 'utf8');

    if (!scoped) {
      rules.push({ path, base, paths: [], content });

      return;
    }

    const parsed = parseFrontmatter(content);
    const unsupported = Object.keys(parsed.frontmatter).filter((key) => key !== 'paths');

    if (unsupported.length)
      throw new Error(`Unsupported rule fields in ${path}: ${unsupported.join(', ')}`);

    if (!Check(ruleFrontmatter, parsed.frontmatter))
      throw new Error(`paths must be a string or string array in ${path}`);

    const paths =
      parsed.frontmatter.paths === undefined
        ? []
        : Array.isArray(parsed.frontmatter.paths)
          ? parsed.frontmatter.paths
          : [parsed.frontmatter.paths];

    rules.push({ path, base, paths, content: parsed.body });
  };

  const addDirectory = (directory: string) => {
    const override = join(directory, 'AGENTS.override.md');

    if (existsSync(override)) add(override, directory);
    else {
      add(join(directory, 'AGENTS.md'), directory);
      add(join(directory, 'CLAUDE.md'), directory);
    }

    add(join(directory, '.claude', 'CLAUDE.md'), directory);

    for (const path of markdownFiles(join(directory, '.claude', 'rules')))
      add(path, directory, true);
  };

  addDirectory(agentDir);
  const ancestors: string[] = [];

  for (let path = resolve(project); ; path = dirname(path)) {
    ancestors.unshift(path);

    if (path === dirname(path)) break;
  }

  for (const directory of ancestors) addDirectory(directory);

  return rules;
}

export async function resolveConfiguration(input: {
  project: string;
  role: string;
  parentModel: Model<Api>;
  parentThinking: ModelThinkingLevel;
  registry: Pick<ModelRegistry, 'getAll' | 'getApiKeyAndHeaders'> & {
    getAvailableOfType(type: 'chat', provider?: string): Promise<readonly Model<Api>[]>;
  };
  agentDir?: string;
  model?: string;
  thinking?: string;
  history?: string;
  isolation?: 'off' | 'worktree';
}): Promise<ResolvedConfiguration> {
  const roles = loadRoles(input.project, input.agentDir);
  const role = roles.get(input.role);

  if (!role)
    throw new Error(`Unknown agent type ${input.role}. Available: ${[...roles.keys()].join(', ')}`);

  if (role.error) throw new Error(role.error);
  const unknown = role.tools.filter((tool) => !availableTools.includes(tool));

  if (unknown.length)
    throw new Error(
      `Unsupported child tools: ${unknown.join(', ')}. MCP and SDK extension tools are not supported.`,
    );

  if (
    ['explore', 'plan'].includes(role.name.toLowerCase()) &&
    role.tools.some((tool) => tool === 'edit' || tool === 'write')
  )
    throw new Error(`${role.name} cannot have write or edit tools`);
  const gptParent = input.parentModel.id.startsWith('gpt-');

  const requested =
    input.model ??
    role.model ??
    (gptParent ? 'gpt-6-luna' : `${input.parentModel.provider}/${input.parentModel.id}`);

  const matches = input.registry
    .getAll()
    .filter((model) => requested === model.id || requested === `${model.provider}/${model.id}`);

  const model =
    matches.find((model) => model.provider === input.parentModel.provider) ??
    (matches.length === 1 ? matches[0] : undefined);

  if (!model)
    throw new Error(
      `Explicit or policy model unavailable or ambiguous: ${requested}. Use provider/modelId.`,
    );

  const level =
    input.thinking === undefined
      ? (role.thinking ?? (gptParent ? 'max' : input.parentThinking))
      : thinking(input.thinking);

  if (!getSupportedThinkingLevels(model).includes(level))
    throw new Error(`${model.provider}/${model.id} does not support thinking ${level}`);
  const auth = await input.registry.getApiKeyAndHeaders(model);

  if (!auth.ok) throw new Error(`Model credentials unavailable: ${auth.error}`);
  const available = await input.registry.getAvailableOfType('chat', model.provider);

  if (!available.some((candidate) => candidate.id === model.id))
    throw new Error(`Selected model is not available for these credentials: ${requested}`);
  const rules = loadInstructions(input.project, input.agentDir);

  const scope =
    'Scoped repository rules below apply only when working on matching paths, not to other files. Patterns describe paths in the parent project. In a worktree, match the corresponding repository-relative paths in the child checkout.';

  const instructions = [
    role.instructions,
    scope,
    ...rules.map(
      (rule) =>
        `Instructions from ${rule.path}${rule.paths.length ? `, apply only to ${rule.paths.join(', ')} relative to ${rule.base}` : ''}:\n${rule.content}`,
    ),
  ].join('\n\n');

  return {
    role: role.name,
    model: { provider: model.provider, modelId: model.id },
    thinking: level,
    instructions,
    tools: role.tools,
    cwd: resolve(input.project),
    project: resolve(input.project),
    history: input.history ?? '',
    isolation: input.isolation ?? 'off',
  };
}
