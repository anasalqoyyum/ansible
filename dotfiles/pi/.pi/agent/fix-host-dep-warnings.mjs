#!/usr/bin/env node
// pi declares host-provided modules (typebox, @earendil-works/pi-*) in peerDependencies with a
// "*" range; a copy in `dependencies` can bypass the extension loader's module mapping. npm
// reinstalls restore the manifests npm published, so re-run this after `pi update` / `npm install`.
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// Mirrors HOST_PROVIDED_EXTENSION_PACKAGES in pi's dist/core/resource-loader.js.
const HOST_PROVIDED = new Set([
  "@earendil-works/pi-agent-core",
  "@earendil-works/pi-ai",
  "@earendil-works/pi-coding-agent",
  "@earendil-works/pi-tui",
  "@mariozechner/pi-agent-core",
  "@mariozechner/pi-ai",
  "@mariozechner/pi-coding-agent",
  "@mariozechner/pi-tui",
  "@sinclair/typebox",
  "typebox",
]);

const HELP = `Usage: node fix-host-dep-warnings.mjs [--dry-run] [--root=<node_modules>]

Moves host-provided module names out of \`dependencies\` and into \`peerDependencies\` with a "*"
range for installed pi extension packages. Default root: ${join(homedir(), ".pi", "agent", "npm", "node_modules")}
`;

const args = process.argv.slice(2);
if (args.includes("--help") || args.includes("-h")) {
  process.stdout.write(HELP);
  process.exit(0);
}
const dryRun = args.includes("--dry-run") || args.includes("-n");
const rootArg = args.find((arg) => arg.startsWith("--root="));
const root = rootArg ? rootArg.slice("--root=".length) : join(homedir(), ".pi", "agent", "npm", "node_modules");

if (!existsSync(root)) {
  console.error(`node_modules root not found: ${root}`);
  process.exit(1);
}

function listPackageDirs(dir, depth = 0) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    const isDir = entry.isDirectory() || (entry.isSymbolicLink() && statSync(path).isDirectory());
    if (!isDir) continue;
    if (entry.name.startsWith("@") && depth === 0) {
      out.push(...listPackageDirs(path, depth + 1));
    } else if (existsSync(join(path, "package.json"))) {
      out.push(path);
    }
  }
  return out;
}

function detectIndent(text) {
  const match = text.match(/^([ \t]+)"/m);
  return match ? match[1] : "  ";
}

const patched = [];
const alreadyCorrect = [];
const failures = [];

for (const dir of listPackageDirs(root)) {
  const manifestPath = join(dir, "package.json");
  const text = readFileSync(manifestPath, "utf8");
  let manifest;
  try {
    manifest = JSON.parse(text);
  } catch (error) {
    failures.push(`${manifestPath}: ${error.message}`);
    continue;
  }

  if (!manifest.pi?.extensions) continue;

  const offending = Object.keys(manifest.dependencies ?? {}).filter((name) => HOST_PROVIDED.has(name));
  if (offending.length === 0) {
    alreadyCorrect.push(manifest.name);
    continue;
  }

  if (dryRun) {
    patched.push(`${manifest.name} (${offending.join(", ")})`);
    continue;
  }

  for (const name of offending) {
    delete manifest.dependencies[name];
    manifest.peerDependencies = { ...manifest.peerDependencies, [name]: "*" };
  }
  if (Object.keys(manifest.dependencies).length === 0) delete manifest.dependencies;

  const indent = detectIndent(text);
  const trailingNewline = text.endsWith("\n") ? "\n" : "";
  writeFileSync(manifestPath, JSON.stringify(manifest, null, indent) + trailingNewline);
  patched.push(`${manifest.name} (${offending.join(", ")})`);
}

for (const line of patched) console.log(`${dryRun ? "would patch" : "patched"} ${line}`);
console.log(
  `${patched.length} ${dryRun ? "to patch" : "patched"}, ${alreadyCorrect.length} already correct`,
);
for (const failure of failures) console.error(`skipped unreadable manifest — ${failure}`);
if (failures.length > 0) process.exit(1);
