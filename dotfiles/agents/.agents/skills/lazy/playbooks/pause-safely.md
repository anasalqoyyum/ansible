# Pause safely

You own a resumable stop.

1. Stop new work and let in-flight safe operations reach a coherent boundary.
2. Record the objective, scope, current playbook step, decisions, exact file or branch state, verification run, open failures, and next command.
3. Preserve uncommitted work without committing, pushing, or publishing unless the user authorized those Git operations.
4. Stop watchers, servers, temporary processes, and delegates that should not survive the pause.
5. Identify any external operation still running and how a future session should query it.
6. Verify the handoff paths exist and contain enough information to resume without the transcript.

Report the durable handoff location, stopped processes, live external work, and exact resume point.
