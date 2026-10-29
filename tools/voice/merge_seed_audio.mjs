import { readFile, writeFile } from 'node:fs/promises';

const updateSql = await readFile('supabase/update_habits_audio.sql', 'utf8');

const regex = /UPDATE stories\s+SET audio_url = '([^']+)',\s+timeline_data = '([^']+)'\s+WHERE id = '([^']+)';/g;
const updates = new Map();
let m;
while ((m = regex.exec(updateSql)) !== null) {
  updates.set(m[3], { audioUrl: m[1], timelineData: m[2] });
}

let seedSql = await readFile('supabase/habits_seed.sql', 'utf8');

// Replace INSERT statements in habits_seed.sql to include audio_url
seedSql = seedSql.replace(
  /INSERT INTO stories \(id, mission_id, title, character_name, content, image_url, order_index, timeline_data, created_at\)/g,
  'INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, audio_url, timeline_data, created_at)'
);

for (const [id, data] of updates.entries()) {
  const pattern = new RegExp(
    `('\\s*${id}\\s*',\\s*[\\s\\S]*?'',\\s*1,\\s*)'(\\{[\\s\\S]*?\\})'`,
    'g'
  );
  seedSql = seedSql.replace(pattern, (match, prefix) => {
    return `${prefix}'${data.audioUrl}',\n        '${data.timelineData}'`;
  });
}

// Also update ON CONFLICT SET
seedSql = seedSql.replace(
  /ON CONFLICT \(id\) DO UPDATE SET\s+title = EXCLUDED\.title,\s+character_name = EXCLUDED\.character_name,\s+content = EXCLUDED\.content,\s+timeline_data = EXCLUDED\.timeline_data;/g,
  'ON CONFLICT (id) DO UPDATE SET\n        title = EXCLUDED.title,\n        character_name = EXCLUDED.character_name,\n        content = EXCLUDED.content,\n        audio_url = EXCLUDED.audio_url,\n        timeline_data = EXCLUDED.timeline_data;'
);

await writeFile('supabase/habits_seed.sql', seedSql);
console.log('habits_seed.sql successfully updated with audio_url and exact timelines!');
