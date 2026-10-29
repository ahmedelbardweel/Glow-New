// ============================================================
// new_habit_full_pipeline.mjs
// ============================================================
// USAGE: node tools/voice/new_habit_full_pipeline.mjs <story_txt_file>
//
// Full end-to-end pipeline:
//   1. Parse the story .txt file (script + questions)
//   2. Generate voice per character via ElevenLabs TTS
//   3. Merge all PCM chunks → single WAV
//   4. Upload WAV to Supabase Storage (story_audio bucket)
//   5. Patch the stories table (audio_url + timeline_data)
//   6. Upsert world / mission / questions into DB
//   7. Write a backup SQL file for reference
// ============================================================

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';

// ─────────────────────────────────────────────
// CONFIG — edit these IDs/keys if needed
// ─────────────────────────────────────────────
const ELEVEN_API_KEY = process.env.ELEVENLABS_API_KEY;

// ElevenLabs voice IDs per character
const ELEVEN_VOICES = {
  port: '4RloeZf2FRvGiu4uoKOf', // بورت  (blue hero)
  mort: 'Vnqlgu3fdiFwisAye1qH', // مورت  (pink)
  fort: 'ihKwLOjVUMG4lgUI6meZ', // فورت  (orange)
  sort: 'hO2yZ8lxM3axUxL8OeKX', // سورت  (yellow)
  qort: '1kvnzrSTos1KbmLKMLCC', // كورت  (green)
};

const SUPABASE_URL = 'https://sqvbbsqmwktxuapwivnk.supabase.co';
const SUPABASE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0eHVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEaOnI';

// Stable IDs — tweak for different habits / worlds
const STORY_CONFIG = {
  worldId: 'a1000000-0000-4000-8000-000000000001',
  worldTitle: 'عالم العادات الذكية للأبطال',
  worldDescription:
    'رحلة ممتعة وتفاعلية مع الأصدقاء بورت، مورت، فورت، سورت، وكورت لاكتساب العادات الخمس الأساسية لبناء شخصية قوية وواثقة.',

  missionId: 'a1000000-0000-4000-8000-000000000011',
  missionTitle: 'العادة (1): القدرة على قول "لا"',
  missionBadge: 'درع الشجاعة والأمان',
  missionStars: 50,
  missionOrder: 1,

  storyId: 'a1000000-0000-4000-8000-000000000021',
  storyTitle: 'سَأَقُولُ (لَا) لِمَا قَدْ يُؤْذِينِي',
  habitNum: 1,

  // Question IDs  (habit 1 → q31..q35 range)
  questionIds: [
    'a1000000-0000-4000-8000-000000000031',
    'a1000000-0000-4000-8000-000000000032',
    'a1000000-0000-4000-8000-000000000033',
    'a1000000-0000-4000-8000-000000000034',
    'a1000000-0000-4000-8000-000000000035',
  ],
};

// ─────────────────────────────────────────────
// ARABIC-to-character mapping
// ─────────────────────────────────────────────
const CHAR_MAP = {
  بورت: 'port',
  فورت: 'fort',
  مورت: 'mort',
  سورت: 'sort',
  كورت: 'qort',
  لورت: 'port', // fallback
};

// ─────────────────────────────────────────────
// CACHE DIR
// ─────────────────────────────────────────────
const CACHE_DIR = 'tools/voice/.audio_cache';
await mkdir(CACHE_DIR, { recursive: true });

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────
function hashText(text) {
  return createHash('md5').update(text).digest('hex').slice(0, 12);
}

function createWavHeader(pcmLength, sampleRate = 22050) {
  const h = Buffer.alloc(44);
  h.write('RIFF', 0);
  h.writeUInt32LE(36 + pcmLength, 4);
  h.write('WAVE', 8);
  h.write('fmt ', 12);
  h.writeUInt32LE(16, 16);
  h.writeUInt16LE(1, 20);   // PCM
  h.writeUInt16LE(1, 22);   // Mono
  h.writeUInt32LE(sampleRate, 24);
  h.writeUInt32LE(sampleRate * 2, 28);
  h.writeUInt16LE(2, 32);
  h.writeUInt16LE(16, 34);
  h.write('data', 36);
  h.writeUInt32LE(pcmLength, 40);
  return h;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// ─────────────────────────────────────────────
// TTS: ElevenLabs → PCM  (with cache + retry)
// ─────────────────────────────────────────────
async function fetchPCM(characterId, text) {
  const clean = text.replace(/\s+/g, ' ').trim();
  const cacheKey = `${characterId}_${hashText(clean)}.pcm`;
  const cachePath = path.join(CACHE_DIR, cacheKey);

  try {
    const cached = await readFile(cachePath);
    if (cached.length > 512) {
      process.stdout.write(' [cache]');
      return cached;
    }
  } catch (_) { /* not cached */ }

  const voiceId = ELEVEN_VOICES[characterId] || ELEVEN_VOICES.port;

  for (let attempt = 1; attempt <= 5; attempt++) {
    try {
      const res = await fetch(
        `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=pcm_22050`,
        {
          method: 'POST',
          headers: {
            'xi-api-key': ELEVEN_API_KEY,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            text: clean,
            model_id: 'eleven_multilingual_v2',
            voice_settings: {
              stability: 0.5,
              similarity_boost: 0.8,
              style: 0.3,
              use_speaker_boost: true,
            },
          }),
        },
      );

      if (res.status === 429) {
        console.warn(`\n    ⚠️  Rate limit 429 – waiting ${attempt * 3}s...`);
        await sleep(attempt * 3000);
        continue;
      }

      if (!res.ok) {
        const err = await res.text();
        throw new Error(`ElevenLabs ${res.status}: ${err.slice(0, 200)}`);
      }

      const pcm = Buffer.from(await res.arrayBuffer());
      if (pcm.length > 100) {
        await writeFile(cachePath, pcm);
        return pcm;
      }
      throw new Error('Empty PCM response');
    } catch (e) {
      if (attempt === 5) throw e;
      console.warn(`\n    ⚠️  Attempt ${attempt} failed: ${e.message}. Retrying...`);
      await sleep(attempt * 2000);
    }
  }

  throw new Error(`Failed to generate PCM for: "${clean.slice(0, 40)}"`);
}

// ─────────────────────────────────────────────
// SUPABASE STORAGE UPLOAD
// ─────────────────────────────────────────────
async function uploadWav(fileName, buffer) {
  console.log(`\n📤 Uploading ${fileName} (${(buffer.length / 1024 / 1024).toFixed(2)} MB)...`);
  const res = await fetch(`${SUPABASE_URL}/storage/v1/object/story_audio/${fileName}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'audio/wav',
      'x-upsert': 'true',
    },
    body: buffer,
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Storage upload failed (${res.status}): ${err}`);
  }
  const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/story_audio/${fileName}`;
  console.log(`✅ Uploaded → ${publicUrl}`);
  return publicUrl;
}

// ─────────────────────────────────────────────
// SUPABASE DB: PATCH / UPSERT
// ─────────────────────────────────────────────
async function supabasePatch(table, filter, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${filter}`, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    body: JSON.stringify(data),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`PATCH ${table} error ${res.status}: ${body.slice(0, 300)}`);
  return JSON.parse(body);
}

async function supabaseUpsert(table, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'resolution=merge-duplicates,return=representation',
    },
    body: JSON.stringify(data),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`UPSERT ${table} error ${res.status}: ${body.slice(0, 300)}`);
  return JSON.parse(body);
}

// ─────────────────────────────────────────────
// MOTION DETECTION  (rule-based)
// ─────────────────────────────────────────────
const MOTION_RULES = [
  [/ابْتَسَمَ|ابْتَسَمَتْ|ابْتَسَمْتُ|ابتسم|بِابْتِسَامَة/u, 'smile'],
  [/ضَحِكَ|ضَحِكَتْ|ضَحِكْتُ|ضَاحِكًا|ضَاحِكَةً/u, 'laugh'],
  [/تَذَكَّرَ|تَذَكَّرْتُ|تَفَكَّرَ|تَفَكَّرْتُ|فَكَّرَ|فِكْرَة|حِكْمَة/u, 'thinking'],
  [/خَائِف|أَخَاف|تَجَمَّدَ|يَخْفِقُ|قَلَقِ|مُرْتَبِك/u, 'nervous'],
  [/حَمَاسًا|بِحَمَاسٍ|حَمَاس|انْطَلَقَ بِسُرْعَة/u, 'excited'],
  [/مُحْتَار|أَيَّ طَرِيق|لَا أَعْرِف|أَيَّةُ خُطْوَة|مُتَرَدِّد/u, 'confused'],
  [/شَجَّعَ|أَحْسَنْتَ|هَيَّا|بَرَافُو|رَائِعٌ|عَظِيم|صَحِيح|مُمْتَاز/u, 'encourage'],
  [/انْتَصَرَ|فَرِحَ|احْتَفَلَ|وَفَعَلَ|نَجَحَ|نَجَحْتُ/u, 'winCelebration'],
];

function detectMotion(text) {
  for (const [rx, motionId] of MOTION_RULES) {
    if (rx.test(text)) return motionId;
  }
  return 'talk';
}

// ─────────────────────────────────────────────
// PARSE STORY FILE
// ─────────────────────────────────────────────
function parseStoryFile(raw) {
  const lines = raw.split('\n').map((l) => l.trim()).filter(Boolean);

  const dialogueLines = [];   // {text, characterId}
  const questions = [];       // {q, opts: [{text, correct}]}

  let inQuestions = false;
  let currentQ = null;

  for (const line of lines) {
    // ── Skip decorative headers / separators ──
    if (/^[=─═━]+$/.test(line)) continue;
    if (line.startsWith('📁') || line.startsWith('🌟') || line.startsWith('⭐') || line.startsWith('🎙')) continue;

    // ── Detect transition into questions section ──
    if (!inQuestions && (
      line.startsWith('أَسْئِلَةُ') ||
      line.startsWith('الْعَادَةُ') ||
      line.match(/^السُّؤَالُ/) ||
      line.match(/^السؤال/)
    )) {
      inQuestions = true;
      // If this line itself is a question header, start a question
      if (line.match(/^السُّؤَالُ|^السؤال/)) {
        if (currentQ && currentQ.q) questions.push(currentQ);
        currentQ = { q: '', opts: [] };
      }
      continue;
    }

    // ─── STORY SECTION ───
    if (!inQuestions) {
      if (!line.includes('/')) continue;  // no tag → skip
      const slashIdx = line.lastIndexOf('/');
      const text = line.slice(0, slashIdx).replace(/"/g, '').trim();
      const tag = line.slice(slashIdx + 1).replace(/[💙💚🧡💛💜\s]/gu, '').trim();
      const charId = CHAR_MAP[tag] || 'port';
      if (text.length > 1) dialogueLines.push({ text, characterId: charId });
      continue;
    }

    // ─── QUESTIONS SECTION ───

    // New question header
    if (line.match(/^السُّؤَالُ|^السؤال/)) {
      if (currentQ && currentQ.q) questions.push(currentQ);
      currentQ = { q: '', opts: [] };
      continue;
    }

    // Skip feedback blocks  (✅/❌ explanations after options)
    if (
      line.startsWith('✅') || line.startsWith('❌') || line.startsWith('🎉') ||
      line.startsWith('---') || line.startsWith('─')
    ) continue;

    if (currentQ) {
      // Options:  "A) text ✅"  or  "A) text"
      const optMatch = line.match(/^([A-D])\)\s*(.+)/);
      if (optMatch) {
        const optText = optMatch[2].replace(/✅/g, '').trim();
        const correct = line.includes('✅');
        currentQ.opts.push({ text: optText, correct });
        continue;
      }

      // Question text (accumulate until we see first option)
      if (currentQ.opts.length === 0 && line.length > 3) {
        currentQ.q = currentQ.q ? currentQ.q + ' ' + line : line;
      }
    }
  }
  if (currentQ && currentQ.q) questions.push(currentQ);

  return { dialogueLines, questions };
}

// ─────────────────────────────────────────────
// GENERATE AUDIO  for all dialogue lines
// ─────────────────────────────────────────────
async function generateAudio(dialogueLines, habitNum) {
  const SILENCE_BETWEEN = 0.25; // seconds between sentences
  const bytesPerSec = 22050 * 2; // 22050 samples/s × 2 bytes/sample (16-bit mono)
  const silenceBytes = Math.round(bytesPerSec * SILENCE_BETWEEN);
  const silence = Buffer.alloc(silenceBytes);

  const pcmChunks = [];
  const blocks = [];
  const motionBlocks = [];
  const transitions = [];
  let currentTime = 0.0;

  console.log(`\n🎙️  Generating voice for ${dialogueLines.length} lines...\n`);

  for (let i = 0; i < dialogueLines.length; i++) {
    const { text, characterId } = dialogueLines[i];
    process.stdout.write(
      `  [${i + 1}/${dialogueLines.length}] ${characterId.padEnd(5)} | "${text.slice(0, 45)}${text.length > 45 ? '…' : ''}" `,
    );

    const pcm = await fetchPCM(characterId, text);
    const lineDuration = pcm.length / bytesPerSec;
    const start = Math.round(currentTime * 100) / 100;
    const end = Math.round((currentTime + lineDuration) * 100) / 100;
    console.log(`→ ${lineDuration.toFixed(2)}s  [${start}–${end}]`);

    blocks.push({ characterId, startTime: start, endTime: end });
    motionBlocks.push({ motionId: detectMotion(text), startTime: start, endTime: end });

    // Add transition if character changed
    if (i > 0 && dialogueLines[i].characterId !== dialogueLines[i - 1].characterId) {
      transitions.push({ time: start, duration: 0.5, type: i % 2 === 0 ? 'slide' : 'pop' });
    }

    pcmChunks.push(pcm);
    pcmChunks.push(silence);
    currentTime = end + SILENCE_BETWEEN;

    // Polite delay between API calls
    await sleep(400);
  }

  const allPcm = Buffer.concat(pcmChunks);
  const wavHeader = createWavHeader(allPcm.length, 22050);
  const fullWav = Buffer.concat([wavHeader, allPcm]);
  const totalDuration = Math.round(currentTime * 100) / 100;

  return {
    wavBuffer: fullWav,
    timelineData: {
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

// ─────────────────────────────────────────────
// UPSERT WORLD + MISSION + STORY + QUESTIONS
// ─────────────────────────────────────────────
async function seedDatabase(audioUrl, timelineData, questions) {
  const cfg = STORY_CONFIG;

  // NOTE: world & mission already exist from habits_seed.sql
  // Anon key cannot INSERT due to RLS — skip those upserts.
  console.log('  ℹ️  World & Mission already exist — skipping (RLS-protected).');

  // 1. Story — PATCH existing row (works with anon key)
  console.log('📦 Patching Story audio_url + timeline_data...');
  const patchRes = await supabasePatch(
    'stories',
    `id=eq.${cfg.storyId}`,
    { audio_url: audioUrl, timeline_data: timelineData },
  );
  if (patchRes.length === 0) {
    // Story row might not exist yet — try upsert
    console.log('  ℹ️  Story not found via PATCH, attempting upsert...');
    await supabaseUpsert('stories', {
      id: cfg.storyId,
      mission_id: cfg.missionId,
      title: cfg.storyTitle,
      audio_url: audioUrl,
      timeline_data: timelineData,
      created_at: new Date().toISOString(),
    });
  }
  console.log(`  ✅ Story updated  (audio: ${audioUrl.split('/').pop()})`);

  // 2. Questions — try upsert, fall back to SQL generation
  if (questions.length > 0) {
    console.log(`📦 Upserting ${questions.length} Questions...`);
    let qFailed = false;
    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      if (!q || !q.q || !q.opts || q.opts.length < 4) {
        console.warn(`  ⚠️  Question ${i + 1} malformed – skipping`);
        continue;
      }
      const correctIdx = q.opts.findIndex((o) => o.correct);
      const qId = cfg.questionIds[i] || `a1000000-0000-4000-8000-a${String(i).padStart(10, '0')}`;
      try {
        await supabaseUpsert('questions', {
          id: qId,
          mission_id: cfg.missionId,
          question_text: q.q.trim(),
          options: q.opts.map((o) => o.text),
          correct_answer_index: correctIdx >= 0 ? correctIdx : 0,
          created_at: new Date().toISOString(),
        });
        console.log(`  ✅ Q${i + 1}: "${q.q.slice(0, 50)}" (correct: ${correctIdx})`);
      } catch (e) {
        console.warn(`  ⚠️  Q${i + 1} upsert failed: ${e.message.slice(0, 80)} — will write to SQL file`);
        qFailed = true;
      }
    }
    if (qFailed) {
      console.log('  ℹ️  Some questions need manual SQL — see backup SQL file.');
    }
  } else {
    console.log('  ⚠️  No questions parsed — check backup SQL for manual entry.');
  }
}

// ─────────────────────────────────────────────
// WRITE BACKUP SQL
// ─────────────────────────────────────────────
async function writeBackupSql(audioUrl, timelineData, questions) {
  const cfg = STORY_CONFIG;
  const tl = JSON.stringify(timelineData).replace(/'/g, "''");
  const ts = new Date().toISOString();

  let sql = `-- =========================================================\n`;
  sql += `-- BACKUP SQL: ${cfg.missionTitle}\n`;
  sql += `-- Generated: ${ts}\n`;
  sql += `-- =========================================================\n\n`;

  sql += `-- World\n`;
  sql += `INSERT INTO worlds (id, title, description, created_at)\n`;
  sql += `VALUES ('${cfg.worldId}', '${cfg.worldTitle}', '${cfg.worldDescription}', NOW())\n`;
  sql += `ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title;\n\n`;

  sql += `-- Mission\n`;
  sql += `INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at)\n`;
  sql += `VALUES ('${cfg.missionId}', '${cfg.worldId}', '${cfg.missionTitle}', '${cfg.missionBadge}', ${cfg.missionStars}, ${cfg.missionOrder}, NOW())\n`;
  sql += `ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title;\n\n`;

  sql += `-- Story\n`;
  sql += `UPDATE stories SET\n`;
  sql += `  audio_url = '${audioUrl}',\n`;
  sql += `  timeline_data = '${tl}'\n`;
  sql += `WHERE id = '${cfg.storyId}';\n\n`;

  sql += `-- Questions\n`;
  for (let i = 0; i < questions.length; i++) {
    const q = questions[i];
    if (!q || !q.q || !q.opts || q.opts.length < 4) continue;
    const correctIdx = q.opts.findIndex((o) => o.correct);
    const qId = cfg.questionIds[i];
    const optsJson = JSON.stringify(q.opts.map((o) => o.text)).replace(/'/g, "''");
    sql += `INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)\n`;
    sql += `VALUES ('${qId}', '${cfg.missionId}', '${q.q.replace(/'/g, "''")}', '${optsJson}'::jsonb, ${correctIdx >= 0 ? correctIdx : 0}, NOW())\n`;
    sql += `ON CONFLICT (id) DO UPDATE SET question_text = EXCLUDED.question_text, options = EXCLUDED.options, correct_answer_index = EXCLUDED.correct_answer_index;\n\n`;
  }

  const outPath = `supabase/habit_${cfg.habitNum}_backup.sql`;
  await writeFile(outPath, sql, 'utf8');
  console.log(`\n💾 Backup SQL saved → ${outPath}`);
}

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────
async function main() {
  if (!ELEVEN_API_KEY) {
    throw new Error('ELEVENLABS_API_KEY is required to generate a new habit.');
  }
  const inputFile = process.argv[2];
  if (!inputFile) {
    console.error('Usage: node tools/voice/new_habit_full_pipeline.mjs <path-to-story.txt>');
    process.exit(1);
  }

  console.log('═══════════════════════════════════════════════════');
  console.log('  GLOW APP — Full Habit Story Pipeline');
  console.log(`  Input: ${inputFile}`);
  console.log('═══════════════════════════════════════════════════\n');

  // ── STEP 1: Parse ──────────────────────────
  console.log('📖 Step 1: Parsing story file...');
  const raw = await readFile(inputFile, 'utf8');
  const { dialogueLines, questions } = parseStoryFile(raw);
  console.log(`  Found ${dialogueLines.length} dialogue lines`);
  console.log(`  Found ${questions.length} questions`);
  if (dialogueLines.length === 0) {
    console.error('❌ No dialogue lines parsed. Check the file format.');
    process.exit(1);
  }

  console.log('\n  Dialogue preview (first 5):');
  dialogueLines.slice(0, 5).forEach((l, i) => {
    console.log(`    ${i + 1}. [${l.characterId}] "${l.text.slice(0, 60)}"`);
  });

  console.log('\n  Questions preview:');
  questions.slice(0, 3).forEach((q, i) => {
    console.log(`    Q${i + 1}: "${q?.q?.slice(0, 60)}"`);
    q?.opts?.forEach((o, j) => console.log(`         ${String.fromCharCode(65 + j)}) ${o.text.slice(0, 50)} ${o.correct ? '✅' : ''}`));
  });

  // ── STEP 2: Generate Audio ─────────────────
  console.log('\n🎙️  Step 2: Generating audio via ElevenLabs...');
  const { wavBuffer, timelineData } = await generateAudio(dialogueLines, STORY_CONFIG.habitNum);
  console.log(`\n  Total duration: ${timelineData.totalDuration}s`);
  console.log(`  WAV size: ${(wavBuffer.length / 1024 / 1024).toFixed(2)} MB`);

  // ── STEP 3: Upload WAV ─────────────────────
  console.log('\n📤 Step 3: Uploading WAV to Supabase Storage...');
  const fileName = `habit_${STORY_CONFIG.habitNum}_new_${Date.now()}.wav`;
  const audioUrl = await uploadWav(fileName, wavBuffer);

  // ── STEP 4: Seed Database ──────────────────
  console.log('\n🗄️  Step 4: Seeding Supabase database...');
  await seedDatabase(audioUrl, timelineData, questions);

  // ── STEP 5: Backup SQL ─────────────────────
  console.log('\n💾 Step 5: Writing backup SQL...');
  await writeBackupSql(audioUrl, timelineData, questions);

  // ── DONE ───────────────────────────────────
  console.log('\n');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║  🎉  PIPELINE COMPLETE — ALL STEPS DONE!         ║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log(`║  Story ID   : ${STORY_CONFIG.storyId}  ║`);
  console.log(`║  Audio URL  : .../${fileName}  ║`);
  console.log(`║  Duration   : ${timelineData.totalDuration}s                               ║`);
  console.log(`║  Blocks     : ${timelineData.blocks.length} character blocks                     ║`);
  console.log(`║  Questions  : ${questions.length} questions seeded                    ║`);
  console.log('╚══════════════════════════════════════════════════╝\n');
}

main().catch((e) => {
  console.error('\n❌ Pipeline error:', e.message);
  console.error(e.stack);
  process.exit(1);
});
