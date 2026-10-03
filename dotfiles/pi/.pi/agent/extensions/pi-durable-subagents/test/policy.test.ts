import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Check } from 'typebox/value';
import type { Role } from '../src/configuration.ts';
import { policyEntrySchema, requiresWriteAuthorization } from '../src/policy.ts';

function role(source: Role['source'], tools: string[], approved = false): Role {
  return {
    name: 'test',
    description: 'test',
    instructions: '',
    tools,
    source,
    approved,
  };
}

test('write authorization follows role provenance and approval', () => {
  const allTools = ['read', 'write', 'edit', 'bash'];

  assert.equal(requiresWriteAuthorization(role('builtin', allTools)), true);
  assert.equal(requiresWriteAuthorization(role('builtin', ['read', 'bash'])), false);
  assert.equal(requiresWriteAuthorization(role('user', allTools)), false);
  assert.equal(requiresWriteAuthorization(role('user', ['read', 'bash'])), false);
  assert.equal(requiresWriteAuthorization(role('project', ['read', 'write'])), true);
  assert.equal(requiresWriteAuthorization(role('project', ['read', 'write'], true)), false);
  assert.equal(requiresWriteAuthorization(role('project', ['read', 'bash'])), false);
});

test('policy entries accept only a boolean allowWrites flag', () => {
  assert.equal(Check(policyEntrySchema, { allowWrites: true }), true);
  assert.equal(Check(policyEntrySchema, { allowWrites: 'yes' }), false);
  assert.equal(Check(policyEntrySchema, { allow: true }), false);
});
