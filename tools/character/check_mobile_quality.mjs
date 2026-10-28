import assert from 'node:assert/strict';
import { MobileQuality } from './mobile_quality.js';
const quality = new MobileQuality();
for (const [w,h,dpr] of [[390,844,3],[430,932,3],[1024,1366,2],[3840,2160,2]]) {
  const ratio = quality.pixelRatio(w,h,dpr);
  assert(w*h*ratio*ratio <= 2000000.01);
  assert(Math.max(w,h)*ratio <= 2048.01);
}
for(let i=0;i<300;i++) quality.sample(1/30);
assert(quality.scale < 1 && quality.scale >= .6);
const reduced = quality.scale;
for(let i=0;i<180;i++) quality.sample(1/60);
assert.equal(quality.scale, reduced, 'Recovery must not oscillate every window');
for(let i=0;i<1200;i++) quality.sample(1/60);
assert(quality.scale > reduced && quality.scale <= 1);
const beforePause = quality.scale;
quality.sample(30); quality.reset();
assert.equal(quality.scale, beforePause, 'Background time must not reduce quality');
console.log('Mobile pixel budgets, slow-device adaptation, recovery and suspension passed');
