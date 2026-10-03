import assert from 'node:assert/strict';
import { fauxProvider, fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

export default function driver(pi: ExtensionAPI) {
  const faux = fauxProvider();
  faux.setResponses([
    fauxAssistantMessage(
      fauxToolCall('Agent', {
        prompt: 'reply marker',
        description: 'CLI proof',
        subagent_type: 'cli-writer',
        run_in_background: false,
      }),
      { stopReason: 'toolUse' },
    ),
    fauxAssistantMessage('CLI_CHILD_OK'),
    (request) => {
      assert.ok(JSON.stringify(request.messages).includes('CLI_CHILD_OK'));

      return fauxAssistantMessage('CLI_PARENT_OK');
    },
  ]);
  pi.registerProvider(faux.provider);
  pi.on('session_start', () => {
    assert.equal(pi.getAllTools().filter((tool) => tool.name === 'Agent').length, 1);
  });
}
