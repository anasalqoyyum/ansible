import type { Runtime } from './runtime.ts';
import type { Report } from './state.ts';

export type ParentReports = {
  seen: () => ReadonlySet<string>;
  send: (report: Report, name: string) => void;
};

export function reportDelivery(runtime: Runtime, parent: ParentReports) {
  const queued = new Set<string>();
  let closing = false;
  let work = Promise.resolve();

  const flush = () => {
    work = work.then(async () => {
      if (closing) return;
      const fleet = await runtime.snapshot();

      for (const report of Object.values(fleet?.outbox ?? {})) {
        if (report.state !== 'pending') continue;

        if (parent.seen().has(report.id)) {
          await runtime.acknowledge(report.id);
          queued.delete(report.id);
        } else if (!queued.has(report.id)) {
          parent.send(report, fleet?.agents[report.agentId]?.name ?? report.agentId);
          queued.add(report.id);
        }
      }
    });

    return work;
  };

  return {
    flush,
    settled() {
      queued.clear();

      return flush();
    },
    async close() {
      closing = true;
      await work;
      queued.clear();
    },
  };
}
