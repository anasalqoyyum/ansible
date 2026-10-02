import { writeSync } from 'node:fs';
import { createModels, fauxProvider, fauxAssistantMessage } from '@earendil-works/pi-ai';
import { openRuntime } from '../src/runtime.ts';
import type { ResolvedConfiguration } from '../src/state.ts';

const directory = process.argv[2];

if (!directory) throw new Error('Missing temporary directory');

const faux = fauxProvider();

const models = createModels();

models.setProvider(faux.provider);

faux.setResponses([
  () => {
    writeSync(1, 'CRASH_READY\n');
    process.kill(process.pid, 'SIGKILL');

    return fauxAssistantMessage('unreachable');
  },
]);

const runtime = await openRuntime({ directory, parentSession: 'crash-parent', models });

const configuration: ResolvedConfiguration = {
  role: 'general-purpose',
  model: { provider: 'faux', modelId: 'faux-1' },
  thinking: 'off',
  tools: [],
  instructions: 'crash test',
  cwd: directory,
  project: directory,
  isolation: 'off',
  history: '',
};

await runtime.wait(
  await runtime.start({
    requestId: 'crashforeground',
    name: 'crash',
    description: 'crash',
    message: 'answer',
    configuration,
    background: false,
  }),
);
