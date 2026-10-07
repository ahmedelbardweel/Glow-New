// Split the Tripo character sheet into one node per pose, face each pose
// forward, ground and center it, simplify it, and write a plain GLB that the
// three_js loader reads (no meshopt/quantization extensions).
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize, weld, simplifyPrimitive, prune } from '@gltf-transform/functions';
import { MeshoptDecoder, MeshoptSimplifier } from 'meshoptimizer';
import fs from 'node:fs';

const [input, output] = process.argv.slice(2);
const TARGET_TRIS = 36000;
const POSES = [
  [2, 'front', 'أمامي'],
  [0, 'power', 'قوة'],
  [1, 'power_2', 'قوة ٢'],
  [3, 'front_2', 'أمامي ٢'],
  [4, 'back', 'من الخلف'],
  [5, 'neutral', 'محايد'],
  [6, 'victorious', 'منتصر'],
  [7, 'happy', 'سعيد'],
  [9, 'laughing', 'ضاحك'],
  [10, 'excited', 'متحمس جدا'],
  [8, 'curious', 'فضولي'],
  [16, 'thinking', 'يفكر'],
  [12, 'cheer', 'تشجيع قوي'],
  [15, 'celebrate', 'احتفال بالفوز'],
  [11, 'frustrated', 'محبط'],
  [13, 'nervous', 'متوتر'],
  [14, 'confused', 'مرتبك'],
  [17, 'final_win', 'الفوز النهائي'],
];
const facing = JSON.parse(fs.readFileSync('facing.json', 'utf8'));
facing[4].yaw = facing[2].yaw;

await MeshoptDecoder.ready;
await MeshoptSimplifier.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({ 'meshopt.decoder': MeshoptDecoder });
const doc = await io.read(input);
await doc.transform(dequantize());
const root = doc.getRoot();
const source = root.listMeshes()[0].listPrimitives()[0];
const material = source.getMaterial();
material.setName('PoseSkin');
const pos = source.getAttribute('POSITION').getArray();
const nrm = source.getAttribute('NORMAL').getArray();
const uv = source.getAttribute('TEXCOORD_0').getArray();
const idx = source.getIndices().getArray();
const n = pos.length / 3;

const keys = new Map();
const welded = new Int32Array(n);
for (let i = 0; i < n; i++) {
  const k = `${Math.round(pos[3 * i] * 1e5)},${Math.round(pos[3 * i + 1] * 1e5)},${Math.round(pos[3 * i + 2] * 1e5)}`;
  let w = keys.get(k);
  if (w === undefined) { w = keys.size; keys.set(k, w); }
  welded[i] = w;
}
const parent = new Int32Array(keys.size).map((_, i) => i);
const find = (a) => { while (parent[a] !== a) { parent[a] = parent[parent[a]]; a = parent[a]; } return a; };
for (let t = 0; t < idx.length; t += 3) {
  for (const k of [1, 2]) { const a = find(welded[idx[t]]), b = find(welded[idx[t + k]]); if (a !== b) parent[a] = b; }
}
const counts = new Map();
for (let t = 0; t < idx.length; t += 3) { const c = find(welded[idx[t]]); counts.set(c, (counts.get(c) ?? 0) + 1); }
const rank = new Map([...counts.entries()].sort((a, b) => b[1] - a[1]).map(([c], i) => [c, i]));
const triangles = Array.from({ length: rank.size }, () => []);
for (let t = 0; t < idx.length; t += 3) triangles[rank.get(find(welded[idx[t]]))].push(t);

const scene = root.listScenes()[0];
for (const node of root.listNodes()) node.dispose();
const buffer = root.listBuffers()[0];
const created = [];
for (const [component, id, label] of POSES) {
  const tris = triangles[component];
  const remap = new Map();
  const order = [];
  const indices = new Uint32Array(tris.length * 3);
  tris.forEach((t, j) => {
    for (let k = 0; k < 3; k++) {
      const v = idx[t + k];
      let m = remap.get(v);
      if (m === undefined) { m = order.length; remap.set(v, m); order.push(v); }
      indices[3 * j + k] = m;
    }
  });
  const yaw = facing[component].yaw;
  const c = Math.cos(-yaw), s = Math.sin(-yaw);
  const p = new Float32Array(order.length * 3);
  const q = new Float32Array(order.length * 3);
  const t = new Float32Array(order.length * 2);
  const region = new Float32Array(order.length).fill(1);
  order.forEach((v, i) => {
    const [x, y, z] = [pos[3 * v], pos[3 * v + 1], pos[3 * v + 2]];
    p.set([c * x + s * z, y, -s * x + c * z], 3 * i);
    const [a, b, d] = [nrm[3 * v], nrm[3 * v + 1], nrm[3 * v + 2]];
    q.set([c * a + s * d, b, -s * a + c * d], 3 * i);
    t.set([uv[2 * v], uv[2 * v + 1]], 2 * i);
  });
  const lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < p.length; i += 3) for (let a = 0; a < 3; a++) { lo[a] = Math.min(lo[a], p[i + a]); hi[a] = Math.max(hi[a], p[i + a]); }
  const scale = 1 / (hi[1] - lo[1]);
  for (let i = 0; i < p.length; i += 3) {
    p[i] = (p[i] - (lo[0] + hi[0]) / 2) * scale;
    p[i + 1] = (p[i + 1] - lo[1]) * scale;
    p[i + 2] = (p[i + 2] - (lo[2] + hi[2]) / 2) * scale;
  }
  const accessor = (array, type) => doc.createAccessor().setArray(array).setType(type).setBuffer(buffer);
  const prim = doc.createPrimitive()
    .setAttribute('POSITION', accessor(p, 'VEC3'))
    .setAttribute('NORMAL', accessor(q, 'VEC3'))
    .setAttribute('TEXCOORD_0', accessor(t, 'VEC2'))
    .setAttribute('_GLOW_SKIN_REGION', accessor(region, 'SCALAR'))
    .setIndices(accessor(indices, 'SCALAR'))
    .setMaterial(material);
  const mesh = doc.createMesh(`Pose_${id}`).addPrimitive(prim);
  const node = doc.createNode(`Pose_${id}`).setMesh(mesh).setExtras({ label, pose: id });
  scene.addChild(node);
  created.push([prim, tris.length, id]);
}
source.dispose();
root.listMeshes().filter((m) => m.listPrimitives().length === 0).forEach((m) => m.dispose());
await doc.transform(weld());
for (const [prim, count, id] of created) {
  const ratio = Math.min(1, TARGET_TRIS / count);
  simplifyPrimitive(prim, { simplifier: MeshoptSimplifier, ratio, error: 0.01, lockBorder: false });
  console.log(id, count, '->', prim.getIndices().getCount() / 3);
}
material.getNormalTexture()?.setImage(fs.readFileSync('normal.jpg')).setMimeType('image/jpeg');
for (const ext of root.listExtensionsUsed()) ext.dispose();
await doc.transform(prune({ keepAttributes: true }));
await io.write(output, doc);
console.log('WROTE', output, fs.statSync(output).size);
