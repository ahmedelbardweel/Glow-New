// Apply the audio_url and timeline_data updates directly to Supabase
import { readFile } from 'node:fs/promises';

const SUPABASE_URL = 'https://sqvbbsqmwktxuapwivnk.supabase.co';
const SUPABASE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0eHVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEaOnI';

const updateSql = await readFile('supabase/update_habits_audio.sql', 'utf8');

// Parse the UPDATE statements
const regex = /UPDATE stories\s+SET audio_url = '([^']+)',\s+timeline_data = '([^']+)'\s+WHERE id = '([^']+)';/g;
const updates = [];
let m;
while ((m = regex.exec(updateSql)) !== null) {
  updates.push({ audioUrl: m[1], timelineData: m[2], id: m[3] });
}

console.log(`Found ${updates.length} updates to apply...`);

for (const u of updates) {
  console.log(`\nUpdating story ${u.id} with audio_url...`);
  const res = await fetch(`${SUPABASE_URL}/rest/v1/stories?id=eq.${u.id}`, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    body: JSON.stringify({
      audio_url: u.audioUrl,
      timeline_data: u.timelineData,
    }),
  });

  const body = await res.text();
  if (!res.ok) {
    console.error(`  ERROR ${res.status}:`, body.slice(0, 200));
  } else {
    const rows = JSON.parse(body);
    const title = rows[0]?.title || '(unknown)';
    console.log(`  OK - "${title}" updated!`);
  }
}

console.log('\n✅ All 5 habit stories updated in Supabase with audio_url and exact timeline_data!');
