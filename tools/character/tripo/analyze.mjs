import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize } from '@gltf-transform/functions';
import { MeshoptDecoder } from 'meshoptimizer';
import fs from 'node:fs';

const input = process.argv[2];
await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({ 'meshopt.decoder': MeshoptDecoder });
const doc = await io.read(input);
await doc.transform(dequantize());
const prim = doc.getRoot().listMeshes()[0].listPrimitives()[0];
const pos = prim.getAttribute('POSITION').getArray();
const idx = prim.getIndices().getArray();
console.log('attributes', prim.listSemantics(), 'verts', pos.length / 3, 'tris', idx.length / 3);
for (const t of doc.getRoot().listTextures()) console.log('texture', t.getName(), t.getMimeType(), t.getSize(), t.getImage().byteLength);

const n = pos.length / 3;
const key = new Map();
const weld = new Int32Array(n);
for (let i = 0; i < n; i++) {
  const k = `${Math.round(pos[3 * i] * 1e5)},${Math.round(pos[3 * i + 1] * 1e5)},${Math.round(pos[3 * i + 2] * 1e5)}`;
  let w = key.get(k);
  if (w === undefined) { w = key.size; key.set(k, w); }
  weld[i] = w;
}
const parent = new Int32Array(key.size).map((_, i) => i);
const find = (a) => { while (parent[a] !== a) { parent[a] = parent[parent[a]]; a = parent[a]; } return a; };
const unite = (a, b) => { a = find(a); b = find(b); if (a !== b) parent[a] = b; };
for (let t = 0; t < idx.length; t += 3) { unite(weld[idx[t]], weld[idx[t + 1]]); unite(weld[idx[t]], weld[idx[t + 2]]); }
const comps = new Map();
for (let t = 0; t < idx.length; t += 3) {
  const c = find(weld[idx[t]]);
  let e = comps.get(c);
  if (!e) { e = { tris: 0, min: [Infinity, Infinity, Infinity], max: [-Infinity, -Infinity, -Infinity] }; comps.set(c, e); }
  e.tris++;
  for (let k = 0; k < 3; k++) {
    const v = idx[t + k];
    for (let a = 0; a < 3; a++) { const x = pos[3 * v + a]; if (x < e.min[a]) e.min[a] = x; if (x > e.max[a]) e.max[a] = x; }
  }
}
const list = [...comps.values()].sort((a, b) => b.tris - a.tris);
console.log('components', list.length);
for (const c of list.slice(0, 40)) console.log(c.tris, c.min.map((x) => x.toFixed(3)).join(','), '|', c.max.map((x) => x.toFixed(3)).join(','));
fs.writeFileSync('components.json', JSON.stringify(list));
const order = [...comps.entries()].sort((a, b) => b[1].tris - a[1].tris).map(([root]) => root);
const rank = new Map(order.map((root, i) => [root, i]));
const triComp = new Uint8Array(idx.length / 3);
for (let t = 0; t < idx.length; t += 3) triComp[t / 3] = rank.get(find(weld[idx[t]]));
fs.writeFileSync('pos.bin', Buffer.from(new Float32Array(pos).buffer));
fs.writeFileSync('idx.bin', Buffer.from(new Uint32Array(idx).buffer));
fs.writeFileSync('comp.bin', Buffer.from(triComp.buffer));
