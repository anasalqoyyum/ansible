import {
  LiveDoc,
  UsageDoc,
  type EntryRecord,
  type LiveState,
  type UsageState,
} from '@earendil-works/pi-durable';
import { context, type Runtime } from './runtime.ts';
import type { AgentRecord } from './state.ts';

export type AgentSnapshot = {
  record: AgentRecord;
  entries: readonly EntryRecord[];
  live: LiveState;
  usage: UsageState;
};

export async function observeAgent(
  runtime: Runtime,
  id: string,
  changed: (snapshot: AgentSnapshot) => void,
) {
  const agent = await runtime.get(id);
  const child = await runtime.conversation(agent);
  const state = await child.viewState(context);
  let disposed = false;
  let work = Promise.resolve();

  const refresh = () => {
    work = work.then(async () => {
      if (disposed) return;
      const record = await runtime.get(id);
      const live = (await runtime.harness.snapshot(LiveDoc, child.id, context)) ?? {};

      const usage = (await runtime.harness.snapshot(UsageDoc, child.id, context)) ?? {
        models: {},
        tools: {},
      };

      if (!disposed) changed({ record, entries: state.value.entries, live, usage });
    });

    return work;
  };

  const offView = state.subscribe(() => {
    void refresh();
  });

  const offFleet = await runtime.subscribe(() => {
    void refresh();
  });

  await refresh();

  return async () => {
    if (disposed) {
      await work;

      return;
    }

    disposed = true;
    offView();
    offFleet();
    state.dispose();
    await work;
  };
}
