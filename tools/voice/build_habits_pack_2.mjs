// Builds the offline "habits 6–20" package from the script files.
//
//   node tools/voice/build_habits_pack_2.mjs <scripts_dir> --dry   parse only, no credit spent
//   $env:ELEVENLABS_API_KEY = '...'                                  (in your own terminal)
//   node tools/voice/build_habits_pack_2.mjs <scripts_dir>          voice + assets
//
// Output:
//   assets/voice/habits/habit_<N>.mp3                one MP3 per habit, bundled in the APK
//   assets/content/habits2_{worlds,missions,stories,questions}.json
//   lib/features/content/data/bundled_habit_audio.g.dart   story id -> asset map

import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';

const VOICES = {
  port: '4RloeZf2FRvGiu4uoKOf',
  mort: 'Vnqlgu3fdiFwisAye1qH',
  fort: 'ihKwLOjVUMG4lgUI6meZ',
  sort: 'hO2yZ8lxM3axUxL8OeKX',
  qort: '1kvnzrSTos1KbmLKMLCC',
};
const TAGS = { بورت: 'port', مورت: 'mort', فورت: 'fort', سورت: 'sort', كورت: 'qort', لورت: 'port' };
const SPOKEN_NAMES = [
  [/PORT/g, 'بورت'],
  [/MORT/g, 'مورت'],
  [/FORT/g, 'فورت'],
  [/SORT/g, 'سورت'],
  [/QORT/g, 'كورت'],
  [/LORT/g, 'لورت'],
];

const SAMPLE_RATE = 22050;
const GAP_SECONDS = 0.25;
const MP3_KBPS = 48;
const CACHE_DIR = 'tools/voice/.audio_cache';

const PREFIX = 'a2000000-0000-4000-8000-';
const WORLD_ID = `${PREFIX}000000000001`;
const pad2 = (n) => String(n).padStart(2, '0');
const missionId = (n) => `${PREFIX}0000000001${pad2(n)}`;
const storyId = (n) => `${PREFIX}0000000002${pad2(n)}`;
const questionId = (n, q) => `${PREFIX}00000003${pad2(n)}0${q}`;

const MOTION_RULES = [
  [/ابْتَسَم|بِابْتِسَامَة/u, 'smile'],
  [/ضَحِك|ضَاحِك/u, 'laugh'],
  [/تَذَكَّر|فَكَّر|فِكْرَة|حِكْمَة/u, 'thinking'],
  [/خَائِف|أَخَاف|تَجَمَّد|قَلَق|مُرْتَبِك|حَزِين/u, 'nervous'],
  [/حَمَاس|مُتَحَمِّس/u, 'excited'],
  [/مُحْتَار|لَا أَعْرِف|مُتَرَدِّد/u, 'confused'],
  [/أَحْسَنْت|هَيَّا|بَرَافُو|رَائِع|مُمْتَاز/u, 'encourage'],
  [/نَجَحْ|احْتَفَل|فَرِح/u, 'winCelebration'],
];
const motionFor = (text) => MOTION_RULES.find(([rx]) => rx.test(text))?.[1] ?? 'talk';

const bare = (s) => s.replace(/[\u064B-\u0652\u0670\u0640]/g, '');

function parseFile(raw) {
  const lines = raw.replace(/\r/g, '').split('\n').map((l) => l.trim());
  const header = lines.find((l) => l.startsWith('📁')) ?? '';
  const num = Number(header.match(/\((\d+)\)/)?.[1]);
  const habit = header.split(/\s+-\s+/).slice(1).join(' - ').trim();

  const titleAt = lines.findIndex((l) => bare(l).startsWith('العنوان'));
  const title = (lines.slice(titleAt + 1).find(Boolean) ?? '').replace(/["«»]/g, '').trim();

  const scriptStart = lines.findIndex((l) => bare(l).includes('السكريبت'));
  const questionsStart = lines.findIndex((l) => bare(l).startsWith('أسئلة'));
  const unknownTags = new Set();
  const dialogue = [];
  for (const line of lines.slice(scriptStart + 1, questionsStart)) {
    const slash = line.lastIndexOf('/');
    if (slash < 0) continue;
    const text = line.slice(0, slash).trim();
    const tag = line.slice(slash + 1).replace(/[^\u0600-\u06FF]/gu, '');
    const characterId = TAGS[tag];
    if (!characterId) unknownTags.add(tag);
    if (text.replace(/["\s]/g, '').length > 1) dialogue.push({ text, characterId: characterId ?? 'port' });
  }

  const questions = [];
  let current = null;
  for (const line of lines.slice(questionsStart + 1)) {
    if (bare(line).startsWith('نهاية')) break;
    if (bare(line).startsWith('السؤال')) {
      current = { text: '', options: [], correct: -1 };
      questions.push(current);
      continue;
    }
    if (!current || current.options.length === 4) continue;
    const option = line.match(/^([A-D])\)\s*(.+)$/);
    if (option) {
      if (option[2].includes('✅')) current.correct = current.options.length;
      current.options.push(option[2].replace(/✅/g, '').trim());
    } else if (line && !/^[=\-─]+$/.test(line) && current.options.length === 0) {
      current.text = current.text ? `${current.text} ${line}` : line;
    }
  }
  return { num, habit, title, dialogue, questions, unknownTags: [...unknownTags] };
}

function spoken(text) {
  let out = text.replace(/["«»]/g, '').replace(/\p{Extended_Pictographic}/gu, '');
  for (const [rx, name] of SPOKEN_NAMES) out = out.replace(rx, name);
  return out.replace(/\s+/g, ' ').trim();
}

async function tts(characterId, text) {
  const clean = spoken(text);
  const key = createHash('md5').update(`${characterId}|${clean}`).digest('hex').slice(0, 16);
  const cachePath = path.join(CACHE_DIR, `p2_${key}.pcm`);
  try {
    const cached = await readFile(cachePath);
    if (cached.length > 512) return cached;
  } catch {}
  for (let attempt = 1; attempt <= 5; attempt++) {
    const res = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${VOICES[characterId]}?output_format=pcm_${SAMPLE_RATE}`,
      {
        method: 'POST',
        headers: { 'xi-api-key': process.env.ELEVENLABS_API_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: clean, model_id: 'eleven_multilingual_v2' }),
      },
    ).catch((error) => ({ ok: false, status: 0, text: async () => String(error) }));
    if (res.ok) {
      const pcm = Buffer.from(await res.arrayBuffer());
      if (pcm.length > 512) {
        await writeFile(cachePath, pcm);
        return pcm;
      }
    }
    const body = res.ok ? 'empty audio' : await res.text();
    if (res.status === 401 || res.status === 402 || /quota|invalid_api_key|paid_plan/i.test(body)) {
      throw new Error(`ElevenLabs ${res.status}: ${body.slice(0, 200)}`);
    }
    if (attempt === 5) throw new Error(`ElevenLabs ${res.status}: ${body.slice(0, 200)}`);
    await new Promise((r) => setTimeout(r, attempt * 2500));
  }
}

async function encodeMp3(pcm) {
  // npm install --prefix tools/voice --no-save @breezystack/lamejs
  const { Mp3Encoder } = await import('@breezystack/lamejs');
  const samples = new Int16Array(pcm.buffer, pcm.byteOffset, Math.floor(pcm.length / 2));
  const encoder = new Mp3Encoder(1, SAMPLE_RATE, MP3_KBPS);
  const chunks = [];
  for (let i = 0; i < samples.length; i += 1152) {
    const frame = encoder.encodeBuffer(samples.subarray(i, i + 1152));
    if (frame.length) chunks.push(Buffer.from(frame));
  }
  chunks.push(Buffer.from(encoder.flush()));
  return Buffer.concat(chunks);
}

async function voiceHabit(habit) {
  const bytesPerSecond = SAMPLE_RATE * 2;
  const gap = Buffer.alloc(Math.round(bytesPerSecond * GAP_SECONDS) & ~1);
  const pcm = [];
  const blocks = [];
  const motionBlocks = [];
  const transitions = [];
  let time = 0;
  for (let i = 0; i < habit.dialogue.length; i++) {
    const { text, characterId } = habit.dialogue[i];
    process.stdout.write(`  habit ${habit.num} line ${i + 1}/${habit.dialogue.length} ${characterId}\r`);
    const clip = await tts(characterId, text);
    const start = Math.round(time * 100) / 100;
    const end = Math.round((time + clip.length / bytesPerSecond) * 100) / 100;
    blocks.push({ characterId, startTime: start, endTime: end });
    motionBlocks.push({ motionId: motionFor(text), startTime: start, endTime: end });
    if (i > 0 && characterId !== habit.dialogue[i - 1].characterId) {
      transitions.push({ time: start, duration: 0.5, type: i % 2 === 0 ? 'slide' : 'pop' });
    }
    pcm.push(clip, gap);
    time = end + GAP_SECONDS;
  }
  const totalDuration = Math.round(time * 100) / 100;
  const mp3 = await encodeMp3(Buffer.concat(pcm));
  const asset = `voice/habits/habit_${habit.num}.mp3`;
  await writeFile(`assets/${asset}`, mp3);
  console.log(`  habit ${habit.num}: ${totalDuration}s, ${(mp3.length / 1048576).toFixed(2)} MB          `);
  return {
    asset,
    timeline: {
      blocks,
      motionBlocks,
      hatBlocks: [],
      glassesBlocks: [],
      musclesBlocks: [],
      jumpBlocks: [],
      transitions,
      totalDuration,
    },
  };
}

async function main() {
  const dir = process.argv[2];
  const dry = process.argv.includes('--dry');
  if (!dir) throw new Error('Usage: node tools/voice/build_habits_pack_2.mjs <scripts_dir> [--dry]');
  if (!dry && !process.env.ELEVENLABS_API_KEY) {
    throw new Error('Set ELEVENLABS_API_KEY in this terminal first.');
  }

  const files = (await readdir(dir)).filter((f) => f.endsWith('.txt'));
  const habits = [];
  for (const file of files) habits.push(parseFile(await readFile(path.join(dir, file), 'utf8')));
  habits.sort((a, b) => a.num - b.num);

  let problems = 0;
  let characters = 0;
  for (const h of habits) {
    const badQuestions = h.questions.filter((q) => q.options.length !== 4 || q.correct < 0 || !q.text);
    characters += h.dialogue.reduce((sum, line) => sum + spoken(line.text).length, 0);
    const speakers = [...new Set(h.dialogue.map((l) => l.characterId))].join(',');
    console.log(
      `habit ${h.num} | ${h.habit} | "${h.title}" | lines ${h.dialogue.length} [${speakers}] | questions ${h.questions.length}` +
        (badQuestions.length ? ` | BAD QUESTIONS ${badQuestions.length}` : '') +
        (h.unknownTags.length ? ` | UNKNOWN TAGS ${h.unknownTags.join(',')}` : ''),
    );
    if (!h.num || !h.title || h.dialogue.length < 5 || h.questions.length !== 5 || badQuestions.length || h.unknownTags.length) {
      problems++;
    }
  }
  console.log(`\n${habits.length} habits, ~${characters} characters of speech, ${problems} with problems`);
  if (problems) throw new Error('Fix the files above before generating voice.');
  if (dry) return;

  await mkdir(CACHE_DIR, { recursive: true });
  const worlds = [
    {
      id: WORLD_ID,
      title: 'عالم العادات الذكية — الجزء الثاني',
      description: 'خمس عشرة عادة جديدة مع بورت ومورت وفورت وسورت وكورت، من ضبط النفس إلى المبادرة.',
      image_url: 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80',
    },
  ];
  const missions = [];
  const stories = [];
  const questions = [];
  const assets = {};
  for (const [index, h] of habits.entries()) {
    const { asset, timeline } = await voiceHabit(h);
    assets[storyId(h.num)] = asset;
    missions.push({
      id: missionId(h.num),
      world_id: WORLD_ID,
      title: `العادة (${h.num}): ${h.habit}`,
      badge_name: `وسام ${h.habit}`,
      stars_reward: 50,
      order_index: index + 1,
    });
    stories.push({
      id: storyId(h.num),
      mission_id: missionId(h.num),
      title: h.title,
      character_name: 'port_frontal.glb',
      content: h.dialogue.map((l) => `${l.text} /${Object.keys(TAGS).find((k) => TAGS[k] === l.characterId)}`).join('\n'),
      image_url: '',
      order_index: 1,
      audio_url: '',
      timeline_data: JSON.stringify(timeline),
    });
    h.questions.forEach((q, i) =>
      questions.push({
        id: questionId(h.num, i + 1),
        mission_id: missionId(h.num),
        question_text: q.text,
        options: q.options,
        correct_answer_index: q.correct,
      }),
    );
  }

  const json = (value) => `${JSON.stringify(value, null, 1)}\n`;
  await writeFile('assets/content/habits2_worlds.json', json(worlds));
  await writeFile('assets/content/habits2_missions.json', json(missions));
  await writeFile('assets/content/habits2_stories.json', json(stories));
  await writeFile('assets/content/habits2_questions.json', json(questions));
  const entries = Object.entries(assets).map(([id, asset]) => `  '${id}': '${asset}',`).join('\n');
  await writeFile(
    'lib/features/content/data/bundled_habit_audio.g.dart',
    `// Generated by tools/voice/build_habits_pack_2.mjs. Do not edit by hand.\n\nconst bundledHabitAudio = <String, String>{\n${entries}\n};\n`,
  );
  console.log('\nDone. Restart the app fully, then open إدارة البكجات.');
}

main().catch((error) => {
  console.error(`\n${error.message}`);
  process.exit(1);
});
