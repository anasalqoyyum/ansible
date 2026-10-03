import { join } from 'node:path';
import { Type } from 'typebox';
import { Check } from 'typebox/value';
import {
  getAgentDir,
  type ExtensionAPI,
  type ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import { LiveDoc } from '@earendil-works/pi-durable';
import { modelsFromPi } from './models.ts';
import { context, openRuntime, type Runtime } from './runtime.ts';
import { loadRoles, resolveConfiguration } from './configuration.ts';
import { policyEntrySchema, policyEntryType, requiresWriteAuthorization } from './policy.ts';
import { reportDelivery } from './reports.ts';
import { worktreeServices } from './worktrees.ts';
import { createFleetUI, type FleetUI } from './ui.ts';
import type { AgentRecord, Result } from './state.ts';

const reportDetails = Type.Object({ reportId: Type.String() });

const agentCall = Type.Object({
  subagent_type: Type.Optional(Type.String()),
  resume: Type.Optional(Type.String()),
  description: Type.Optional(Type.String()),
});

function reportIds(ctx: ExtensionContext): Set<string> {
  const ids = new Set<string>();

  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== 'custom_message' || entry.customType !== 'durable-subagent-result') continue;
    const details: unknown = entry.details;

    if (Check(reportDetails, details)) ids.add(details.reportId);
  }

  return ids;
}

function response(result: Result, agent: AgentRecord) {
  const worktree = agent.worktree
    ? `\nWorktree retained: ${agent.worktree.path}\nBranch: ${agent.worktree.branch}\nBase: ${agent.worktree.baseCommit}\nChanged files:\n${agent.changedFiles || 'none'}`
    : '';

  return {
    content: [{ type: 'text' as const, text: result.text + worktree }],
    details: {
      agent_id: agent.id,
      name: agent.name,
      conversation_id: agent.conversationId,
      status: result.status,
      worktree: agent.worktree,
    },
    isError: result.status !== 'completed',
  };
}

export default function durableSubagents(pi: ExtensionAPI) {
  let runtime: Runtime | undefined;
  let ui: FleetUI | undefined;
  let delivery: ReturnType<typeof reportDelivery> | undefined;
  let unsubscribe: (() => void) | undefined;
  let initializing: Promise<void> | undefined;
  let allowWriteChildren = false;

  const failures = (message: string, ctx: ExtensionContext) => ctx.ui.notify(message, 'error');

  const close = async () => {
    await initializing;
    unsubscribe?.();
    unsubscribe = undefined;

    try {
      await ui?.dispose();
      ui = undefined;
      await delivery?.close();
      delivery = undefined;
    } finally {
      await runtime?.close();
      runtime = undefined;
    }
  };

  const initialize = async (ctx: ExtensionContext) => {
    if (runtime) return;

    if (initializing) return initializing;
    initializing = (async () => {
      const directory = join(getAgentDir(), 'durable-subagents');
      runtime = await openRuntime({
        directory,
        parentSession: ctx.sessionManager.getSessionId(),
        models: modelsFromPi(ctx.modelRegistry),
        isolation: worktreeServices(directory, ctx.sessionManager.getSessionId()),
      });
      const active = runtime;
      delivery = reportDelivery(active, {
        seen: () => reportIds(ctx),
        send: (report, name) => {
          const worktree = report.worktree
            ? `\nWorktree retained: ${report.worktree.path}\nBranch: ${report.worktree.branch}\nBase: ${report.worktree.baseCommit}\nChanged files:\n${report.changedFiles?.slice(0, 1000) || 'none'}`
            : '';

          pi.sendMessage(
            {
              customType: 'durable-subagent-result',
              content: `[subagent ${name} ${report.result.status}; report ${report.id}]\n${report.result.text.slice(0, 4000)}${report.result.text.length > 4000 ? '\nFull answer is available with get_subagent_result or /agents.' : ''}${worktree}`,
              display: true,
              details: {
                reportId: report.id,
                agentId: report.agentId,
                status: report.result.status,
              },
            },
            { triggerTurn: true, deliverAs: 'followUp' },
          );
        },
      });
      const currentDelivery = delivery;
      unsubscribe = await active.subscribe(() => {
        void currentDelivery
          .flush()
          .catch((error) => failures(error instanceof Error ? error.message : String(error), ctx));
      });

      if (ctx.mode === 'tui') ui = await createFleetUI(active, ctx);
      await currentDelivery.flush();
    })();

    try {
      await initializing;
    } finally {
      initializing = undefined;
    }
  };

  const ready = async (ctx: ExtensionContext) => {
    await initialize(ctx);

    if (!runtime) throw new Error('Durable runtime is unavailable');

    return runtime;
  };

  const resumedAgent = async (ctx: ExtensionContext, id: string) => {
    try {
      return await (await ready(ctx)).get(id);
    } catch {
      return undefined;
    }
  };

  const writePolicyReason = (role: string) =>
    `Subagent role "${role}" can write files and was not authorized. Implement the work in the parent, or ask the user to run /agents implement on to allow write-capable subagents for this session.`;

  const showWritePolicy = (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return;
    ctx.ui.setStatus(
      'durable-subagents-policy',
      allowWriteChildren ? 'subagents: writes allowed' : undefined,
    );
  };

  const restoreWritePolicy = (ctx: ExtensionContext) => {
    allowWriteChildren = false;

    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== 'custom' || entry.customType !== policyEntryType) continue;

      if (Check(policyEntrySchema, entry.data)) allowWriteChildren = entry.data.allowWrites;
    }

    showWritePolicy(ctx);
  };

  const setWritePolicy = (allow: boolean, ctx: ExtensionContext) => {
    allowWriteChildren = allow;
    pi.appendEntry(policyEntryType, { allowWrites: allow });
    showWritePolicy(ctx);
  };

  pi.on('session_start', async (_event, ctx) => {
    await close();
    restoreWritePolicy(ctx);
    await initialize(ctx);
  });
  pi.on('session_shutdown', close);
  pi.on('message_end', async () => {
    await delivery?.flush();
  });
  pi.on('agent_settled', async () => {
    await delivery?.settled();
  });

  pi.on('tool_call', async (event, ctx) => {
    if (event.toolName !== 'Agent' || allowWriteChildren) return;

    const input = event.input;

    if (!Check(agentCall, input)) return;
    const roles = loadRoles(ctx.cwd, getAgentDir());
    let requires = false;
    let label = '';

    if (input.resume) {
      const agent = await resumedAgent(ctx, input.resume);

      if (!agent) return;
      const role = roles.get(agent.configuration.role);

      requires = role ? requiresWriteAuthorization(role) : true;
      label = agent.configuration.role;
    } else {
      const role = roles.get(input.subagent_type ?? 'general-purpose');

      if (!role) return;
      requires = requiresWriteAuthorization(role);
      label = role.name;
    }

    if (!requires) return;

    if (!ctx.hasUI) return { block: true, reason: writePolicyReason(label) };
    const once = 'Allow once';
    const session = 'Allow for this session';

    const choice = await ctx.ui.select(
      `Subagent "${label}" can write files.${input.description ? `\n${input.description}` : ''}`,
      [once, session, 'Deny'],
    );

    if (choice === once) return;

    if (choice === session) {
      setWritePolicy(true, ctx);

      return;
    }

    return { block: true, reason: writePolicyReason(label) };
  });

  pi.registerTool({
    name: 'Agent',
    label: 'Agent',
    description:
      'Delegate to a persistent Durable child. Prefer read-only roles (Explore, Plan, custom read-only agents) for investigation and review, and implement changes in the parent unless the user asks for a subagent. Write-capable roles require explicit user authorization. Types: Explore, Plan, general-purpose, or a custom .pi/agents definition. Background is the default; foreground waits and is cancelled by parent Esc. Explore and Plan have no write/edit tools, but their shell access is prompt-restricted, not sandboxed. No MCP, workflows, scheduling, nested delegation, or legacy isolated/max_turns fields. Worktree isolation starts from recorded HEAD without parent uncommitted changes.',
    parameters: Type.Object(
      {
        prompt: Type.String(),
        description: Type.String(),
        subagent_type: Type.Optional(Type.String()),
        name: Type.Optional(Type.String()),
        run_in_background: Type.Optional(Type.Boolean()),
        model: Type.Optional(Type.String()),
        thinking: Type.Optional(Type.String()),
        inherit_context: Type.Optional(Type.Boolean()),
        isolation: Type.Optional(Type.Union([Type.Literal('off'), Type.Literal('worktree')])),
        resume: Type.Optional(Type.String()),
      },
      { additionalProperties: false },
    ),
    async execute(callId, args, signal, onUpdate, ctx) {
      const active = await ready(ctx);
      const background = args.run_in_background ?? true;

      if (!background) signal?.throwIfAborted();
      const requestId = `tool:${callId}`;

      if (
        args.resume &&
        (args.model ||
          args.thinking ||
          args.isolation ||
          args.inherit_context ||
          args.subagent_type ||
          args.name)
      )
        throw new Error(
          'Resume uses the saved configuration. Model, thinking, isolation, history, type, and name cannot change.',
        );
      let task;
      let agent;

      if (args.resume) {
        agent = await active.get(args.resume);
        task = await active.send({
          id: agent.id,
          requestId,
          message: args.prompt,
          followUp: true,
          background,
        });
      } else {
        if (!ctx.model) throw new Error('Parent has no configured model');

        const configuration = await resolveConfiguration({
          project: ctx.cwd,
          role: args.subagent_type ?? 'general-purpose',
          parentModel: ctx.model,
          parentThinking: ctx.thinkingLevel ?? pi.getThinkingLevel(),
          registry: ctx.modelRegistry,
          model: args.model,
          thinking: args.thinking,
          isolation: args.isolation,
          history: args.inherit_context
            ? JSON.stringify(ctx.sessionManager.buildContextEntries())
            : '',
        });

        task = await active.start({
          requestId,
          name: args.name ?? `${args.subagent_type ?? 'agent'}-${callId.slice(-8)}`,
          description: args.description,
          message: args.prompt,
          configuration,
          background,
        });
        agent = await active.get(requestId);
      }

      onUpdate?.({
        content: [
          {
            type: 'text',
            text: `Started ${agent.name}${agent.worktree ? `. Worktree ${agent.worktree.path}. Parent uncommitted changes were not copied.` : ''}`,
          },
        ],
        details: {
          agent_id: agent.id,
          conversation_id: agent.conversationId,
          owner_task: agent.ownerTask,
        },
      });

      if (background)
        return {
          content: [
            {
              type: 'text',
              text: `Started ${agent.name} in the background. Agent ID: ${agent.id}${agent.worktree ? `\nWorktree: ${agent.worktree.path}\nBranch: ${agent.worktree.branch}\nParent uncommitted changes were not copied.` : ''}`,
            },
          ],
          details: { agent_id: agent.id, conversation_id: agent.conversationId },
        };
      const result = await active.wait(task, signal);

      return response(result, await active.get(agent.id));
    },
  });
  pi.registerTool({
    name: 'get_subagent_result',
    label: 'Subagent result',
    description:
      'Retrieve a Durable agent result by ID or unique name. wait waits for its latest request. verbose includes the saved conversation. Failed work returns an error, not success.',
    parameters: Type.Object(
      {
        agent_id: Type.String(),
        wait: Type.Optional(Type.Boolean()),
        verbose: Type.Optional(Type.Boolean()),
      },
      { additionalProperties: false },
    ),
    async execute(_callId, args, _signal, _update, ctx) {
      const active = await ready(ctx);
      let agent = await active.get(args.agent_id);
      const latest = agent.tasks.at(-1);

      if (args.wait && latest) {
        await active.wait(latest);
        agent = await active.get(args.agent_id);
      }

      if (!agent.finishedAt)
        return {
          content: [{ type: 'text', text: `${agent.name} is running or queued.` }],
          details: { agent_id: agent.id, status: 'running' },
        };
      const result = response(agent.result ?? { status: 'failed', text: 'No saved result' }, agent);

      if (args.verbose)
        result.content.push({
          type: 'text',
          text: JSON.stringify((await (await active.conversation(agent)).context(context)).entries),
        });

      return result;
    },
  });
  pi.registerTool({
    name: 'steer_subagent',
    label: 'Steer agent',
    description:
      'Send a steering message during a run, queue a follow-up with follow_up, or continue an idle child. The child retains its saved model, instructions, tools and cwd.',
    parameters: Type.Object(
      { agent_id: Type.String(), message: Type.String(), follow_up: Type.Optional(Type.Boolean()) },
      { additionalProperties: false },
    ),
    async execute(callId, args, _signal, _update, ctx) {
      const active = await ready(ctx);
      await active.send({
        id: args.agent_id,
        requestId: `steer:${callId}`,
        message: args.message,
        followUp: args.follow_up ?? false,
      });

      return {
        content: [{ type: 'text', text: `Sent to ${args.agent_id}.` }],
        details: { agent_id: args.agent_id },
      };
    },
  });
  pi.registerTool({
    name: 'stop_subagent',
    label: 'Stop agent',
    description:
      'Abort active work and queued inputs for one Durable child, retaining its conversation and worktree for inspection and continuation.',
    parameters: Type.Object({ agent_id: Type.String() }, { additionalProperties: false }),
    async execute(_callId, args, _signal, _update, ctx) {
      await (await ready(ctx)).stop(args.agent_id);

      return {
        content: [{ type: 'text', text: `Stopped ${args.agent_id}. Conversation retained.` }],
        details: { agent_id: args.agent_id },
      };
    },
  });

  const cleanup = async (id: string, path: string, ctx: ExtensionContext) => {
    const active = await ready(ctx);
    const agent = await active.get(id);

    if (!agent.worktree || agent.worktree.path !== path)
      throw new Error('Cleanup requires the exact recorded worktree path');
    const live = await active.harness.snapshot(LiveDoc, agent.conversationId, context);

    const tasks = await Promise.all(
      agent.tasks.map((task) => active.harness.getTask(task, context)),
    );

    if (live?.run || tasks.some((task) => task && task.state.status !== 'terminal'))
      throw new Error('Stop the agent and queued requests before cleanup');

    if (
      ctx.hasUI &&
      !(await ctx.ui.confirm(
        'Remove owned worktree?',
        `${path}\nBranch ${agent.worktree.branch} will be retained. Dirty work is never discarded.`,
      ))
    )
      throw new Error('Cleanup cancelled');

    return worktreeServices(
      join(getAgentDir(), 'durable-subagents'),
      ctx.sessionManager.getSessionId(),
    ).cleanup(agent.worktree);
  };

  pi.registerTool({
    name: 'cleanup_subagent_worktree',
    label: 'Clean up worktree',
    description:
      'Only after explicit user authorization: remove one clean, owned, idle worktree. Requires its exact recorded path. Refuses dirty or ignored files. Retains the branch and never commits or merges.',
    parameters: Type.Object(
      { agent_id: Type.String(), path: Type.String() },
      { additionalProperties: false },
    ),
    async execute(_callId, args, _signal, _update, ctx) {
      return {
        content: [{ type: 'text', text: await cleanup(args.agent_id, args.path, ctx) }],
        details: { agent_id: args.agent_id },
      };
    },
  });
  pi.registerCommand('agents', {
    description:
      'Durable agents for this parent session. /agents [id], /agents implement on|off, /agents stop ID, /agents cleanup ID PATH',
    async handler(args, ctx) {
      const input = args.trim();

      if (input === 'implement on' || input === 'implement off') {
        const allow = input === 'implement on';

        setWritePolicy(allow, ctx);
        ctx.ui.notify(
          allow
            ? 'Write-capable subagents are allowed for this session'
            : 'Write-capable subagents require authorization',
          'info',
        );

        return;
      }

      await ready(ctx);

      if (input.startsWith('stop ')) {
        await runtime!.stop(input.slice(5));
        ctx.ui.notify('Agent stopped', 'info');

        return;
      }

      if (input.startsWith('cleanup ')) {
        const split = input.indexOf(' ', 8);

        if (split < 0) throw new Error('Usage: /agents cleanup ID EXACT_PATH');
        ctx.ui.notify(await cleanup(input.slice(8, split), input.slice(split + 1), ctx), 'info');

        return;
      }

      if (!ui) {
        ctx.ui.notify(
          'Terminal inspector requires interactive Pi. Use get_subagent_result in other modes.',
          'info',
        );

        return;
      }

      if (input) await ui.inspect((await runtime!.get(input)).id);
      else await ui.overview();
    },
  });
  pi.registerShortcut('ctrl+alt+a', {
    description: 'Open Durable agent fleet',
    handler: async (ctx) => {
      await ready(ctx);
      await ui?.overview();
    },
  });
}
