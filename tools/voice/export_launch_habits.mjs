// Exports the reviewed launch seed into APK assets. Run after changing
// supabase/habits_seed.sql so offline content is always identical to cloud.
import { mkdir, readFile, writeFile } from 'node:fs/promises';

const source = await readFile('supabase/habits_seed.sql', 'utf8');
await mkdir('assets/content', { recursive: true });

const variables = Object.fromEntries(
  [...source.matchAll(/\b(\w+)\s+UUID\s*:=\s*'([^']+)'/g)].map((match) => [
    match[1],
    match[2],
  ]),
);

function valuesFor(table) {
  const found = [];
  const marker = `INSERT INTO ${table} (`;
  let cursor = 0;
  while ((cursor = source.indexOf(marker, cursor)) >= 0) {
    const columnsEnd = source.indexOf(')\n    VALUES (', cursor);
    const columns = source
      .slice(cursor + marker.length, columnsEnd)
      .split(',')
      .map((value) => value.trim());
    let index = columnsEnd + ')\n    VALUES ('.length;
    let quote = false;
    let depth = 1;
    let value = '';
    const values = [];
    for (; index < source.length; index++) {
      const char = source[index];
      if (quote && char === "'" && source[index + 1] === "'") {
        value += "''";
        index++;
        continue;
      }
      if (char === "'") quote = !quote;
      if (!quote && char === '(') depth++;
      if (!quote && char === ')') {
        depth--;
        if (depth === 0) {
          values.push(value.trim());
          break;
        }
      }
      if (!quote && depth === 1 && char === ',') {
        values.push(value.trim());
        value = '';
        continue;
      }
      value += char;
    }
    const row = Object.fromEntries(columns.map((column, i) => [column, sqlValue(values[i] ?? '')]));
    found.push(row);
    cursor = index + 1;
  }
  return found;
}

function sqlValue(value) {
  const text = value.trim();
  if (text.startsWith("'") && text.includes("'")) {
    const end = text.lastIndexOf("'");
    const unescaped = text.slice(1, end).replaceAll("''", "'");
    if (text.slice(end + 1).trim() === '::jsonb') return JSON.parse(unescaped);
    return unescaped;
  }
  if (/^-?\d+$/.test(text)) return Number(text);
  return variables[text] ?? text;
}

const worlds = valuesFor('worlds');
const missions = valuesFor('missions');
const stories = valuesFor('stories');
const questions = valuesFor('questions');

await Promise.all([
  writeFile('assets/content/launch_worlds.json', JSON.stringify(worlds)),
  writeFile('assets/content/launch_missions.json', JSON.stringify(missions)),
  writeFile('assets/content/launch_stories.json', JSON.stringify(stories)),
  writeFile('assets/content/launch_questions.json', JSON.stringify(questions)),
]);

console.log(`Exported ${worlds.length} world, ${missions.length} missions, ${stories.length} stories, and ${questions.length} questions.`);
