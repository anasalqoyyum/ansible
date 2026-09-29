/**
 * Classifier Extension
 *
 * Exposes pi's classifier models as a `classify` tool, so the model can ask
 * typed questions about JSON state without going through codemode. Answers
 * carry probabilities, which the caller thresholds instead of parsing prose.
 *
 * Model choice, in order: the "classifier.model" entry in
 * ~/.pi/agent/settings.json, then the preferred list below, then the first
 * classifier with working credentials. `/classifier` lists what is available
 * and stores the choice. With no credentials at all the tool reports that
 * instead of breaking the session.
 *
 * Inside codemode scripts, `models.classify()` does the same thing and can run
 * four calls at once.
 */

import { Type } from 'typebox'
import {
  getAgentDir,
  type ExtensionAPI,
  type ExtensionContext
} from '@earendil-works/pi-coding-agent'
import type {
  ClassifierApi,
  ClassifierModel,
  ClassifierQuestion,
  ClassifierResult,
  JsonObject,
  JsonValue
} from '@earendil-works/pi-ai'
import { readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

const SETTINGS_KEY = 'classifier'
const MAX_QUESTIONS = 16

/** The state is sent twice per request, so a huge one costs double. */
const MAX_STATE_CHARS = 64_000

/** Tried in order when nothing is configured, so a fresh machine still works. */
const PREFERRED_MODELS = [
  'openrouter/~typesafe/jev-latest',
  'openrouter/typesafe/jev-1.13',
  'typesafe/jev-latest',
  'cloudflare-workers-ai/typesafe/jev',
  'vercel-ai-gateway/typesafe-ai/jev',
  'opencode/jev-1.13'
]

const QuestionSchema = Type.Union([
  Type.Object({
    type: Type.Literal('choice'),
    instructions: Type.String({
      description: 'What to decide, phrased as a question about the state.'
    }),
    criteria: Type.Record(Type.String(), Type.String(), {
      description: 'Option value to what it means. Up to 62 options.'
    })
  }),
  Type.Object({
    type: Type.Literal('score'),
    instructions: Type.String({
      description: 'What to rate, phrased as a question about the state.'
    }),
    criteria: Type.Array(Type.String(), {
      description: 'Rating levels from low to high. Up to 10 levels.'
    })
  }),
  Type.Object({
    type: Type.Literal('bool'),
    instructions: Type.String({
      description: 'What to decide, phrased as a yes or no question about the state.'
    }),
    criteria: Type.Object({
      true: Type.String({ description: 'What the true answer means.' }),
      false: Type.String({ description: 'What the false answer means.' })
    })
  })
])

const ClassifyParams = Type.Object({
  state: Type.Record(Type.String(), Type.Unknown(), {
    description:
      'JSON object the questions are about. Keep it small: it is sent twice per request.'
  }),
  questions: Type.Record(Type.String(), QuestionSchema, {
    description:
      'Question key to question. Keys come back unchanged in the answers.'
  }),
  temperature: Type.Optional(
    Type.Number({
      description:
        'Divides the answer logits before normalizing. Above 1 softens overconfident probabilities. Default 1.3.'
    })
  )
})

const ClassifyOutput = Type.Object({
  model: Type.String(),
  stopReason: Type.String(),
  answers: Type.Record(Type.String(), Type.Unknown()),
  usage: Type.Optional(Type.Unknown())
})

function settingsPath(): string {
  return path.join(getAgentDir(), 'settings.json')
}

function parseModelRef(ref: string): { provider: string; id: string } | undefined {
  const slash = ref.indexOf('/')
  if (slash <= 0 || slash === ref.length - 1) {
    return undefined
  }
  return { provider: ref.slice(0, slash), id: ref.slice(slash + 1) }
}

function readModelBlock(settings: unknown): string | undefined {
  if (typeof settings !== 'object' || settings === null) {
    return undefined
  }
  const block = (settings as Record<string, unknown>)[SETTINGS_KEY]
  if (typeof block !== 'object' || block === null) {
    return undefined
  }
  const model = (block as Record<string, unknown>).model
  return typeof model === 'string' && model.length > 0 ? model : undefined
}

async function readConfiguredModel(): Promise<string | undefined> {
  try {
    return readModelBlock(JSON.parse(await readFile(settingsPath(), 'utf8')))
  } catch {
    return undefined
  }
}

async function writeConfiguredModel(ref: string | undefined): Promise<void> {
  let raw = ''
  try {
    raw = await readFile(settingsPath(), 'utf8')
  } catch (error) {
    // A missing file is normal; anything else is a real failure.
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
      throw error
    }
  }

  let settings: Record<string, unknown> = {}
  if (raw.trim() !== '') {
    // Parse without a catch: a corrupt settings file must be fixed by hand
    // rather than replaced by whatever this extension last wanted to write.
    const parsed: unknown = JSON.parse(raw)
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      throw new Error('settings.json is not a JSON object')
    }
    settings = parsed as Record<string, unknown>
  }

  if (ref) {
    const existing = settings[SETTINGS_KEY]
    const block =
      typeof existing === 'object' && existing !== null && !Array.isArray(existing)
        ? { ...(existing as Record<string, unknown>) }
        : {}
    settings[SETTINGS_KEY] = { ...block, model: ref }
  } else {
    delete settings[SETTINGS_KEY]
  }

  await writeFile(settingsPath(), `${JSON.stringify(settings, null, 2)}\n`, 'utf8')
}

async function resolveClassifier(
  ctx: ExtensionContext
): Promise<ClassifierModel<ClassifierApi> | undefined> {
  const available = await ctx.modelRegistry.getAvailableOfType('classifier')
  if (available.length === 0) {
    return undefined
  }

  const configured = parseModelRef((await readConfiguredModel()) ?? '')
  const candidates = [
    ...(configured ? [configured] : []),
    ...PREFERRED_MODELS.map((ref) => parseModelRef(ref)).filter(
      (parsed): parsed is { provider: string; id: string } => parsed !== undefined
    )
  ]

  for (const candidate of candidates) {
    const hit = available.find(
      (model) => model.provider === candidate.provider && model.id === candidate.id
    )
    if (hit) {
      return hit
    }
  }

  return available[0]
}

function formatAnswers(result: ClassifierResult): string {
  const lines: string[] = []

  for (const [key, answer] of Object.entries(result.answers)) {
    if (answer.type === 'bool') {
      const call = answer.probability >= 0.5 ? 'true' : 'false'
      lines.push(`${key}: ${call} (p ${answer.probability.toFixed(3)})`)
      continue
    }

    if (answer.type === 'choice') {
      const ranked = Object.entries(answer.probabilities)
        .sort((a, b) => b[1] - a[1])
        .map(([option, probability]) => `${option} ${probability.toFixed(3)}`)
        .join(', ')
      lines.push(
        `${key}: ${answer.choice} (confidence ${answer.confidence.toFixed(3)}; ${ranked})`
      )
      continue
    }

    lines.push(`${key}: ${answer.score} (confidence ${answer.confidence.toFixed(3)})`)
  }

  const usage = result.usage
    ? `, ${result.usage.totalTokens} tokens, $${result.usage.cost.total.toFixed(6)}`
    : ''
  lines.push(`model ${result.provider}/${result.model}${usage}`)

  if (result.stopReason !== 'stop') {
    const detail = result.errorMessage ? `: ${result.errorMessage}` : ''
    lines.push(`stopReason ${result.stopReason}${detail}`)
  }

  return lines.join('\n')
}

export default function classifierExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: 'classify',
    label: 'Classify',
    description: [
      'Answer typed questions about a JSON state with a classifier model.',
      'Each question is `choice` with a criteria map of option to meaning, `bool` with `criteria.true` and `criteria.false`, or `score` with a list of levels.',
      'Answers come back with probabilities, so threshold them instead of trusting the top label.',
      'Use this where the check is fuzzy, such as relevance, severity, or intent. Where a test, typecheck, or search can decide, use that instead.'
    ].join(' '),
    promptSnippet: 'Answer typed questions about JSON state with a classifier model',
    promptGuidelines: [
      'Use classify for cheap fuzzy judgments such as relevance, severity, or intent; do not use it where a deterministic check can answer.',
      'Treat classifier probabilities as a ranking, not a calibrated rate, and apply your own threshold.'
    ],
    parameters: ClassifyParams,
    outputSchema: ClassifyOutput,
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const questions = params.questions as Record<string, ClassifierQuestion>
      const keys = Object.keys(questions)

      if (keys.length === 0) {
        throw new Error('classify needs at least one question')
      }
      if (keys.length > MAX_QUESTIONS) {
        throw new Error(
          `classify accepts at most ${MAX_QUESTIONS} questions per call, got ${keys.length}`
        )
      }

      const state = params.state as JsonObject
      const size = JSON.stringify(state).length
      if (size > MAX_STATE_CHARS) {
        throw new Error(
          `state is ${size} characters, over the ${MAX_STATE_CHARS} limit; the state is sent twice per request`
        )
      }

      if (params.temperature !== undefined && params.temperature <= 0) {
        throw new Error('temperature must be greater than 0')
      }

      const model = await resolveClassifier(ctx)
      if (!model) {
        return {
          content: [
            {
              type: 'text' as const,
              text: 'No classifier model has working credentials. Set an API key for typesafe, openrouter, cloudflare-workers-ai, vercel-ai-gateway, or opencode.'
            }
          ],
          structuredContent: {
            model: '',
            stopReason: 'error',
            answers: {}
          },
          isError: true
        }
      }

      const result = await ctx.modelRegistry.classify(
        model,
        { state, questions },
        { signal, temperature: params.temperature ?? 1.3 }
      )

      return {
        content: [{ type: 'text' as const, text: formatAnswers(result) }],
        structuredContent: {
          model: `${result.provider}/${result.model}`,
          stopReason: result.stopReason,
          answers: result.answers as unknown as JsonValue,
          ...(result.usage ? { usage: result.usage as unknown as JsonValue } : {})
        },
        isError: result.stopReason !== 'stop'
      }
    }
  })

  pi.registerCommand('classifier', {
    description: 'Show or change the classifier model used by the classify tool',
    getArgumentCompletions: () => [
      { value: 'clear', label: 'clear', description: 'use the preferred default' }
    ],
    handler: async (args, ctx) => {
      const available = await ctx.modelRegistry.getAvailableOfType('classifier')
      if (available.length === 0) {
        ctx.ui.notify(
          'No classifier model has working credentials. Set an API key for typesafe, openrouter, cloudflare-workers-ai, vercel-ai-gateway, or opencode.',
          'warning'
        )
        return
      }

      const refs = available.map((model) => `${model.provider}/${model.id}`)
      const argument = args.trim()

      if (argument === 'clear') {
        try {
          await writeConfiguredModel(undefined)
        } catch (error) {
          ctx.ui.notify(`Could not update settings.json: ${error instanceof Error ? error.message : String(error)}`, 'error')
          return
        }
        ctx.ui.notify('Classifier model cleared, using the preferred default.', 'info')
        return
      }

      if (argument) {
        if (!refs.includes(argument)) {
          ctx.ui.notify(
            `Unknown classifier model "${argument}". Run /classifier to pick one.`,
            'error'
          )
          return
        }
        try {
          await writeConfiguredModel(argument)
        } catch (error) {
          ctx.ui.notify(`Could not update settings.json: ${error instanceof Error ? error.message : String(error)}`, 'error')
          return
        }
        ctx.ui.notify(`Classifier model set to ${argument}`, 'info')
        return
      }

      const configured = await readConfiguredModel()
      if (!ctx.hasUI) {
        const suffix = configured ? ` (configured: ${configured})` : ''
        ctx.ui.notify(`Classifiers: ${refs.join(', ')}${suffix}`, 'info')
        return
      }

      const choice = await ctx.ui.select('Classifier model', refs)
      if (!choice) {
        return
      }

      try {
        await writeConfiguredModel(choice)
      } catch (error) {
        ctx.ui.notify(`Could not update settings.json: ${error instanceof Error ? error.message : String(error)}`, 'error')
        return
      }
      ctx.ui.notify(`Classifier model set to ${choice}`, 'info')
    }
  })
}
