import { defineDoc, type ConversationId, type TaskId } from '@earendil-works/pi-durable';
import type { ModelThinkingLevel } from '@earendil-works/pi-ai';

export type Worktree = {
  repository: string;
  path: string;
  branch: string;
  baseCommit: string;
  owner: string;
};

export type ResolvedConfiguration = {
  role: string;
  model: { provider: string; modelId: string };
  thinking: ModelThinkingLevel;
  instructions: string;
  tools: string[];
  cwd: string;
  project: string;
  isolation: 'off' | 'worktree';
  history: string;
};

export type Result = { status: 'completed' | 'failed' | 'stopped'; text: string };

export type AgentRecord = {
  id: string;
  name: string;
  description: string;
  configuration: ResolvedConfiguration;
  conversationId: ConversationId;
  ownerTask: TaskId;
  tasks: TaskId<Result>[];
  startedAt: number;
  finishedAt?: number;
  result?: Result;
  worktree?: Worktree;
  changedFiles?: string;
};

export type Report = {
  id: string;
  agentId: string;
  result: Result;
  state: 'pending' | 'delivered';
  worktree?: Worktree;
  changedFiles?: string;
};

export const Fleet = defineDoc<{
  parentSession: string;
  agents: Record<string, AgentRecord>;
  requests: Record<string, TaskId<Result>>;
  outbox: Record<string, Report>;
}>({
  kind: 'durable-subagents.fleet',
  version: 1,
  scope: 'conversation',
  history: 'latest',
  fork: 'initial',
  initial: () => ({ parentSession: '', agents: {}, requests: {}, outbox: {} }),
});
