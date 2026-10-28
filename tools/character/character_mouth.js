import {MOUTH_TARGETS, sampleMouth} from './mouth_expression.js';

/** One expression drives the jaw, lips, cavity, teeth and tongue together. */
export class CharacterMouth {
  constructor(model) {
    this.meshes=[];
    model.traverse(o=>{
      if(o.morphTargetDictionary?.MouthOpen!==undefined) this.meshes.push(o);
    });
    this.mouth=model.getObjectByName('ExpressiveMouth');
    this.hasTargets=this.meshes.length>0;
    this.current=[0,.12,0,0];this.time=0;this.lastClock=null;
  }
  update(dt, motion, speaking=false, clockTime, clipTime) {
    if(!this.hasTargets) return;
    const step=Number.isFinite(dt)?Math.max(0,Math.min(dt,.08)):0;
    const clock=Number.isFinite(clockTime)?clockTime:this.time+step;
    const seek=this.lastClock!==null&&Math.abs(clock-this.lastClock-step)>.20;
    this.time=clock;this.lastClock=clock;
    const target=sampleMouth(clock,motion,speaking,Number.isFinite(clipTime)?clipTime:clock);
    for(let i=0;i<4;i++) {
      // Quick closures preserve consonants; slower emotion changes stay gentle.
      const rate=i===0?(target[i]<this.current[i]?38:28):(i===3?24:10);
      const blend=seek||step===0?1:1-Math.exp(-step*rate);
      this.current[i]+=(target[i]-this.current[i])*blend;
    }
    for(const mesh of this.meshes) {
      for(let i=0;i<4;i++) {
        const index=mesh.morphTargetDictionary[MOUTH_TARGETS[i]];
        if(index!==undefined)mesh.morphTargetInfluences[index]=this.current[i];
      }
    }
  }
}
