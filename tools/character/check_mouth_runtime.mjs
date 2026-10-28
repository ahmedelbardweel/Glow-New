import assert from 'node:assert/strict';
import fs from 'node:fs';
import {CharacterMouth} from './character_mouth.js';
import {sampleMouth, MOUTH_TARGETS} from './mouth_expression.js';
import {motionLabels} from './motion_catalog.js';
const motions=Object.keys(motionLabels);
const samples=[];
for(const motion of motions)for(const speaking of [false,true])for(let i=0;i<=280;i++){
  const time=i/100,pose=sampleMouth(time,motion,speaking);
  assert(pose.every(v=>Number.isFinite(v)&&v>=0&&v<=1));
  samples.push({motion,speaking,time,pose});
}
assert(sampleMouth(2.5,'Talk')[0]===0,'Phrase must close the mouth');
assert(sampleMouth(.63,'Talk')[3]>.5,'Rounded vowels are missing');
assert(sampleMouth(0,'Sad')[2]>.9&&sampleMouth(0,'Smile')[1]>.9);
for(const motion of ['Laugh','Happy','Excited']){
  assert.deepEqual(sampleMouth(50,motion,false,0),sampleMouth(90,motion,false,0),'Pose phase depends on global speech clock');
  for(let i=0;i<=64;i++){
    const clipTime=i/20,time=100+clipTime,pose=sampleMouth(time,motion,false,clipTime);
    samples.push({motion,speaking:false,time,clipTime,pose});
  }
}
const meshes=['Body','ExpressiveMouth','MouthTeeth','MouthTongue'].map(name=>({name,morphTargetDictionary:Object.fromEntries(MOUTH_TARGETS.map((n,i)=>[n,i])),morphTargetInfluences:[0,0,0,0]}));
const model={traverse:fn=>meshes.forEach(fn),getObjectByName:name=>meshes.find(m=>m.name===name)};
const controller=new CharacterMouth(model);
let minimum=1,maximum=0;
for(let i=0;i<336;i++){
  controller.update(1/60,'Talk',true,(i+1)/60);
  minimum=Math.min(minimum,controller.current[0]);maximum=Math.max(maximum,controller.current[0]);
  for(const mesh of meshes)assert.deepEqual(mesh.morphTargetInfluences,controller.current);
}
assert(minimum<.001&&maximum>.5);
controller.update(0,'Talk',true,.63);
assert.deepEqual(controller.current,sampleMouth(.63,'Talk',true));
controller.update(0,'Idle',false,4);
assert.equal(controller.current[0],0,'Stopping speech must close the jaw');
if(process.argv[2])fs.writeFileSync(process.argv[2],JSON.stringify(samples));
console.log(JSON.stringify({samples:samples.length,partsSynchronized:true,completeClosures:true,roundedVowels:true,seekDeterministic:true,stopClosesJaw:true}));
