import assert from 'node:assert/strict';
import * as THREE from 'three';
import {MotionBlend} from './motion_blend.js';
import {motionLabels} from './motion_catalog.js';
// Real mixers, including rapid reversals and paused selection: no rest-pose
// contribution, no jump on interruption, and only one action survives settling.
let pairs=0;
for(const from of Object.keys(motionLabels))for(const to of Object.keys(motionLabels)){
  const root=new THREE.Object3D(),mixer=new THREE.AnimationMixer(root);
  const actions=new Map(Object.keys(motionLabels).map((name,i)=>[name,mixer.clipAction(new THREE.AnimationClip(name,2,[new THREE.VectorKeyframeTrack('.position',[0,2],[i,i/2,0,i,i/2,0])]))]));
  const blend=new MotionBlend(actions);blend.select(from);mixer.update(0);
  blend.select(to);blend.update(.23);mixer.update(.23);
  const before=root.position.clone();blend.select('Wave');blend.update(0);mixer.update(0);
  assert(before.distanceTo(root.position)<1e-10,'Interrupted transition jumped');
  for(let i=0;i<55;i++){
    blend.update(1/60);mixer.update(1/60);
    assert(Math.abs([...blend.weights.values()].reduce((a,b)=>a+b,0)-1)<1e-12);
  }
  assert.equal(blend.weights.size,1);
  assert.equal(mixer.stats.actions.inUse,1);
  blend.select('Curious',true);mixer.update(0);
  assert.equal(blend.weights.size,1);
  assert.equal(blend.active,actions.get('Curious'));
  blend.clear();assert.equal(mixer.stats.actions.inUse,0);
  pairs++;
}
console.log(JSON.stringify({pairs,interruptionsContinuous:true,weightsNormalized:true,noActionLeak:true,pausedSelection:true}));
