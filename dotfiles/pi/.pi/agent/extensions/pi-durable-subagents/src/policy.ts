import { Type } from 'typebox';
import type { Role } from './configuration.ts';

export const policyEntryType = 'durable-subagents.policy';

export const policyEntrySchema = Type.Object({ allowWrites: Type.Boolean() });

// User-installed roles are the authorization; project roles opt in per file so a cloned
// repository cannot grant itself write-capable subagents.
export function requiresWriteAuthorization(role: Role): boolean {
  const writes = role.tools.some((tool) => tool === 'write' || tool === 'edit');

  if (!writes) return false;

  if (role.source === 'user') return false;

  if (role.source === 'project' && role.approved) return false;

  return true;
}
