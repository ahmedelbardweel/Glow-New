// Export the local pose review as a self-contained HTML file. All code, model
// bytes and the reference image are embedded, so it also works after the local
// preview server stops. This does not change any production asset.
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../..');
const review = path.join(root, process.argv[2] || 'build/idle_pose_review');
let html = await readFile(path.join(review, 'index.html'), 'utf8');
const match = html.match(/<script type="module">([\s\S]*?)<\/script>/);
if (!match) throw new Error('Review module was not found.');
let source = match[1];
source = source.replace(
  'const q=new URLSearchParams(location.search)',
  "const q=new URLSearchParams('saved=1&'+location.search.slice(1))",
).replace(
  'const gltf=await new GLTFLoader().loadAsync(file);',
  "const encoded=document.getElementById('model-'+id).textContent.trim();" +
  "const bytes=Uint8Array.from(atob(encoded),c=>c.charCodeAt(0));" +
  "const gltf=await new GLTFLoader().parseAsync(bytes.buffer,'');",
);
if (source.includes('loadAsync(file)')) throw new Error('External GLB load remains.');
const imports = [...source.matchAll(/import .*?;/g)].map(item => item[0]).join('\n');
source = source.replace(/import .*?;/g, '');
const result = await build({
  stdin: { contents: `${imports}\n(async()=>{${source}\n})();`, resolveDir: here },
  bundle: true, write: false, format: 'iife', target: 'es2020', minify: true,
});
html = html.replace(/<script type="importmap">[\s\S]*?<\/script>/, '');
const code = result.outputFiles[0].text.replace(/<\/script/gi, '<\\/script');
// Callback replacement preserves literal $&, $` and $' in bundled shaders.
html = html.replace(match[0], () => `<script>${code}</script>`);
const [before, after, reference] = await Promise.all([
  readFile(path.join(review, 'before.glb')),
  readFile(path.join(root, 'assets/3d/glow_mascot.glb')),
  readFile(path.join(review, 'reference.png')),
]);
html = html.replace('src="reference.png"', `src="data:image/png;base64,${reference.toString('base64')}"`);
const embedded = `<script id="model-before" type="application/octet-stream">${before.toString('base64')}</script>` +
  `<script id="model-after" type="application/octet-stream">${after.toString('base64')}</script>`;
html = html.replace('<script>', () => embedded + '<script>');
if ((html.match(/<\/script>/g) || []).length !== 3) {
  throw new Error('Unexpected script boundary in the embedded review.');
}
const output = path.join(review, 'character-review-offline.html');
await writeFile(output, html, 'utf8');
console.log(`Saved standalone review (${(Buffer.byteLength(html) / 1024 / 1024).toFixed(1)} MiB): ${output}`);

