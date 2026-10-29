// tools/voice/generate_habits_audio.mjs
// Full audio generator for the 5 habits using ElevenLabs + Supabase Storage upload
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';

const ELEVEN_VOICES = {
  port: '4RloeZf2FRvGiu4uoKOf', // بورت
  mort: 'Vnqlgu3fdiFwisAye1qH', // مورت
  fort: 'ihKwLOjVUMG4lgUI6meZ', // فورت
  sort: 'hO2yZ8lxM3axUxL8OeKX', // سورت
  qort: '1kvnzrSTos1KbmLKMLCC', // كورت
  narrator: 'Bsa1HP3wF8JGRzGouFEa', // جوليا
};

const ELEVEN_API_KEY = process.env.ELEVENLABS_API_KEY;

const SUPABASE_URL = 'https://sqvbbsqmwktxuapwivnk.supabase.co';
const SUPABASE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0eHVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEaOnI';

const CACHE_DIR = 'tools/voice/.audio_cache';
await mkdir(CACHE_DIR, { recursive: true });

function createWavHeader(pcmLength, sampleRate = 22050) {
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + pcmLength, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM format
  header.writeUInt16LE(1, 22); // Mono
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(sampleRate * 2, 28); // Byte rate (22050 * 2)
  header.writeUInt16LE(2, 32); // Block align (16-bit mono = 2)
  header.writeUInt16LE(16, 34); // Bits per sample
  header.write('data', 36);
  header.writeUInt32LE(pcmLength, 40);
  return header;
}

function hashText(text) {
  return createHash('md5').update(text).digest('hex').slice(0, 10);
}

async function fetchPCM(characterId, text) {
  const clean = text.replace(/[/][^\s]+/g, '').trim();
  const fileKey = `${characterId}_${hashText(clean)}.pcm`;
  const cachePath = path.join(CACHE_DIR, fileKey);

  try {
    const cached = await readFile(cachePath);
    if (cached.length > 512) {
      return cached;
    }
  } catch (_) { }

  const voiceId = ELEVEN_VOICES[characterId] || ELEVEN_VOICES.qort;

  for (let attempt = 1; attempt <= 4; attempt++) {
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
          }),
        },
      );

      if (res.status === 429) {
        console.warn(`[Rate limit 429] Waiting ${attempt * 2}s for attempt ${attempt}...`);
        await new Promise((resolve) => setTimeout(resolve, attempt * 2000));
        continue;
      }

      if (!res.ok) {
        const errText = await res.text();
        throw new Error(`TTS HTTP ${res.status}: ${errText}`);
      }

      const pcm = Buffer.from(await res.arrayBuffer());
      if (pcm.length > 100) {
        await writeFile(cachePath, pcm);
        return pcm;
      }
    } catch (e) {
      if (attempt === 4) throw e;
      await new Promise((resolve) => setTimeout(resolve, attempt * 1500));
    }
  }

  throw new Error(`Failed to generate PCM after 4 attempts for: ${clean}`);
}

async function uploadToSupabaseStorage(fileName, buffer, contentType = 'audio/wav') {
  console.log(`Uploading ${fileName} (${(buffer.length / 1024 / 1024).toFixed(2)} MB) to Supabase Storage...`);
  const res = await fetch(`${SUPABASE_URL}/storage/v1/object/story_audio/${fileName}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': contentType,
      'x-upsert': 'true',
    },
    body: buffer,
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Storage upload failed (${res.status}): ${err}`);
  }

  return `${SUPABASE_URL}/storage/v1/object/public/story_audio/${fileName}`;
}

export async function processHabitStory(habitNum, storyId, rawScript) {
  const charMap = {
    'بورت': 'port',
    'فورت': 'fort',
    'مورت': 'mort',
    'سورت': 'sort',
    'كورت': 'qort',
    'لورت': 'lort',
  };

  const lines = [];
  for (const raw of rawScript.split('\n')) {
    const trimmed = raw.trim();
    if (!trimmed) continue;
    const slashIdx = trimmed.lastIndexOf('/');
    if (slashIdx === -1) {
      lines.push({ text: trimmed, characterId: 'port' });
      continue;
    }
    const text = trimmed.slice(0, slashIdx).trim();
    const tag = trimmed.slice(slashIdx + 1).trim();
    const cleanTag = tag.replace(/^[.،,!؟:\s]+|[.،,!؟:\s]+$/g, '');
    const charId = charMap[cleanTag] || 'port';
    lines.push({ text, characterId: charId });
  }

  console.log(`\n========================================`);
  console.log(`[Habit ${habitNum}] Processing ${lines.length} dialogue lines...`);

  const pcmChunks = [];
  const blocks = [];
  const motionBlocks = [];
  const transitions = [];
  let currentTime = 0.0;

  // 0.25 second silence between sentences (22050 samples/s * 2 bytes/sample * 0.25s = 11024 bytes)
  const silence = Buffer.alloc(11024);

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    process.stdout.write(` [Habit ${habitNum}] Line ${i + 1}/${lines.length} (${line.characterId}): "${line.text.slice(0, 30)}..." `);
    const pcm = await fetchPCM(line.characterId, line.text);
    const lineDuration = Math.round((pcm.length / 44100) * 100) / 100;
    console.log(`-> ${lineDuration}s`);

    const start = Math.round(currentTime * 100) / 100;
    const end = Math.round((currentTime + lineDuration) * 100) / 100;

    blocks.push({
      characterId: line.characterId,
      startTime: start,
      endTime: end,
    });

    let motionId = 'talk';
    const text = line.text;
    if (text.includes('متحمس') || text.includes('حماس') || text.includes('قَفَزَ')) {
      motionId = 'excited';
    } else if (text.includes('فخور') || text.includes('فَخْرٍ') || text.includes('بَرَافُو')) {
      motionId = 'winCelebration';
    } else if (text.includes('ابْتَسَمَ') || text.includes('ابْتَسَمْتُ') || text.includes('أَثِقُ بِكَ')) {
      motionId = 'smile';
    } else if (text.includes('ضَحِكَ') || text.includes('ضَاحِكًا')) {
      motionId = 'laugh';
    } else if (text.includes('تَذَكَّرْ') || text.includes('حِكْمَة') || text.includes('تَفْكِير')) {
      motionId = 'thinking';
    } else if (text.includes('خَائِف') || text.includes('تَجَمَّدْتُ') || text.includes('يَخْفِقُ')) {
      motionId = 'nervous';
    } else if (text.includes('مُحْتَار') || text.includes('أَيَّ طَرِيقٍ')) {
      motionId = 'confused';
    } else if (text.includes('شَجَّعَ') || text.includes('أَحْسَنْتَ') || text.includes('هَيَّا')) {
      motionId = 'encourage';
    }

    motionBlocks.push({
      motionId,
      startTime: start,
      endTime: end,
    });

    if (i > 0 && lines[i].characterId !== lines[i - 1].characterId) {
      transitions.push({
        time: start,
        duration: 0.5,
        type: i % 2 === 0 ? 'slide' : 'pop',
      });
    }

    pcmChunks.push(pcm);
    pcmChunks.push(silence);
    currentTime = end + 0.25;

    // Small delay between calls to be gentle on ElevenLabs rate limits
    await new Promise((r) => setTimeout(r, 350));
  }

  const allPcm = Buffer.concat(pcmChunks);
  const wavHeader = createWavHeader(allPcm.length, 22050);
  const fullWav = Buffer.concat([wavHeader, allPcm]);
  const totalDuration = Math.round(currentTime * 100) / 100;

  const fileName = `habit_${habitNum}_voice_${Date.now()}.wav`;
  const publicAudioUrl = await uploadToSupabaseStorage(fileName, fullWav);

  const timelineData = {
    blocks,
    motionBlocks,
    hatBlocks: [],
    glassesBlocks: [],
    musclesBlocks: [],
    jumpBlocks: [],
    transitions,
    totalDuration,
  };

  return {
    storyId,
    habitNum,
    publicAudioUrl,
    timelineData,
  };
}

async function run() {
  if (!ELEVEN_API_KEY) {
    throw new Error('ELEVENLABS_API_KEY is required to generate new habit audio.');
  }
  console.log('🚀 Starting voice generation for the 5 habits with ElevenLabs...');
  const seedSrc = await readFile('tools/voice/generate_habits_seed.mjs', 'utf8');

  // Extract scripts
  const scriptRegex = /num:\s*([1-5]),[\s\S]*?storyTitle:\s*'([^']+)'[\s\S]*?script:\s*`([^`]+)`/g;
  let match;
  const habits = [];
  while ((match = scriptRegex.exec(seedSrc)) !== null) {
    habits.push({
      num: parseInt(match[1]),
      storyTitle: match[2],
      script: match[3],
      storyId: `a1000000-0000-4000-8000-00000000002${match[1]}`,
    });
  }

  console.log(`Loaded ${habits.length} habits stories.`);

  const results = [];
  for (const h of habits) {
    const res = await processHabitStory(h.num, h.storyId, h.script);
    results.push(res);
  }

  // Generate update SQL
  let updateSql = `-- =========================================================================\n`;
  updateSql += `-- Update Stories Audio & Exact Timeline for the 5 Habits\n`;
  updateSql += `-- =========================================================================\n\n`;

  for (const r of results) {
    const timelineJson = JSON.stringify(r.timelineData).replace(/'/g, "''");
    updateSql += `UPDATE stories\nSET audio_url = '${r.publicAudioUrl}',\n    timeline_data = '${timelineJson}'\nWHERE id = '${r.storyId}';\n\n`;
  }

  await writeFile('supabase/update_habits_audio.sql', updateSql);
  console.log('\n🎉 ALL 5 HABITS AUDIO SUCCESSFULLY GENERATED & UPLOADED!');
  console.log('Saved SQL update script to: supabase/update_habits_audio.sql');
}

run().catch((e) => {
  console.error('\n❌ Fatal error during audio generation:', e);
  process.exit(1);
});
