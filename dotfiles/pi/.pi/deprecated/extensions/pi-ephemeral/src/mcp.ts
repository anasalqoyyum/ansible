import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import type { ProjectMcpJson, ProjectMcpServerConfig } from "./types.ts";
import { ensureTrailingNewline, isJsonObject } from "./util.ts";

export async function readProjectMcp(projectMcpPath: string): Promise<ProjectMcpJson | undefined> {
  let raw: string;
  try {
    raw = await readFile(projectMcpPath, "utf8");
  } catch (error) {
    if (isEnoent(error)) return undefined;
    throw error;
  }

  const parsed = JSON.parse(raw) as unknown;
  return normalizeProjectMcp(parsed, projectMcpPath);
}

export function cloneProjectMcp(value?: ProjectMcpJson): ProjectMcpJson {
  if (!value) {
    return { mcpServers: {} };
  }

  const mcpServers = value.mcpServers
    ? Object.fromEntries(Object.entries(value.mcpServers).map(([serverName, serverConfig]) => [serverName, { ...serverConfig }]))
    : {};

  return {
    ...value,
    mcpServers,
  };
}

export async function writeProjectMcp(projectMcpPath: string, value: ProjectMcpJson): Promise<void> {
  await mkdir(dirname(projectMcpPath), { recursive: true });
  await writeFile(projectMcpPath, ensureTrailingNewline(JSON.stringify(value, null, 2)), "utf8");
}

function normalizeProjectMcp(raw: unknown, projectMcpPath: string): ProjectMcpJson {
  if (!isJsonObject(raw)) {
    throw new Error(`Invalid project MCP config: ${projectMcpPath}`);
  }

  const normalizedServers: Record<string, ProjectMcpServerConfig> = {};

  const shorthandServers = raw.mcp;
  if (shorthandServers !== undefined) {
    assertProjectMcpServers(shorthandServers, projectMcpPath);
    for (const [serverName, serverConfig] of Object.entries(shorthandServers)) {
      const normalized = normalizeProjectMcpServer(serverName, serverConfig, projectMcpPath);
      if (normalized) {
        normalizedServers[serverName] = normalized;
      }
    }
  }

  const canonicalServers = raw.mcpServers;
  if (canonicalServers !== undefined) {
    assertProjectMcpServers(canonicalServers, projectMcpPath);
    for (const [serverName, serverConfig] of Object.entries(canonicalServers)) {
      normalizedServers[serverName] = normalizeProjectMcpServer(serverName, serverConfig, projectMcpPath) ?? serverConfig;
    }
  }

  const passthroughEntries = Object.entries(raw).filter(([key]) => key !== "mcp" && key !== "mcpServers");
  return {
    ...Object.fromEntries(passthroughEntries),
    mcpServers: normalizedServers,
  };
}

function normalizeProjectMcpServer(
  serverName: string,
  serverConfig: ProjectMcpServerConfig,
  projectMcpPath: string,
): ProjectMcpServerConfig | undefined {
  if (serverConfig.enabled === false) {
    return undefined;
  }

  const normalized: ProjectMcpServerConfig = { ...serverConfig };

  if (Array.isArray(serverConfig.command)) {
    const commandParts = serverConfig.command.filter((value): value is string => typeof value === "string" && value.length > 0);
    if (commandParts.length === 0) {
      throw new Error(`Invalid MCP server config for '${serverName}': ${projectMcpPath}`);
    }

    normalized.command = commandParts[0];
    if (commandParts.length > 1) {
      normalized.args = commandParts.slice(1);
    } else {
      delete normalized.args;
    }
  }

  if (normalized.type === "local") {
    delete normalized.type;
  }

  if ("enabled" in normalized) {
    delete normalized.enabled;
  }

  return normalized;
}

function assertProjectMcpServers(value: unknown, projectMcpPath: string): asserts value is Record<string, ProjectMcpServerConfig> {
  if (!isJsonObject(value)) {
    throw new Error(`Invalid project MCP config: ${projectMcpPath}`);
  }

  for (const [serverName, serverConfig] of Object.entries(value)) {
    if (!isJsonObject(serverConfig)) {
      throw new Error(`Invalid MCP server config for '${serverName}': ${projectMcpPath}`);
    }
  }
}

function isEnoent(error: unknown): error is NodeJS.ErrnoException {
  return error !== null
    && typeof error === "object"
    && "code" in error
    && (error as NodeJS.ErrnoException).code === "ENOENT";
}
