import { randomUUID } from 'node:crypto';
import {
  getMarkdownTheme,
  type ExtensionContext,
  type Theme,
} from '@earendil-works/pi-coding-agent';
import {
  Editor,
  Input,
  Markdown,
  ScrollView,
  Text,
  TuiMainScreen,
  TuiAltScreen,
  matchesKey,
  isKeyRelease,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
  type Component,
  type TUI,
} from '@earendil-works/pi-tui';
import type { Message } from '@earendil-works/pi-ai';
import { observeAgent, type AgentSnapshot } from './observe.ts';
import type { Runtime } from './runtime.ts';

export function rightAlign(left: string, right: string, width: number): string {
  const rightWidth = visibleWidth(right);
  const leftClamped = truncateToWidth(left, Math.max(0, width - rightWidth - 1));
  const gap = Math.max(1, width - visibleWidth(leftClamped) - rightWidth);

  return truncateToWidth(leftClamped + ' '.repeat(gap) + right, width);
}

function plain(value: string) {
  let result = '';

  for (const character of value) {
    const code = character.charCodeAt(0);

    if ((code >= 32 && code !== 127) || code === 9 || code === 10) result += character;
  }

  return result;
}

export function status(snapshot: AgentSnapshot) {
  return snapshot.live.run
    ? 'running'
    : snapshot.record.finishedAt
      ? (snapshot.record.result?.status ?? 'idle')
      : 'queued';
}

export function activity(snapshot: AgentSnapshot) {
  const tools =
    snapshot.live.tools?.filter((tool) => tool.status === 'running').map((tool) => tool.name) ?? [];

  if (tools.length) return tools.join(', ');

  const text = snapshot.live.generation?.message?.content
    .flatMap((part) => (part.type === 'text' ? [part.text] : []))
    .join('');

  return plain(
    text?.split('\n').findLast((line) => line.trim()) ??
      (snapshot.live.run ? 'thinking' : snapshot.record.description),
  );
}

export function stats(snapshot: AgentSnapshot) {
  const usage = [...Object.values(snapshot.usage.models), ...Object.values(snapshot.usage.tools)];
  const tokens = usage.reduce((sum, bucket) => sum + bucket.totalTokens, 0);
  const cost = usage.reduce((sum, bucket) => sum + bucket.cost.total, 0);

  const seconds = Math.max(
    0,
    Math.round(
      ((snapshot.live.run ? Date.now() : snapshot.record.finishedAt) ?? Date.now()) -
        snapshot.record.startedAt,
    ) / 1000,
  );

  return `${seconds.toFixed(0)}s · ${tokens} tokens${cost > 0 ? ` · ~$${cost.toFixed(4)}` : ''}`;
}

function statusIcon(snapshot: AgentSnapshot, theme: Pick<Theme, 'fg'>) {
  switch (status(snapshot)) {
    case 'completed':
      return theme.fg('success', '✓');
    case 'failed':
      return theme.fg('error', '✗');
    case 'stopped':
      return theme.fg('warning', '■');
    case 'running':
      return theme.fg('accent', '●');
    default:
      return theme.fg('muted', '○');
  }
}

function panel(lines: readonly string[], width: number, theme: Pick<Theme, 'fg'>) {
  if (width < 6) return lines.map((line) => truncateToWidth(line, width));
  const inner = width - 4;

  return [
    theme.fg('border', `╭${'─'.repeat(width - 2)}╮`),
    ...lines.map((line) => {
      const text = truncateToWidth(line, inner);

      return (
        theme.fg('border', '│') +
        ' ' +
        text +
        ' '.repeat(Math.max(0, inner - visibleWidth(text))) +
        ' ' +
        theme.fg('border', '│')
      );
    }),
    theme.fg('border', `╰${'─'.repeat(width - 2)}╯`),
  ];
}

export const FINISHED_LINGER_MS = 4000;

export function visibleFleet(
  snapshots: readonly AgentSnapshot[],
  now = Date.now(),
  viewing?: string,
) {
  return snapshots.filter(
    (snapshot) =>
      snapshot.live.run ||
      !snapshot.record.finishedAt ||
      snapshot.record.id === viewing ||
      now - snapshot.record.finishedAt < FINISHED_LINGER_MS,
  );
}

export function fleetLines(
  snapshots: readonly AgentSnapshot[],
  width: number,
  theme: Pick<Theme, 'fg'>,
  selected = -1,
  limit = 5,
) {
  const start = Math.max(0, selected - limit + 1);
  const shown = snapshots.slice(start, start + limit);

  const lines = shown.map((snapshot, index) => {
    const active = index + start === selected;
    const color = active ? 'accent' : 'muted';
    const label = `${theme.fg(color, active ? '›' : ' ')} ${statusIcon(snapshot, theme)} ${theme.fg(color, `${plain(snapshot.record.name)} ${status(snapshot)} · ${activity(snapshot)}`)}`;

    return rightAlign(label, theme.fg('dim', stats(snapshot)), width);
  });

  if (start > 0) lines.unshift(truncateToWidth(`↑ ${start} more`, width));

  if (start + shown.length < snapshots.length)
    lines.push(truncateToWidth(`↓ ${snapshots.length - start - shown.length} more`, width));

  return lines;
}

export class Inspector implements Component {
  private scroll: ScrollView;
  private content: Text;
  private armed = false;
  private raw = false;
  private width = 80;
  private height = 10;
  private markdown = new Map<string, Markdown>();
  private snapshot: AgentSnapshot;
  private tui: { terminal: { rows: number }; requestRender: () => void };
  private theme: Pick<Theme, 'fg' | 'bold'>;
  private done: () => void;
  private send: (message: string, followUp: boolean) => Promise<void>;
  private stop: () => Promise<void>;
  private disposed = false;
  private _focused = false;
  private action:
    | { kind: 'view'; error?: string }
    | { kind: 'compose'; input: Input; followUp: boolean; pending: boolean; error?: string }
    | { kind: 'stopping' } = { kind: 'view' };

  get focused() {
    return this._focused;
  }
  set focused(value: boolean) {
    this._focused = value;

    if (this.action.kind === 'compose') this.action.input.focused = value;
  }

  constructor(input: {
    snapshot: AgentSnapshot;
    tui: { terminal: { rows: number }; requestRender: () => void };
    theme: Pick<Theme, 'fg' | 'bold'>;
    done: () => void;
    send: (message: string, followUp: boolean) => Promise<void>;
    stop: () => Promise<void>;
  }) {
    this.snapshot = input.snapshot;
    this.tui = input.tui;
    this.theme = input.theme;
    this.done = input.done;
    this.send = input.send;
    this.stop = input.stop;
    this.content = new Text('', 0, 0);
    this.scroll = new ScrollView(this.content, { follow: 'end', scrollbar: 'hidden' });
  }
  update(snapshot: AgentSnapshot) {
    if (this.disposed) return;
    this.snapshot = snapshot;
    this.invalidate();
    this.tui.requestRender();
  }
  invalidate() {
    this.content.invalidate();

    for (const md of this.markdown.values()) md.invalidate();
  }
  private text(text: string, key?: string) {
    if (key && !this.raw) {
      let markdown = this.markdown.get(key);

      if (!markdown) {
        markdown = new Markdown(plain(text), 0, 0, getMarkdownTheme(), undefined, {
          preserveOrderedListMarkers: true,
          preserveBackslashEscapes: true,
        });
        this.markdown.set(key, markdown);
      } else markdown.setText(plain(text));

      return markdown.render(this.width);
    }

    return plain(text)
      .split('\n')
      .flatMap((line) => wrapTextWithAnsi(line, this.width));
  }
  private message(message: Message, key: string): string[] {
    if (message.role === 'system') return [];

    const lines = [
      this.theme.fg(
        'accent',
        message.role === 'toolResult'
          ? `${message.toolName} result${message.isError ? ' [error]' : ''}`
          : message.role,
      ),
    ];

    if (!Array.isArray(message.content)) lines.push(...this.text(message.content));
    else
      for (const part of message.content) {
        if (part.type === 'text')
          lines.push(...this.text(part.text, message.role === 'assistant' ? key : undefined));
        else if (part.type === 'thinking') lines.push(...this.text(`Thinking: ${part.thinking}`));
        else if (part.type === 'toolCall')
          lines.push(...this.text(`${part.name}(${JSON.stringify(part.arguments)})`));
        else lines.push('[non-text content]');
      }

    return [...lines, ''];
  }
  render(width: number) {
    if (width < 1) return [];
    this.width = Math.max(1, width - 4);
    const snapshot = this.snapshot;
    const maxHeight = Math.max(1, Math.floor(this.tui.terminal.rows * 0.8));
    const header = `${statusIcon(snapshot, this.theme)} ${plain(snapshot.record.name)} · ${status(snapshot)} · ${stats(snapshot)}`;

    if (width < 6 || maxHeight < 8)
      return [header, 'Esc close'].slice(0, maxHeight).map((line) => truncateToWidth(line, width));

    const composing = this.action.kind === 'compose' ? this.action : undefined;
    const error = this.action.kind === 'stopping' ? undefined : this.action.error;
    this.height = Math.max(0, maxHeight - 7 - (composing ? 1 : 0));

    const body = snapshot.entries.flatMap((entry) =>
      (entry.model ?? []).flatMap((message, index) =>
        this.message(message, `${entry.id}:${index}`),
      ),
    );

    const partial = snapshot.live.generation?.message;

    if (partial) body.push(...this.message(partial, 'partial'));

    for (const tool of snapshot.live.tools ?? [])
      if (tool.status !== 'done')
        body.push(...this.text(`${tool.name} [${tool.status}]\n${tool.output ?? ''}`));

    if (snapshot.record.worktree)
      body.push(
        ...this.text(
          `Worktree ${snapshot.record.worktree.branch}\n${snapshot.record.worktree.path}\nBase ${snapshot.record.worktree.baseCommit}\n${snapshot.record.changedFiles ?? ''}`,
        ),
      );
    this.content.setText(body.join('\n'));
    this.scroll.updateLayout(body.length, this.height, () => this.tui.requestRender());

    const viewport = Array.from(
      { length: this.height },
      (_, index) => body[this.scroll.scrollTop + index] ?? '',
    );

    const separator = this.theme.fg('dim', '─'.repeat(this.width));

    const footer = error
      ? this.theme.fg(
          'error',
          `${plain(error)} · ${composing ? 'Enter retry · Esc cancel' : 'Esc close'}`,
        )
      : composing
        ? composing.pending
          ? 'Sending…'
          : 'Enter send · Esc cancel'
        : this.action.kind === 'stopping'
          ? 'Stopping… · Esc close'
          : this.armed
            ? 'Press x again to stop. Any other key cancels.'
            : rightAlign(
                'Enter/s steer · f follow-up · x stop · m raw/md',
                '↑↓ PgUp/PgDn Home/End · Esc close',
                this.width,
              );

    return panel(
      [
        this.theme.bold(header),
        `${snapshot.record.configuration.model.provider}/${snapshot.record.configuration.model.modelId} · ${snapshot.record.configuration.thinking}`,
        separator,
        ...viewport,
        separator,
        ...(composing ? composing.input.render(this.width) : []),
        footer,
      ],
      width,
      this.theme,
    );
  }

  private compose(followUp: boolean) {
    const input = new Input({ prompt: followUp ? 'Follow-up > ' : 'Steer > ' });

    const action: Extract<typeof this.action, { kind: 'compose' }> = {
      kind: 'compose',
      input,
      followUp,
      pending: false,
    };

    input.focused = this.focused;
    input.onEscape = () => {
      input.focused = false;
      this.action = { kind: 'view' };
    };

    input.onSubmit = (value) => {
      if (!value.trim()) {
        input.onEscape?.();

        return;
      }

      void this.submit(action, value);
    };

    this.action = action;
  }

  private async submit(action: Extract<typeof this.action, { kind: 'compose' }>, value: string) {
    action.pending = true;
    delete action.error;

    try {
      await this.send(value, action.followUp);

      if (this.disposed) return;
      action.input.focused = false;
      this.action = { kind: 'view' };
    } catch (error) {
      if (this.disposed) return;
      action.pending = false;
      action.error = error instanceof Error ? error.message : String(error);
    }

    if (!this.disposed) this.tui.requestRender();
  }

  private async stopAgent() {
    this.action = { kind: 'stopping' };

    try {
      await this.stop();

      if (!this.disposed) this.action = { kind: 'view' };
    } catch (error) {
      if (!this.disposed)
        this.action = {
          kind: 'view',
          error: error instanceof Error ? error.message : String(error),
        };
    }

    if (!this.disposed) this.tui.requestRender();
  }

  handleInput(data: string) {
    if (this.disposed || isKeyRelease(data)) return;

    if (this.action.kind === 'compose') {
      if (!this.action.pending) this.action.input.handleInput(data);
      this.tui.requestRender();

      return;
    }

    if (matchesKey(data, 'escape') || matchesKey(data, 'q') || matchesKey(data, 'ctrl+c')) {
      this.dispose();
      this.done();

      return;
    }

    if (matchesKey(data, 'x')) {
      if (this.action.kind === 'stopping') return;

      if (this.armed) {
        this.armed = false;
        void this.stopAgent();
      } else this.armed = true;
    } else {
      this.armed = false;

      if (this.action.kind === 'view' && (matchesKey(data, 's') || matchesKey(data, 'enter')))
        this.compose(false);
      else if (this.action.kind === 'view' && matchesKey(data, 'f')) this.compose(true);
      else if (matchesKey(data, 'm')) this.raw = !this.raw;
      else if (matchesKey(data, 'up')) this.scroll.scrollBy(-1);
      else if (matchesKey(data, 'down')) this.scroll.scrollBy(1);
      else if (matchesKey(data, 'pageUp')) this.scroll.scrollBy(-this.height);
      else if (matchesKey(data, 'pageDown')) this.scroll.scrollBy(this.height);
      else if (matchesKey(data, 'home')) this.scroll.scrollToStart();
      else if (matchesKey(data, 'end')) this.scroll.scrollToEnd();
    }

    this.tui.requestRender();
  }

  dispose() {
    this.disposed = true;

    if (this.action.kind === 'compose') this.action.input.focused = false;
  }
}

export async function createFleetUI(
  runtime: Runtime,
  ctx: {
    ui: Pick<
      ExtensionContext['ui'],
      'setWidget' | 'custom' | 'onTerminalInput' | 'getEditorText' | 'notify'
    >;
  },
  presentation: { now?: () => number } = {},
) {
  const snapshots = new Map<string, AgentSnapshot>();
  const observers = new Map<string, () => Promise<void>>();
  const listeners = new Set<() => void>();
  const transientObservers = new Set<() => Promise<void>>();
  let closed = false;
  let widgetTui: TUI | undefined;
  let closeOverlay: (() => void) | undefined;
  let widget: Component | undefined;
  let selectedId: string | undefined;
  let viewingId: string | undefined;
  const now = presentation.now ?? Date.now;

  const ordered = () =>
    [...snapshots.values()].sort((a, b) => a.record.startedAt - b.record.startedAt);

  const compact = () => visibleFleet(ordered(), now(), viewingId);

  const notify = () => {
    const fleet = compact();

    if (!fleet.length) selectedId = undefined;
    else if (
      selectedId &&
      selectedId !== 'main' &&
      !fleet.some((agent) => agent.record.id === selectedId)
    )
      selectedId = 'main';
    widgetTui?.requestRender();

    for (const listener of listeners) listener();
  };

  let refreshWork = Promise.resolve();

  const refresh = () => {
    refreshWork = refreshWork.then(async () => {
      if (closed) return;
      const fleet = await runtime.snapshot();

      for (const agent of Object.values(fleet?.agents ?? {})) {
        if (observers.has(agent.id)) continue;

        const dispose = await observeAgent(runtime, agent.id, (snapshot) => {
          if (!closed) {
            snapshots.set(agent.id, snapshot);
            notify();
          }
        });

        if (closed) await dispose();
        else observers.set(agent.id, dispose);
      }
    });

    return refreshWork;
  };

  const offFleet = await runtime.subscribe(() => {
    void refresh();
  });

  await refresh();
  ctx.ui.setWidget(
    'durable-subagents',
    (tui, theme) => {
      widgetTui = tui;
      widget = {
        render: (width) => {
          const fleet = compact();

          if (!fleet.length) return [];
          const index = fleet.findIndex((agent) => agent.record.id === selectedId);

          return [
            truncateToWidth(
              selectedId
                ? 'Agents · ↑↓ select · Enter inspect · Esc prompt'
                : 'Agents · ↓/← select · /agents · ctrl+alt+a',
              width,
            ),
            theme.fg(
              selectedId === 'main' ? 'accent' : 'muted',
              truncateToWidth(`${selectedId === 'main' ? '›' : ' '} ○ main`, width),
            ),
            ...fleetLines(fleet, width, theme, index),
          ];
        },
        invalidate: () => {},
      };

      return widget;
    },
    { placement: 'belowEditor' },
  );

  let hadRows = compact().length > 0;

  const timer = setInterval(() => {
    const hasRows = compact().length > 0;

    if (hasRows || hadRows) notify();
    hadRows = hasRows;
  }, 500);

  timer.unref();

  const inspect = async (id: string) => {
    if (closed || viewingId || closeOverlay) return;
    viewingId = id;
    let snapshot: AgentSnapshot | undefined;
    let inspector: Inspector | undefined;
    let dispose: (() => Promise<void>) | undefined;

    try {
      dispose = await observeAgent(runtime, id, (next) => {
        snapshot = next;
        inspector?.update(next);
      });
      transientObservers.add(dispose);

      if (closed) return;
      const initial = snapshot;

      if (!initial) throw new Error('Inspector snapshot is unavailable');
      await ctx.ui.custom<void>(
        (tui, theme, _keys, done) => {
          closeOverlay = () => done();
          inspector = new Inspector({
            snapshot: initial,
            tui,
            theme,
            done,
            stop: () => runtime.stop(id),
            send: async (message, followUp) => {
              await runtime.send({ id, requestId: `ui:${randomUUID()}`, message, followUp });
            },
          });

          return inspector;
        },
        { overlay: true, overlayOptions: { anchor: 'center', width: '90%', maxHeight: '80%' } },
      );
    } finally {
      inspector?.dispose();
      closeOverlay = undefined;
      viewingId = undefined;

      if (dispose) {
        transientObservers.delete(dispose);
        await dispose();
      }

      notify();
    }
  };

  const inspectFromFleet = async (id: string) => {
    try {
      await inspect(id);
    } catch (error) {
      if (!closed) ctx.ui.notify(error instanceof Error ? error.message : String(error), 'error');
    }
  };

  const offInput = ctx.ui.onTerminalInput((data) => {
    if (closed || isKeyRelease(data) || viewingId || closeOverlay) return;

    // The core editor can be empty while a dialog owns input. Never intercept its keys.
    if (
      !(widgetTui instanceof TuiMainScreen || widgetTui instanceof TuiAltScreen) ||
      !(widgetTui.getFocusedComponent() instanceof Editor) ||
      ctx.ui.getEditorText() !== ''
    ) {
      selectedId = undefined;
      notify();

      return;
    }

    const fleet = compact();

    if (!fleet.length) return;

    if (!selectedId) {
      if (!matchesKey(data, 'down') && !matchesKey(data, 'left')) return;
      selectedId = 'main';
    } else if (matchesKey(data, 'down')) {
      const index = fleet.findIndex((agent) => agent.record.id === selectedId);
      selectedId = fleet[Math.min(fleet.length - 1, index + 1)]?.record.id ?? 'main';
    } else if (matchesKey(data, 'up')) {
      const index = fleet.findIndex((agent) => agent.record.id === selectedId);
      selectedId = selectedId === 'main' ? undefined : (fleet[index - 1]?.record.id ?? 'main');
    } else if (matchesKey(data, 'escape')) selectedId = undefined;
    else if (matchesKey(data, 'enter')) {
      if (selectedId === 'main') selectedId = undefined;
      else void inspectFromFleet(selectedId);
    } else {
      selectedId = undefined;
      notify();

      return;
    }

    notify();

    return { consume: true };
  });

  const overview = async () => {
    if (viewingId || closeOverlay) return;
    let selectedAgent: string | undefined;

    while (!closed) {
      const selected = await ctx.ui.custom<string | undefined>(
        (tui, theme, _keys, done) => {
          let index = Math.max(
            0,
            ordered().findIndex((agent) => agent.record.id === selectedAgent),
          );

          closeOverlay = () => done(undefined);
          const listener = () => tui.requestRender();
          listeners.add(listener);

          return {
            render: (width) => {
              const all = ordered();
              index = Math.min(index, Math.max(0, all.length - 1));
              const inner = Math.max(1, width - 4);
              const limit = Math.max(1, Math.floor(tui.terminal.rows * 0.8) - 6);

              return panel(
                [
                  'Agents · ↑↓ select · Enter inspect · Esc close',
                  theme.fg('dim', '─'.repeat(inner)),
                  ...(all.length
                    ? fleetLines(all, inner, theme, index, limit)
                    : ['No agents for this parent session.']),
                ],
                width,
                theme,
              ).slice(0, Math.max(1, Math.floor(tui.terminal.rows * 0.8)));
            },
            handleInput: (data) => {
              if (isKeyRelease(data)) return;

              if (matchesKey(data, 'escape') || matchesKey(data, 'q')) done(undefined);
              else if (matchesKey(data, 'up')) index = Math.max(0, index - 1);
              else if (matchesKey(data, 'down')) index = Math.min(ordered().length - 1, index + 1);
              else if (matchesKey(data, 'enter')) {
                const selected = ordered()[index];

                if (selected) done(selected.record.id);
              }

              tui.requestRender();
            },
            invalidate: () => {},
            dispose: () => listeners.delete(listener),
          };
        },
        { overlay: true, overlayOptions: { anchor: 'center', width: '90%', maxHeight: '80%' } },
      );

      closeOverlay = undefined;

      if (!selected || closed) return;
      selectedAgent = selected;
      await inspect(selected);
    }
  };

  return {
    overview,
    inspect,
    async dispose() {
      if (closed) return;
      closed = true;
      clearInterval(timer);
      offInput();
      closeOverlay?.();
      offFleet();
      ctx.ui.setWidget('durable-subagents', undefined);
      await refreshWork;
      await Promise.all([...observers.values(), ...transientObservers].map((dispose) => dispose()));
      transientObservers.clear();
      observers.clear();
      snapshots.clear();
      listeners.clear();
      widgetTui = undefined;
      widget = undefined;
    },
  };
}

export type FleetUI = Awaited<ReturnType<typeof createFleetUI>>;
