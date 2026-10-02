import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
}

const motions = ['wave', 'happy', 'sad', 'thinking', 'victory', 'walk', 'smile', 'laugh']
const kinds = ['motion', 'jump', 'hat', 'glasses', 'muscles']
const seams = ['fade', 'slide', 'pop']

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }

  const auth = req.headers.get('Authorization') ?? ''
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: auth } } },
  )
  const { data: userData } = await supabase.auth.getUser()
  if (!userData.user) {
    return json({ error: 'signed_out' }, 401)
  }

  const key = (Deno.env.get('GEMINI_API_KEY') || Deno.env.get('Glow') || '').trim()
  if (!key) return json({ error: 'missing_key' }, 500)

  let body: { sentences?: unknown }
  try {
    body = await req.json()
  } catch {
    return json({ error: 'bad_request' }, 400)
  }

  const sentences = Array.isArray(body.sentences) ? body.sentences.slice(0, 80) : []
  const script = sentences.flatMap((item, index) => {
    if (!item || typeof item !== 'object') return []
    const row = item as { character?: unknown; words?: unknown }
    const words = Array.isArray(row.words) ? row.words.slice(0, 80) : []
    const clean = words
      .map((word) => `${word ?? ''}`.trim())
      .filter((word) => word.length > 0 && word.length <= 40)
    if (clean.length === 0) return []
    return [{
      sentence: index,
      character: `${row.character ?? ''}`.slice(0, 40),
      words: clean,
    }]
  })
  if (script.length === 0) return json({ error: 'empty_script' }, 400)

  const model = Deno.env.get('GEMINI_MODEL') || 'gemini-3.8-flash'
  const prompt = [
    'أنت مخرج مونتاج. مر على كل الجمل بالترتيب، ومن كل جملة على كل كلمة. لا تتوقف بعد أول معنى.',
    'كل كلمة تحمل معنى، أو تشبه كلمة تحمل معنى، تأخذ إشارة على تلك الكلمة فقط.',
    'wave للتحية والوداع وما يشبهها: مرحبا، هلا، أهلين، يا هلا، السلام، صباح الخير، مساء الخير، هاي، مرحبتين، مع السلامة، باي.',
    'sad للحزن والخوف والزعل والبكاء وما يشبهها.',
    'laugh للضحك والقهقهة. smile للابتسامة. happy للفرح والحماس.',
    'thinking للسؤال والحيرة: ليش، لماذا، كيف، يا ترى، محتار.',
    'victory للفوز والنجاح. walk للمشي والذهاب والركض.',
    'jump للنطة والقفز والحركة المفاجئة. kind يكون jump والقيمة فاضية.',
    'hat إذا ذُكرت قبعة أو غطاء رأس. glasses إذا ذُكرت نظارة. muscles إذا ذُكرت قوة أو عضلات.',
    'الجملة العادية التي فيها كلام فقط بلا معنى من هذه الأنواع لا تأخذ حركة.',
    'هلا نبدأ تحية wave. هلا درست سؤال thinking.',
    'startWord و endWord فهرسان داخل words من صفر. quote منسوخة كما هي من words.',
    'إذا الجملة فيها أكثر من معنى، أرجع إشارة لكل معنى، لا واحدة فقط.',
    'seams: لكل جملتين متتاليتين بشخصيتين مختلفتين أرجع تأثيراً واحداً fade أو slide أو pop.',
    JSON.stringify(script),
  ].join('\n')

  const requestBody = JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 4096,
          responseMimeType: 'application/json',
          thinkingConfig: { thinkingLevel: 'low' },
          responseSchema: {
            type: 'OBJECT',
            properties: {
              cues: {
                type: 'ARRAY',
                items: {
                  type: 'OBJECT',
                  properties: {
                    sentence: { type: 'INTEGER' },
                    startWord: { type: 'INTEGER' },
                    endWord: { type: 'INTEGER' },
                    quote: { type: 'STRING' },
                    kind: { type: 'STRING', enum: kinds },
                    value: { type: 'STRING' },
                  },
                  required: ['sentence', 'startWord', 'endWord', 'quote', 'kind'],
                },
              },
              seams: {
                type: 'ARRAY',
                items: {
                  type: 'OBJECT',
                  properties: {
                    afterSentence: { type: 'INTEGER' },
                    type: { type: 'STRING', enum: seams },
                  },
                  required: ['afterSentence', 'type'],
                },
              },
            },
            required: ['cues', 'seams'],
          },
        },
      })

  let gemini: Response | null = null
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      gemini = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          signal: AbortSignal.timeout(18000),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': key,
          },
          body: requestBody,
        },
      )
      if (gemini.ok || (gemini.status !== 503 && gemini.status !== 429)) break
    } catch {
      gemini = null
    }
    await new Promise((resolve) => setTimeout(resolve, 900))
  }

  if (!gemini || !gemini.ok) {
    let detail = ''
    try {
      const err = await gemini.json()
      detail = `${err?.error?.status ?? ''} ${err?.error?.message ?? ''}`.trim()
    } catch {
      detail = ''
    }
    return json({ error: 'gemini_failed', detail: detail.slice(0, 160) }, 502)
  }
  const payload = await gemini.json()
  const parts = payload?.candidates?.[0]?.content?.parts ?? []
  const visible = parts
    .filter((part: { thought?: boolean }) => !part.thought)
    .map((part: { text?: string }) => part.text ?? '')
    .join('')
  const text = visible.trim() || parts.map((part: { text?: string }) => part.text ?? '').join('')
  let parsed: { cues?: unknown; seams?: unknown }
  try {
    parsed = readPlan(text)
  } catch {
    return json({ error: 'bad_response' }, 502)
  }

  const cues = Array.isArray(parsed.cues) ? parsed.cues.flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const cue = item as Record<string, unknown>
    let kind = `${cue.kind ?? ''}`.trim()
    let value = `${cue.value ?? ''}`.trim()
    if (motions.includes(kind)) {
      value = kind
      kind = 'motion'
    }
    if (!kinds.includes(kind)) return []
    if (kind === 'motion' && !motions.includes(value)) return []
    const sentence = Number(cue.sentence)
    const startWord = Number(cue.startWord)
    const endWord = Number(cue.endWord)
    if (!Number.isInteger(sentence) || !Number.isInteger(startWord)) return []
    return [{
      sentence,
      startWord,
      endWord: Number.isInteger(endWord) ? endWord : startWord,
      quote: `${cue.quote ?? ''}`.slice(0, 80),
      kind,
      value: kind === 'motion' ? value : '',
    }]
  }).slice(0, 200) : []

  const seamList = Array.isArray(parsed.seams) ? parsed.seams.flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const seam = item as Record<string, unknown>
    const type = `${seam.type ?? ''}`
    const afterSentence = Number(seam.afterSentence)
    if (!seams.includes(type) || !Number.isInteger(afterSentence)) return []
    return [{ afterSentence, type }]
  }).slice(0, 80) : []

  return json({ cues, seams: seamList }, 200)
})

function readPlan(text: string) {
  const start = text.indexOf('{')
  const end = text.lastIndexOf('}')
  if (start < 0 || end <= start) throw new Error('no json')
  return JSON.parse(text.slice(start, end + 1))
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), { status, headers: cors })
}
