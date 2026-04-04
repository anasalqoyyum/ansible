/**
 * Plan Mode Extension
 *
 * Read-only exploration mode for safe code analysis.
 * When enabled, only read-only tools are available.
 *
 * Features:
 * - /plan command or Ctrl+Alt+P to toggle
 * - Bash restricted to allowlisted read-only commands
 * - Extracts numbered plan steps from "Plan:" sections
 * - [DONE:n] markers to complete steps during execution
 * - Progress tracking widget during execution
 */

import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key } from "@mariozechner/pi-tui";
import { extractTodoItems, isSafeCommand, markCompletedSteps, type TodoItem } from "./utils.js";
import {
	closeExportedPlanTodos,
	exportPlanStepsToTodos,
	extractSourceTodoFromPrompt,
	type ExportedPlanTodo,
	type PlanTodoSource,
} from "./todo-bridge.js";

// Tools
const PLAN_MODE_TOOL_CANDIDATES = ["read", "bash", "grep", "find", "ls", "questionnaire"];

// Type guard for assistant messages
function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray(m.content);
}

// Extract text content from an assistant message
function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

export default function planModeExtension(pi: ExtensionAPI): void {
	let planModeEnabled = false;
	let executionMode = false;
	let todoItems: TodoItem[] = [];
	let restoreTools: string[] | null = null;
	let exportedTodos: ExportedPlanTodo[] = [];
	let sourceTodo: PlanTodoSource | null = null;

	pi.registerFlag("plan", {
		description: "Start in plan mode (read-only exploration)",
		type: "boolean",
		default: false,
	});

	function getAvailableToolNames(): Set<string> {
		return new Set(pi.getAllTools().map((tool) => tool.name));
	}

	function filterAvailableTools(names: string[]): string[] {
		const available = getAvailableToolNames();
		return [...new Set(names.filter((name) => available.has(name)))];
	}

	function getPlanModeTools(): string[] {
		return filterAvailableTools(PLAN_MODE_TOOL_CANDIDATES);
	}

	function restoreToolSelection(): void {
		const target = restoreTools ?? pi.getActiveTools();
		const filtered = filterAvailableTools(target);
		if (filtered.length > 0) {
			pi.setActiveTools(filtered);
		}
	}

	function enablePlanMode(ctx: ExtensionContext, options?: { resetPlan?: boolean; notify?: boolean }): void {
		const { resetPlan = true, notify = true } = options ?? {};
		if (!planModeEnabled && !executionMode) {
			restoreTools = [...pi.getActiveTools()];
		}

		planModeEnabled = true;
		executionMode = false;
		if (resetPlan) {
			todoItems = [];
			exportedTodos = [];
			sourceTodo = null;
		}

		const planTools = getPlanModeTools();
		if (planTools.length > 0) {
			pi.setActiveTools(planTools);
		}

		if (notify) {
			ctx.ui.notify(`Plan mode enabled. Tools: ${planTools.join(", ") || "(none available)"}`);
		}
		updateStatus(ctx);
		persistState();
	}

	function disablePlanMode(ctx: ExtensionContext, options?: { clearPlan?: boolean; notify?: boolean }): void {
		const { clearPlan = true, notify = true } = options ?? {};
		planModeEnabled = false;
		executionMode = false;
		if (clearPlan) {
			todoItems = [];
			exportedTodos = [];
			sourceTodo = null;
		}
		restoreToolSelection();
		restoreTools = null;
		if (notify) {
			ctx.ui.notify("Plan mode disabled. Previous tool access restored.");
		}
		updateStatus(ctx);
		persistState();
	}

	function startExecutionMode(ctx: ExtensionContext): void {
		planModeEnabled = false;
		executionMode = todoItems.length > 0;
		restoreToolSelection();
		updateStatus(ctx);
		persistState();
	}

	function updateStatus(ctx: ExtensionContext): void {
		// Footer status
		if (executionMode && todoItems.length > 0) {
			const completed = todoItems.filter((t) => t.completed).length;
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("accent", `📋 ${completed}/${todoItems.length}`));
		} else if (planModeEnabled) {
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("warning", "⏸ plan"));
		} else {
			ctx.ui.setStatus("plan-mode", undefined);
		}

		// Widget showing todo list
		if (executionMode && todoItems.length > 0) {
			const lines = todoItems.map((item) => {
				if (item.completed) {
					return (
						ctx.ui.theme.fg("success", "☑ ") + ctx.ui.theme.fg("muted", ctx.ui.theme.strikethrough(item.text))
					);
				}
				return `${ctx.ui.theme.fg("muted", "☐ ")}${item.text}`;
			});
			ctx.ui.setWidget("plan-todos", lines);
		} else {
			ctx.ui.setWidget("plan-todos", undefined);
		}
	}

	function togglePlanMode(ctx: ExtensionContext): void {
		if (planModeEnabled || executionMode) {
			disablePlanMode(ctx);
			return;
		}
		enablePlanMode(ctx);
	}

	function persistState(): void {
		pi.appendEntry("plan-mode", {
			enabled: planModeEnabled,
			todos: todoItems,
			executing: executionMode,
			restoreTools,
			exportedTodos,
			sourceTodo,
		});
	}

	function rememberPlanPrompt(prompt: string): void {
		sourceTodo = extractSourceTodoFromPrompt(prompt);
		exportedTodos = [];
	}

	async function exportCurrentPlan(ctx: ExtensionContext): Promise<boolean> {
		if (todoItems.length === 0) {
			ctx.ui.notify("No plan steps to export yet.", "info");
			return false;
		}

		const previousCount = exportedTodos.length;
		const nextExported = await exportPlanStepsToTodos({
			cwd: ctx.cwd,
			items: todoItems,
			existing: exportedTodos,
			sourceTodo,
		});
		const createdCount = nextExported.length - previousCount;
		exportedTodos = nextExported;
		await closeExportedPlanTodos({ cwd: ctx.cwd, exported: exportedTodos, items: todoItems });
		persistState();

		if (createdCount <= 0) {
			ctx.ui.notify("Current plan steps are already exported to .pi/todos.", "info");
			return true;
		}

		const exportedIds = nextExported.map((todo) => `TODO-${todo.id}`).join(", ");
		ctx.ui.notify(`Exported ${createdCount} plan step(s) to .pi/todos: ${exportedIds}`, "info");
		return true;
	}

	pi.registerCommand("plan", {
		description: "Toggle or control plan mode (/plan, /plan on, /plan off, /plan export, /plan start <prompt>)",
		handler: async (args, ctx) => {
			const input = (args ?? "").trim();

			if (!input) {
				togglePlanMode(ctx);
				return;
			}

			if (["on", "enable"].includes(input)) {
				if (planModeEnabled && !executionMode) {
					ctx.ui.notify("Plan mode is already enabled.", "info");
					return;
				}
				enablePlanMode(ctx, { resetPlan: false });
				return;
			}

			if (["off", "disable"].includes(input)) {
				if (!planModeEnabled && !executionMode) {
					ctx.ui.notify("Plan mode is already disabled.", "info");
					return;
				}
				disablePlanMode(ctx);
				return;
			}

			if (input === "export") {
				await exportCurrentPlan(ctx);
				return;
			}

			if (input === "start") {
				enablePlanMode(ctx);
				rememberPlanPrompt("");
				persistState();
				ctx.ui.notify("Plan mode enabled. Enter your planning prompt.", "info");
				return;
			}

			if (input.startsWith("start ")) {
				const prompt = input.slice("start ".length).trim();
				enablePlanMode(ctx);
				rememberPlanPrompt(prompt);
				persistState();
				if (!prompt) {
					ctx.ui.notify("Plan mode enabled. Enter your planning prompt.", "info");
					return;
				}
				pi.sendUserMessage(prompt);
				return;
			}

			ctx.ui.notify("Usage: /plan [on|off|export|start <prompt>]", "info");
		},
	});

	pi.registerCommand("todos-plan", {
		description: "Show current in-memory plan steps and progress",
		handler: async (_args, ctx) => {
			if (todoItems.length === 0) {
				ctx.ui.notify("No todos. Create a plan first with /plan", "info");
				return;
			}
			const exportedByStep = new Map(exportedTodos.map((todo) => [todo.step, todo] as const));
			const list = todoItems
				.map((item, i) => {
					const exported = exportedByStep.get(item.step);
					const exportSuffix = exported ? ` → TODO-${exported.id}` : "";
					return `${i + 1}. ${item.completed ? "✓" : "○"} ${item.text}${exportSuffix}`;
				})
				.join("\n");
			ctx.ui.notify(`Plan Progress:\n${list}`, "info");
		},
	});

	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle plan mode",
		handler: async (ctx) => togglePlanMode(ctx),
	});

	// Block destructive bash commands in plan mode
	pi.on("tool_call", async (event) => {
		if (!planModeEnabled || event.toolName !== "bash") return;

		const command = event.input.command as string;
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `Plan mode: command blocked (not allowlisted). Use /plan to disable plan mode first.\nCommand: ${command}`,
			};
		}
	});

	// Filter out stale plan mode context when not in plan mode
	pi.on("context", async (event) => {
		if (planModeEnabled) return;

		return {
			messages: event.messages.filter((m) => {
				const msg = m as AgentMessage & { customType?: string };
				if (msg.customType === "plan-mode-context") return false;
				if (msg.role !== "user") return true;

				const content = msg.content;
				if (typeof content === "string") {
					return !content.includes("[PLAN MODE ACTIVE]");
				}
				if (Array.isArray(content)) {
					return !content.some(
						(c) => c.type === "text" && (c as TextContent).text?.includes("[PLAN MODE ACTIVE]"),
					);
				}
				return true;
			}),
		};
	});

	// Inject plan/execution context before agent starts
	pi.on("before_agent_start", async () => {
		if (planModeEnabled) {
			const toolList = getPlanModeTools();
			return {
				message: {
					customType: "plan-mode-context",
					content: `[PLAN MODE ACTIVE]
You are in plan mode - a read-only exploration mode for safe code analysis.

Restrictions:
- You can only use: ${toolList.join(", ") || "the currently enabled read-only tools"}
- You CANNOT use: edit, write (file modifications are disabled)
- Bash is restricted to an allowlist of read-only commands

Ask clarifying questions using the questionnaire tool.
Use brave-search skill via bash for web research.

Create a detailed numbered plan under a "Plan:" header:

Plan:
1. First step description
2. Second step description
...

Do NOT attempt to make changes - just describe what you would do.`,
					display: false,
				},
			};
		}

		if (executionMode && todoItems.length > 0) {
			const remaining = todoItems.filter((t) => !t.completed);
			const todoList = remaining.map((t) => `${t.step}. ${t.text}`).join("\n");
			return {
				message: {
					customType: "plan-execution-context",
					content: `[EXECUTING PLAN - Full tool access enabled]

Remaining steps:
${todoList}

Execute each step in order.
After completing a step, include a [DONE:n] tag in your response.`,
					display: false,
				},
			};
		}
	});

	// Track progress after each turn
	pi.on("turn_end", async (event, ctx) => {
		if (!executionMode || todoItems.length === 0) return;
		if (!isAssistantMessage(event.message)) return;

		const text = getTextContent(event.message);
		if (markCompletedSteps(text, todoItems) > 0) {
			await closeExportedPlanTodos({ cwd: ctx.cwd, exported: exportedTodos, items: todoItems });
			updateStatus(ctx);
		}
		persistState();
	});

	// Handle plan completion and plan mode UI
	pi.on("agent_end", async (event, ctx) => {
		// Check if execution is complete
		if (executionMode && todoItems.length > 0) {
			if (todoItems.every((t) => t.completed)) {
				const completedList = todoItems.map((t) => `~~${t.text}~~`).join("\n");
				pi.sendMessage(
					{ customType: "plan-complete", content: `**Plan Complete!** ✓\n\n${completedList}`, display: true },
					{ triggerTurn: false },
				);
				executionMode = false;
				todoItems = [];
				restoreToolSelection();
				restoreTools = null;
				updateStatus(ctx);
				persistState(); // Save cleared state so resume doesn't restore old execution mode
			}
			return;
		}

		if (!planModeEnabled || !ctx.hasUI) return;

		// Extract todos from last assistant message
		const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
		if (lastAssistant) {
			const extracted = extractTodoItems(getTextContent(lastAssistant));
			if (extracted.length > 0) {
				todoItems = extracted;
				exportedTodos = [];
				persistState();
			}
		}

		// Show plan steps and prompt for next action
		if (todoItems.length > 0) {
			const todoListText = todoItems.map((t, i) => `${i + 1}. ☐ ${t.text}`).join("\n");
			pi.sendMessage(
				{
					customType: "plan-todo-list",
					content: `**Plan Steps (${todoItems.length}):**\n\n${todoListText}`,
					display: true,
				},
				{ triggerTurn: false },
			);
		}

		const choice = await ctx.ui.select("Plan mode - what next?", [
			todoItems.length > 0 ? "Execute the plan (track progress)" : "Execute the plan",
			...(todoItems.length > 0 ? ["Export steps to .pi/todos"] : []),
			"Stay in plan mode",
			"Refine the plan",
		]);

		if (choice?.startsWith("Execute")) {
			startExecutionMode(ctx);
			const firstTodo = todoItems[0];

			const execMessage =
				firstTodo
					? `Execute the plan. Start with: ${firstTodo.text}`
					: "Execute the plan you just created.";
			pi.sendMessage(
				{ customType: "plan-mode-execute", content: execMessage, display: true },
				{ triggerTurn: true },
			);
		} else if (choice === "Export steps to .pi/todos") {
			await exportCurrentPlan(ctx);
		} else if (choice === "Refine the plan") {
			const refinement = await ctx.ui.editor("Refine the plan:", "");
			if (refinement?.trim()) {
				pi.sendUserMessage(refinement.trim());
			}
		}
	});

	// Restore state on session start/resume
	pi.on("session_start", async (_event, ctx) => {
		if (pi.getFlag("plan") === true) {
			planModeEnabled = true;
		}

		const entries = ctx.sessionManager.getEntries();

		// Restore persisted state
		const planModeEntry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "plan-mode")
			.pop() as
			| {
					data?: {
						enabled: boolean;
						todos?: TodoItem[];
						executing?: boolean;
						restoreTools?: string[] | null;
						exportedTodos?: ExportedPlanTodo[];
						sourceTodo?: PlanTodoSource | null;
					};
				}
			| undefined;

		if (planModeEntry?.data) {
			planModeEnabled = planModeEntry.data.enabled ?? planModeEnabled;
			todoItems = planModeEntry.data.todos ?? todoItems;
			executionMode = planModeEntry.data.executing ?? executionMode;
			restoreTools = planModeEntry.data.restoreTools ?? restoreTools;
			exportedTodos = planModeEntry.data.exportedTodos ?? exportedTodos;
			sourceTodo = planModeEntry.data.sourceTodo ?? sourceTodo;
		}

		if ((planModeEnabled || executionMode) && !restoreTools) {
			restoreTools = [...pi.getActiveTools()];
		}

		// On resume: re-scan messages to rebuild completion state
		// Only scan messages AFTER the last "plan-mode-execute" to avoid picking up [DONE:n] from previous plans
		const isResume = planModeEntry !== undefined;
		if (isResume && executionMode && todoItems.length > 0) {
			// Find the index of the last plan-mode-execute entry (marks when current execution started)
			let executeIndex = -1;
			for (let i = entries.length - 1; i >= 0; i--) {
				const currentEntry = entries[i];
				if (!currentEntry) continue;
				const entry = currentEntry as { type: string; customType?: string };
				if (entry.customType === "plan-mode-execute") {
					executeIndex = i;
					break;
				}
			}

			// Only scan messages after the execute marker
			const messages: AssistantMessage[] = [];
			for (let i = executeIndex + 1; i < entries.length; i++) {
				const entry = entries[i];
				if (!entry) continue;
				if (entry.type === "message" && "message" in entry && isAssistantMessage(entry.message as AgentMessage)) {
					messages.push(entry.message as AssistantMessage);
				}
			}
			const allText = messages.map(getTextContent).join("\n");
			markCompletedSteps(allText, todoItems);
			await closeExportedPlanTodos({ cwd: ctx.cwd, exported: exportedTodos, items: todoItems });
		}

		if (planModeEnabled) {
			const planTools = getPlanModeTools();
			if (planTools.length > 0) {
				pi.setActiveTools(planTools);
			}
		}
		updateStatus(ctx);
	});
}
