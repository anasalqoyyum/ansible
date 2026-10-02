import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import {
  getSelectListTheme,
  initTheme,
  type ExtensionContext,
  type Theme,
} from '@earendil-works/pi-coding-agent';
import { KeybindingsManager } from '../node_modules/@earendil-works/pi-coding-agent/dist/core/keybindings.js';
import { theme as piTheme } from '../node_modules/@earendil-works/pi-coding-agent/dist/modes/interactive/theme/theme.js';
import { createModels } from '@earendil-works/pi-ai';
import { fauxProvider, fauxAssistantMessage } from '@earendil-works/pi-ai/providers/faux';
import {
  visibleWidth,
  CURSOR_MARKER,
  Editor,
  Input,
  TuiMainScreen,
  TuiAltScreen,
  type TUI,
  type Component,
  type Terminal,
} from '@earendil-works/pi-tui';
import { openRuntime } from '../src/runtime.ts';
import { observeAgent, type AgentSnapshot } from '../src/observe.ts';
import {
  Inspector,
  fleetLines,
  rightAlign,
  status,
  createFleetUI,
  visibleFleet,
  FINISHED_LINGER_MS,
} from '../src/ui.ts';
import type { ResolvedConfiguration } from '../src/state.ts';

async function until(check: () => boolean) {
  for (let n = 0; n < 500; n++) {
    if (check()) return;
    await delay(10);
  }

  throw new Error('UI condition timed out');
}

test('inspector receives a current mid-run snapshot and committed updates; completed view reopens; disposal stops updates', async () => {
  initTheme('dark', false);
  const directory = await mkdtemp(join(tmpdir(), 'ui-tests-'));
  const faux = fauxProvider({ tokensPerSecond: 400 });
  const models = createModels();
  models.setProvider(faux.provider);
  const options = { directory, models, parentSession: 'ui' };
  let runtime = await openRuntime(options);
  let dispose: (() => Promise<void>) | undefined;

  try {
    const configuration: ResolvedConfiguration = {
      role: 'general-purpose',
      model: { provider: 'faux', modelId: 'faux-1' },
      thinking: 'off',
      tools: [],
      instructions: 'UI test',
      cwd: directory,
      project: directory,
      isolation: 'off',
      history: '',
    };

    const text =
      '# Live answer\n\n' +
      Array.from({ length: 50 }, (_, index) => `Line ${index} wide 漢字`).join('\n');

    faux.setResponses([fauxAssistantMessage(text)]);

    const task = await runtime.start({
      requestId: 'ui-agent',
      name: 'UI 漢字',
      description: 'live test',
      configuration,
      message: 'answer',
      background: true,
    });

    let snapshot: AgentSnapshot | undefined;
    let updates = 0;
    dispose = await observeAgent(runtime, 'ui-agent', (value) => {
      snapshot = value;
      updates++;
    });
    assert.ok(snapshot);
    await until(
      () =>
        !!snapshot?.live.generation?.message?.content.some(
          (part) => part.type === 'text' && part.text.length > 0,
        ),
    );
    assert.ok(snapshot.entries.length > 0);
    let renders = 0;
    const terminal = { rows: 24 };
    const theme = { fg: (_color: string, text: string) => text, bold: (text: string) => text };
    const actions: string[] = [];

    const inspector = new Inspector({
      snapshot,
      tui: { terminal, requestRender: () => renders++ },
      theme,
      done: () => actions.push('close'),
      send: async (message, followUp) => {
        actions.push(`${followUp ? 'followUp' : 'steer'}:${message}`);
      },
      stop: async () => {
        actions.push('stop');
      },
    });

    for (const width of [1, 4, 12, 40, 100])
      assert.ok(inspector.render(width).every((line) => visibleWidth(line) <= width));
    await runtime.wait(task);
    await until(() => !!snapshot?.record.finishedAt);
    assert.ok(snapshot);
    inspector.update(snapshot);
    assert.equal(status(snapshot), 'completed');
    assert.ok(updates > 2);
    assert.ok(
      snapshot.entries.some((entry) => JSON.stringify(entry.model).includes('Live answer')),
    );
    inspector.handleInput('\x1b[H');
    const start = inspector.render(60).join('\n');
    inspector.handleInput('\x1b[F');
    const end = inspector.render(60).join('\n');
    assert.notEqual(start, end);
    inspector.handleInput('x');
    assert.deepEqual(actions, []);
    inspector.handleInput('m');
    inspector.handleInput('x');
    inspector.handleInput('x');
    await delay(0);
    assert.deepEqual(actions, ['stop']);
    const framed = inspector.render(100);
    assert.ok(framed[0]?.startsWith('╭'));
    assert.ok(framed.at(-1)?.endsWith('╯'));
    assert.ok(framed.slice(1, -1).every((line) => line.startsWith('│ ') && line.endsWith(' │')));
    assert.ok(framed.every((line) => visibleWidth(line) === 100));

    const shortView = new Inspector({
      snapshot: {
        ...snapshot,
        entries: [],
        live: { ...snapshot.live, generation: undefined, tools: [] },
      },
      tui: { terminal, requestRender() {} },
      theme,
      done() {},
      send: async () => {},
      stop: async () => {},
    });

    assert.equal(shortView.render(100).length, framed.length);
    shortView.dispose();
    let release!: () => void;

    const pending = new Promise<void>((resolve) => {
      release = resolve;
    });

    const submitted: string[] = [];
    let errorClosed = false;

    const errors = new Inspector({
      snapshot,
      tui: { terminal, requestRender() {} },
      theme,
      done: () => {
        errorClosed = true;
      },
      send: async (message) => {
        submitted.push(message);

        if (submitted.length === 1) throw new Error('Admission failed');
        await pending;
      },
      stop: async () => {
        throw new Error('Stop failed');
      },
    });

    errors.focused = true;
    errors.handleInput('s');
    errors.handleInput('saved draft');
    errors.handleInput('\r');
    await delay(0);
    assert.ok(errors.render(100).some((line) => line.includes('Admission failed')));
    assert.ok(errors.render(100).some((line) => line.includes('saved draft')));
    terminal.rows = 10;
    assert.ok(errors.render(20).length <= 8);
    terminal.rows = 24;
    errors.focused = false;
    assert.ok(!errors.render(100).join('\n').includes(CURSOR_MARKER));
    errors.focused = true;
    errors.handleInput('\r');
    errors.handleInput('\r');
    assert.deepEqual(submitted, ['saved draft', 'saved draft']);
    release();
    await delay(0);
    errors.handleInput('x');
    errors.handleInput('x');
    await delay(0);
    assert.ok(errors.render(100).some((line) => line.includes('Stop failed')));
    assert.equal(errorClosed, false);
    errors.handleInput('f');
    errors.handleInput('\r');
    assert.equal(submitted.length, 2);
    errors.handleInput('\x1b');
    assert.equal(errorClosed, true);
    inspector.focused = true;
    inspector.handleInput('\r');
    inspector.handleInput('question x m s');
    assert.ok(inspector.render(100).join('\n').includes(CURSOR_MARKER));
    assert.deepEqual(actions, ['stop']);
    inspector.handleInput('\r');
    await delay(0);
    assert.deepEqual(actions, ['stop', 'steer:question x m s']);
    inspector.handleInput('f');
    inspector.handleInput('next');
    inspector.handleInput('\r');
    await delay(0);
    assert.deepEqual(actions, ['stop', 'steer:question x m s', 'followUp:next']);
    inspector.handleInput('s');
    inspector.handleInput('\x1b');
    assert.equal(actions.at(-1), 'followUp:next');
    terminal.rows = 10;
    inspector.invalidate();
    assert.ok(inspector.render(20).length <= 8);
    inspector.handleInput('\x1b');
    assert.equal(actions.at(-1), 'close');
    assert.ok(renders > 0);

    const tokens = Object.values(snapshot.usage.models).reduce(
      (sum, usage) => sum + usage.totalTokens,
      0,
    );

    assert.ok(fleetLines([snapshot], 100, theme)[0]?.includes(`${tokens} tokens`));
    assert.ok(fleetLines([snapshot], 100, theme)[0]?.includes('✓'));

    for (const [outcome, icon] of [
      ['failed', '✗'],
      ['stopped', '■'],
    ] as const) {
      const finished: AgentSnapshot = {
        ...snapshot,
        record: { ...snapshot.record, result: { status: outcome, text: '' } },
      };

      assert.ok(fleetLines([finished], 100, theme)[0]?.includes(icon));
    }

    const finishedAt = snapshot.record.finishedAt!;
    assert.equal(visibleFleet([snapshot], finishedAt + FINISHED_LINGER_MS - 1).length, 1);
    assert.equal(visibleFleet([snapshot], finishedAt + FINISHED_LINGER_MS).length, 0);
    assert.equal(
      visibleFleet([snapshot], finishedAt + FINISHED_LINGER_MS, snapshot.record.id).length,
      1,
    );
    assert.equal(
      visibleFleet(
        [{ ...snapshot, record: { ...snapshot.record, finishedAt: undefined } }],
        finishedAt + FINISHED_LINGER_MS,
      ).length,
      1,
    );

    const unsafeName = {
      ...snapshot,
      record: { ...snapshot.record, name: '\u0000UI\u0007 漢字😀\u001f\u007f' },
    };

    assert.ok(fleetLines([unsafeName], 200, theme)[0]?.includes('UI 漢字😀'));

    for (const code of [0, 7, 31, 127])
      assert.ok(!fleetLines([unsafeName], 200, theme)[0]?.includes(String.fromCharCode(code)));

    for (const width of [1, 5, 20])
      assert.ok(visibleWidth(rightAlign('very long 漢字 label', '99 tokens', width)) <= width);
    await dispose();
    dispose = undefined;
    const count = updates;
    faux.setResponses([fauxAssistantMessage('after disposal')]);
    await runtime.wait(
      await runtime.send({ id: 'ui-agent', requestId: 'next', message: 'next', followUp: true }),
    );
    assert.equal(updates, count);
    await runtime.close();
    runtime = await openRuntime(options);
    let recovered: AgentSnapshot | undefined;
    dispose = await observeAgent(runtime, 'ui-agent', (value) => {
      recovered = value;
    });
    assert.ok(
      recovered?.entries.some((entry) => JSON.stringify(entry.model).includes('after disposal')),
    );
  } finally {
    await dispose?.();
    await runtime.close();
    await rm(directory, { recursive: true, force: true });
  }
});

for (const mode of ['regular', 'fullscreen'] as const) {
  test(`fleet navigates without stealing input and retains history after rows expire in ${mode} mode`, async () => {
    initTheme('dark', false);
    const directory = await mkdtemp(join(tmpdir(), 'fleet-ui-'));
    const faux = fauxProvider();
    const models = createModels();
    models.setProvider(faux.provider);
    const runtime = await openRuntime({ directory, models, parentSession: 'fleet' });

    let terminalInput: ((data: string) => void) | undefined;

    const terminal: Terminal = {
      rows: 20,
      columns: 40,
      kittyProtocolActive: false,
      start(onInput) {
        terminalInput = onInput;
      },
      stop() {},
      drainInput: async () => {},
      write() {},
      moveBy() {},
      hideCursor() {},
      showCursor() {},
      clearLine() {},
      clearFromCursor() {},
      clearScreen() {},
      setTitle() {},
      setProgress() {},
    };

    const tui = mode === 'regular' ? new TuiMainScreen(terminal) : new TuiAltScreen(terminal);

    const editor = new Editor(tui, {
      borderColor: (text) => text,
      selectList: getSelectListTheme(),
    });

    tui.addChild(editor);
    tui.setFocus(editor);
    let clock = Date.now();
    let inputsSubscribed = 0;
    let widget: Component | undefined;
    let overlay: (Component & { dispose?(): void }) | undefined;
    let overlays = 0;

    const ui: Pick<
      ExtensionContext['ui'],
      'setWidget' | 'custom' | 'onTerminalInput' | 'getEditorText' | 'notify'
    > = {
      onTerminalInput(handler) {
        inputsSubscribed++;
        const off = tui.addInputListener(handler);

        return () => {
          inputsSubscribed--;
          off();
        };
      },
      getEditorText: () => editor.getText(),
      notify(message) {
        assert.fail(message);
      },
      setWidget(_key, factory) {
        widget = !factory || Array.isArray(factory) ? undefined : factory(tui, piTheme);
      },
      async custom<T>(
        factory: (
          tui: TUI,
          theme: Theme,
          keys: KeybindingsManager,
          done: (result: T) => void,
        ) => (Component & { dispose?(): void }) | Promise<Component & { dispose?(): void }>,
        options?: Parameters<ExtensionContext['ui']['custom']>[1],
      ): Promise<T> {
        let finish!: (result: T) => void;

        const result = new Promise<T>((resolve) => {
          finish = resolve;
        });

        overlay = await factory(tui, piTheme, new KeybindingsManager(), (value) => {
          overlay?.dispose?.();
          tui.hideOverlay();
          overlay = undefined;
          finish(value);
        });
        overlays++;

        const bounds = { anchor: 'center', width: '90%', maxHeight: '80%' } satisfies NonNullable<
          Parameters<TUI['showOverlay']>[1]
        >;

        assert.equal(options?.overlay, true);
        assert.deepEqual(options.overlayOptions, bounds);
        tui.showOverlay(overlay, bounds);

        return result;
      },
    };

    let fleet: Awaited<ReturnType<typeof createFleetUI>> | undefined;

    try {
      faux.setResponses([fauxAssistantMessage('saved answer')]);

      const configuration: ResolvedConfiguration = {
        role: 'general-purpose',
        model: { provider: 'faux', modelId: 'faux-1' },
        thinking: 'off',
        tools: [],
        instructions: 'UI test',
        cwd: directory,
        project: directory,
        isolation: 'off',
        history: '',
      };

      await runtime.wait(
        await runtime.start({
          requestId: 'fleet-agent',
          name: 'fleet-agent',
          description: 'fleet',
          configuration,
          message: 'answer',
          background: true,
        }),
      );
      clock = Date.now();
      fleet = await createFleetUI(runtime, { ui }, { now: () => clock });
      assert.equal(inputsSubscribed, 1);
      assert.ok(widget?.render(100).some((line) => line.includes('fleet-agent')));
      tui.start();
      terminalInput?.('\x1b[B');
      assert.ok(widget?.render(100).some((line) => line.includes('› ○ main')));
      terminalInput?.('\x1b[B');
      assert.ok(
        widget
          ?.render(100)
          .some((line) => line.includes('›') && line.includes('✓') && line.includes('fleet-agent')),
      );
      terminalInput?.('z');
      assert.equal(editor.getText(), 'z');
      assert.equal(overlays, 0);
      editor.setText('draft');
      terminalInput?.('\x1b[B');
      assert.equal(overlays, 0);
      assert.ok(!widget?.render(100).some((line) => line.includes('›')));
      editor.setText('');
      const dialog = new Input();
      tui.setFocus(dialog);
      terminalInput?.('\x1b[B');
      terminalInput?.('\r');
      assert.equal(overlays, 0);
      tui.setFocus(editor);
      terminalInput?.('\x1b[D');
      terminalInput?.('\x1b[B');
      terminalInput?.('\r');
      await until(() => overlays === 1);
      assert.ok(overlay?.render(100).some((line) => line.includes('saved answer')));
      assert.ok(overlay?.render(12).every((line) => visibleWidth(line) <= 12));
      clock += FINISHED_LINGER_MS + 1;
      assert.ok(widget?.render(100).some((line) => line.includes('fleet-agent')));
      faux.setResponses([fauxAssistantMessage('inline reply')]);
      terminalInput?.('\r');
      terminalInput?.('keep inspecting');
      terminalInput?.('\r');
      await until(
        () =>
          overlays === 1 && !!overlay?.render(100).some((line) => line.includes('inline reply')),
      );
      assert.equal(editor.getText(), '');
      terminalInput?.('\x1b');
      await until(() => overlay === undefined);
      clock = Date.now() + FINISHED_LINGER_MS + 1;
      await until(() => widget?.render(100).length === 0);
      assert.deepEqual(widget?.render(100), []);
      assert.ok((await runtime.get('fleet-agent')).result?.text.includes('inline reply'));
      const overview = fleet.overview();
      await until(() => overlays === 2);
      assert.ok(overlay?.render(100).some((line) => line.includes('fleet-agent')));
      terminalInput?.('\r');
      await until(() => overlays === 3);
      assert.ok(overlay?.render(100).some((line) => line.includes('inline reply')));
      await fleet.dispose();
      await overview;
      assert.equal(inputsSubscribed, 0);
      assert.equal(widget, undefined);
      assert.equal(overlay, undefined);
      await runtime.close();
      const reopened = await openRuntime({ directory, models, parentSession: 'fleet' });
      await reopened.close();
    } finally {
      await fleet?.dispose();
      await runtime.close();
      tui.stop();
      await rm(directory, { recursive: true, force: true });
    }
  });
}
