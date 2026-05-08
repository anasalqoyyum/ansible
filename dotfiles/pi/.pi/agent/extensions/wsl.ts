import type { ExtensionAPI } from '@mariozechner/pi-coding-agent'

// Converts Windows drive-letter paths in user input and tool calls to WSL /mnt paths.

const DRIVE_PATH_START = /^[A-Za-z]:[\\/]/
const PATH_FIELD_NAMES = new Set([
	'path',
	'cwd',
	'file',
	'directory',
	'dir',
	'root',
	'baseDir',
	'target'
])
const PATH_LIST_FIELD_NAMES = new Set(['paths', 'files'])
const WRAPPER_PAIRS = new Map<string, string>([
	['"', '"'],
	["'", "'"],
	['`', '`'],
	['(', ')'],
	['[', ']'],
	['{', '}']
])

function isAsciiLetter(value: string | undefined): value is string {
	return value !== undefined && /[A-Za-z]/.test(value)
}

function isPathSeparator(value: string | undefined): boolean {
	return value === '\\' || value === '/'
}

function isHardStop(value: string | undefined, softStop?: string): boolean {
	if (value === undefined) return true
	if (softStop && value === softStop) return true

	return (
		value === '\n' ||
		value === '\r' ||
		value === '\t' ||
		value === '"' ||
		value === "'" ||
		value === '`' ||
		value === '<' ||
		value === '>' ||
		value === '|' ||
		value === '?' ||
		value === '*'
	)
}

function getSoftStop(text: string, start: number): string | undefined {
	const previous = text[start - 1]
	return previous ? WRAPPER_PAIRS.get(previous) : undefined
}

function isBoundaryStart(text: string, start: number): boolean {
	const previous = text[start - 1]
	return previous === undefined || /[\s"'`([{]/.test(previous)
}

function hasSeparatorBeforeBoundary(
	text: string,
	start: number,
	softStop?: string
): boolean {
	for (let index = start; index < text.length; index++) {
		const value = text[index]

		if (isPathSeparator(value)) return true
		if (isHardStop(value, softStop)) return false
	}

	return false
}

function trimCandidateEnd(value: string): { path: string; trailing: string } {
	let path = value
	let trailing = ''

	while (path.length > 0) {
		const last = path[path.length - 1]
		if (!last) break

		if (last === '.' || last === ',' || last === ';' || last === ':' || last === '!' || last === '?') {
			trailing = last + trailing
			path = path.slice(0, -1)
			continue
		}

		if (last === ')' || last === ']' || last === '}') {
			const opening = last === ')' ? '(' : last === ']' ? '[' : '{'
			const opens = [...path].filter((character) => character === opening).length
			const closes = [...path].filter((character) => character === last).length
			if (closes > opens) {
				trailing = last + trailing
				path = path.slice(0, -1)
				continue
			}
		}

		break
	}

	return { path, trailing }
}

function splitOuterWhitespace(value: string): {
	leading: string
	core: string
	trailing: string
} {
	const match = value.match(/^(\s*)(.*?)(\s*)$/s)
	if (!match) {
		return { leading: '', core: value, trailing: '' }
	}

	return {
		leading: match[1],
		core: match[2],
		trailing: match[3]
	}
}

function readWindowsPathCandidate(
	text: string,
	start: number
): { path: string; trailing: string; end: number } | null {
	if (!isBoundaryStart(text, start)) return null
	if (!isAsciiLetter(text[start])) return null
	if (text[start + 1] !== ':') return null
	if (!isPathSeparator(text[start + 2])) return null

	const softStop = getSoftStop(text, start)
	let index = start + 2
	let raw = text.slice(start, index)
	let sawSegment = false

	while (index < text.length && isPathSeparator(text[index])) {
		raw += text[index]
		index++
	}

	while (index < text.length) {
		const value = text[index]
		if (isHardStop(value, softStop)) break

		if (value === ' ' && !softStop && !hasSeparatorBeforeBoundary(text, index + 1, softStop)) {
			break
		}

		if (isPathSeparator(value)) {
			raw += value
			index++
			continue
		}

		const segmentStart = index
		while (index < text.length) {
			const character = text[index]
			if (isPathSeparator(character) || isHardStop(character, softStop)) break

			if (
				character === ' ' &&
				!softStop &&
				!hasSeparatorBeforeBoundary(text, index + 1, softStop)
			) {
				break
			}

			index++
		}

		if (segmentStart === index) break

		raw += text.slice(segmentStart, index)
		sawSegment = true
	}

	if (!sawSegment) return null

	const { path, trailing } = trimCandidateEnd(raw)
	if (!DRIVE_PATH_START.test(path)) return null

	return {
		path,
		trailing,
		end: start + raw.length
	}
}

export function toWslPath(value: string): string {
	const { leading, core, trailing } = splitOuterWhitespace(value)
	if (!DRIVE_PATH_START.test(core)) return value

	const drive = core[0].toLowerCase()
	const rest = core.slice(2).replace(/[\\/]+/g, '/').replace(/^\/+/, '')
	const converted = rest.length > 0 ? `/mnt/${drive}/${rest}` : `/mnt/${drive}`

	return `${leading}${converted}${trailing}`
}

export function replaceWindowsPathsInText(text: string): string {
	let result = ''

	for (let index = 0; index < text.length; ) {
		const candidate = readWindowsPathCandidate(text, index)
		if (!candidate) {
			result += text[index]
			index++
			continue
		}

		result += toWslPath(candidate.path) + candidate.trailing
		index = candidate.end
	}

	return result
}

function patchPathFields(value: unknown): void {
	if (!value || typeof value !== 'object') return

	if (Array.isArray(value)) {
		for (const item of value) {
			patchPathFields(item)
		}
		return
	}

	for (const [key, current] of Object.entries(value as Record<string, unknown>)) {
		if (typeof current === 'string') {
			if (PATH_FIELD_NAMES.has(key)) {
				;(value as Record<string, unknown>)[key] = toWslPath(current)
			}
			continue
		}

		if (Array.isArray(current)) {
			if (PATH_LIST_FIELD_NAMES.has(key)) {
				;(value as Record<string, unknown>)[key] = current.map((item) =>
					typeof item === 'string' ? toWslPath(item) : item
				)
				continue
			}

			for (const item of current) {
				patchPathFields(item)
			}
			continue
		}

		patchPathFields(current)
	}
}

export default function (pi: ExtensionAPI) {
	pi.on('input', async (event) => {
		if (event.source === 'extension') {
			return { action: 'continue' as const }
		}

		const text = replaceWindowsPathsInText(event.text)
		if (text === event.text) {
			return { action: 'continue' as const }
		}

		return {
			action: 'transform' as const,
			text,
			images: event.images
		}
	})

	pi.on('tool_call', async (event) => {
		if (event.toolName === 'bash' && typeof event.input?.command === 'string') {
			event.input.command = replaceWindowsPathsInText(event.input.command)
		}

		patchPathFields(event.input)
	})
}
