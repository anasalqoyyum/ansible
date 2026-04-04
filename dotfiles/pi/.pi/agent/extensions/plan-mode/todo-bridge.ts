import * as crypto from "node:crypto";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import type { TodoItem } from "./utils.js";

const TODO_DIR_NAME = ".pi/todos";
const TODO_PATH_ENV = "PI_TODO_PATH";
const TODO_ID_PREFIX = "TODO-";
const TODO_ID_PATTERN = /^[a-f0-9]{8}$/i;

interface TodoFileRecord {
	id: string;
	title: string;
	tags: string[];
	status: string;
	created_at: string;
	assigned_to_session?: string;
	body: string;
}

export interface PlanTodoSource {
	id: string;
	title?: string;
}

export interface ExportedPlanTodo {
	step: number;
	id: string;
	title: string;
	path: string;
}

function normalizeTodoId(id: string): string {
	let trimmed = id.trim();
	if (trimmed.toUpperCase().startsWith(TODO_ID_PREFIX)) {
		trimmed = trimmed.slice(TODO_ID_PREFIX.length);
	}
	return trimmed.toLowerCase();
}

function formatTodoId(id: string): string {
	const normalized = normalizeTodoId(id);
	return `${TODO_ID_PREFIX}${normalized}`;
}

function getTodosDir(cwd: string): string {
	const overridePath = process.env[TODO_PATH_ENV];
	if (overridePath && overridePath.trim()) {
		return path.resolve(cwd, overridePath.trim());
	}
	return path.resolve(cwd, TODO_DIR_NAME);
}

async function ensureTodosDir(todosDir: string): Promise<void> {
	await fs.mkdir(todosDir, { recursive: true });
}

function getTodoPath(todosDir: string, id: string): string {
	return path.join(todosDir, `${id}.md`);
}

function serializeTodo(todo: TodoFileRecord): string {
	const frontMatter = JSON.stringify(
		{
			id: todo.id,
			title: todo.title,
			tags: todo.tags,
			status: todo.status,
			created_at: todo.created_at,
			assigned_to_session: todo.assigned_to_session || undefined,
		},
		null,
		2,
	);

	const trimmedBody = todo.body.replace(/^\n+/, "").replace(/\s+$/, "");
	if (!trimmedBody) return `${frontMatter}\n`;
	return `${frontMatter}\n\n${trimmedBody}\n`;
}

async function writeTodoFile(filePath: string, todo: TodoFileRecord): Promise<void> {
	await fs.writeFile(filePath, serializeTodo(todo), "utf8");
}

async function generateTodoId(todosDir: string): Promise<string> {
	for (let attempt = 0; attempt < 10; attempt += 1) {
		const id = crypto.randomBytes(4).toString("hex");
		try {
			await fs.access(getTodoPath(todosDir, id));
		} catch {
			return id;
		}
	}
	throw new Error("Failed to generate unique todo id");
}

function findJsonObjectEnd(content: string): number {
	let depth = 0;
	let inString = false;
	let escaped = false;

	for (let i = 0; i < content.length; i += 1) {
		const char = content[i];
		if (!char) continue;

		if (inString) {
			if (escaped) {
				escaped = false;
				continue;
			}
			if (char === "\\") {
				escaped = true;
				continue;
			}
			if (char === '"') {
				inString = false;
			}
			continue;
		}

		if (char === '"') {
			inString = true;
			continue;
		}

		if (char === "{") {
			depth += 1;
			continue;
		}

		if (char === "}") {
			depth -= 1;
			if (depth === 0) return i;
		}
	}

	return -1;
}

function splitFrontMatter(content: string): { frontMatter: string; body: string } {
	if (!content.startsWith("{")) {
		return { frontMatter: "", body: content };
	}

	const endIndex = findJsonObjectEnd(content);
	if (endIndex === -1) {
		return { frontMatter: "", body: content };
	}

	return {
		frontMatter: content.slice(0, endIndex + 1),
		body: content.slice(endIndex + 1).replace(/^\r?\n+/, ""),
	};
}

function parseTodoContent(content: string, idFallback: string): TodoFileRecord {
	const { frontMatter, body } = splitFrontMatter(content);
	let parsed: Partial<TodoFileRecord> = {};

	try {
		parsed = frontMatter ? (JSON.parse(frontMatter) as Partial<TodoFileRecord>) : {};
	} catch {
		parsed = {};
	}

	return {
		id: typeof parsed.id === "string" && parsed.id ? normalizeTodoId(parsed.id) : idFallback,
		title: typeof parsed.title === "string" ? parsed.title : "",
		tags: Array.isArray(parsed.tags) ? parsed.tags.filter((tag): tag is string => typeof tag === "string") : [],
		status: typeof parsed.status === "string" && parsed.status ? parsed.status : "open",
		created_at: typeof parsed.created_at === "string" ? parsed.created_at : new Date().toISOString(),
		assigned_to_session:
			typeof parsed.assigned_to_session === "string" && parsed.assigned_to_session.trim()
				? parsed.assigned_to_session
				: undefined,
		body,
	};
}

async function readTodoFile(filePath: string, id: string): Promise<TodoFileRecord | null> {
	try {
		const content = await fs.readFile(filePath, "utf8");
		return parseTodoContent(content, id);
	} catch {
		return null;
	}
}

function buildPlanStepBody(item: TodoItem, totalSteps: number, sourceTodo: PlanTodoSource | null, exportedAt: string): string {
	const lines = [
		"Exported from plan mode.",
		`Exported at: ${exportedAt}`,
		`Plan step: ${item.step} of ${totalSteps}`,
	];

	if (sourceTodo) {
		lines.push(`Source todo: ${sourceTodo.id}${sourceTodo.title ? ` \"${sourceTodo.title}\"` : ""}`);
	}

	lines.push("", item.text);
	return lines.join("\n");
}

export function extractSourceTodoFromPrompt(prompt: string): PlanTodoSource | null {
	const match = prompt.match(/\bTODO-([a-f0-9]{8})\b(?:\s+"([^"]+)")?/i);
	if (!match) return null;
	const rawId = match[1];
	if (!rawId || !TODO_ID_PATTERN.test(rawId)) return null;
	const title = match[2]?.trim();
	return {
		id: formatTodoId(rawId),
		title: title || undefined,
	};
}

export async function exportPlanStepsToTodos(options: {
	cwd: string;
	items: TodoItem[];
	existing?: ExportedPlanTodo[];
	sourceTodo?: PlanTodoSource | null;
}): Promise<ExportedPlanTodo[]> {
	const { cwd, items, existing = [], sourceTodo = null } = options;
	const todosDir = getTodosDir(cwd);
	await ensureTodosDir(todosDir);

	const existingByStep = new Map(existing.map((todo) => [todo.step, todo] as const));
	const exported: ExportedPlanTodo[] = [];
	const exportedAt = new Date().toISOString();

	for (const item of items) {
		const existingTodo = existingByStep.get(item.step);
		if (existingTodo) {
			exported.push(existingTodo);
			continue;
		}

		const id = await generateTodoId(todosDir);
		const filePath = getTodoPath(todosDir, id);
		const title = item.text;
		const todo: TodoFileRecord = {
			id,
			title,
			tags: ["plan"],
			status: item.completed ? "closed" : "open",
			created_at: exportedAt,
			body: buildPlanStepBody(item, items.length, sourceTodo, exportedAt),
		};
		await writeTodoFile(filePath, todo);
		exported.push({ step: item.step, id, title, path: filePath });
	}

	return exported.sort((a, b) => a.step - b.step);
}

export async function closeExportedPlanTodos(options: {
	cwd: string;
	exported: ExportedPlanTodo[];
	items: TodoItem[];
}): Promise<void> {
	const { cwd, exported, items } = options;
	if (exported.length === 0) return;

	const todosDir = getTodosDir(cwd);
	const completedSteps = new Set(items.filter((item) => item.completed).map((item) => item.step));
	if (completedSteps.size === 0) return;

	for (const todo of exported) {
		if (!completedSteps.has(todo.step)) continue;
		const id = normalizeTodoId(todo.id);
		const filePath = getTodoPath(todosDir, id);
		const record = await readTodoFile(filePath, id);
		if (!record || record.status.toLowerCase() === "closed" || record.status.toLowerCase() === "done") {
			continue;
		}
		record.status = "closed";
		await writeTodoFile(filePath, record);
	}
}
