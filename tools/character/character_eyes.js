import * as THREE from 'three';

const smooth = t => { t=THREE.MathUtils.clamp(t,0,1);return t*t*(3-2*t); };

// Shared by the bundled mobile viewer and the local HTTP review. Morph names also
// match CharacterEyeAnimation in Dart, including the legacy collapsed lids.
export class CharacterEyes {
  constructor(model) {
    this.eyes=['EyeLeft','EyeRight'].map(name=>model.getObjectByName(name));
    model.traverse(o=>{if(o.morphTargetDictionary?.BlinkLeftClosed!==undefined)this.lids=o;});
    this.keepOpen=this.lids?.userData.keepOpenLids===true;
    this.rotation=new THREE.Euler();
    this.time=0;this.motionTime=0;this.nextBlink=.7;this.blinkStart=-10;
    this.duration=.26;this.nextLook=1.2;
    this.lookX=this.lookY=this.gazeX=this.gazeY=this.squint=0;
    if(this.lids)this.lids.visible=this.keepOpen;
  }
  blink(delay) {
    const p=(this.time-this.blinkStart-delay)/this.duration;
    return p<0||p>1?0:p<.3?smooth(p/.3):p<.4?1:1-smooth((p-.4)/.6);
  }
  setClosure(left,right=left) {
    if(!this.lids||this.eyes.some(e=>!e))return;
    left=THREE.MathUtils.clamp(left,0,1);right=THREE.MathUtils.clamp(right,0,1);
    this.lids.visible=this.keepOpen||Math.max(left,right)>.002;
    [left,right].forEach((c,i)=>{
      this.rotation.set(this.gazeY*(1-c),this.gazeX*(1-c),0);
      this.eyes[i].quaternion.setFromEuler(this.rotation);
      this.lids.morphTargetInfluences[i*2]=Math.min(c*2,2-c*2);
      this.lids.morphTargetInfluences[i*2+1]=Math.max(0,c*2-1);
    });
  }
  update(dt,motion) {
    if(!this.lids||this.eyes.some(e=>!e))return;
    this.time+=dt;this.motionTime+=dt;
    if(motion!==this.motion){
      this.motion=motion;this.motionTime=0;this.nextLook=this.time+.2;
      this.nextBlink=Math.min(this.nextBlink,this.time+.35);
    }
    if(this.time>=this.nextBlink){
      this.blinkStart=this.time;this.duration=motion==='Sad'?.34:.24+Math.random()*.06;
      this.nextBlink=this.time+(Math.random()<.1?.42:2.6+Math.random()*3);
    }
    if(this.time>=this.nextLook){
      this.lookX=(Math.random()-.5)*.055;this.lookY=(Math.random()-.5)*.025;
      this.nextLook=this.time+1.6+Math.random()*2.2;
    }
    let x=this.lookX,y=this.lookY,close=0;
    switch(motion){
      case 'Thinking':x+=.065;y-=.05;close=.08;break;
      case 'Sad':x*=.3;y+=.06;close=.24;break;
      case 'Laugh':close=.48+.1*Math.sin(this.motionTime*5.2);y-=.015;break;
      case 'Happy':close=.16;break;
      case 'Smile':close=.07;break;
      case 'Victory':y-=.04;close=.08;break;
      case 'Wave':x+=.025*Math.sin(this.motionTime*1.4);break;
    }
    const ease=1-Math.exp(-dt*16);
    this.gazeX+=(THREE.MathUtils.clamp(x,-.1,.1)-this.gazeX)*ease;
    this.gazeY+=(THREE.MathUtils.clamp(y,-.08,.08)-this.gazeY)*ease;
    this.squint+=(close-this.squint)*(1-Math.exp(-dt*9));
    this.setClosure(Math.max(this.squint,this.blink(0)),Math.max(this.squint,this.blink(.012)));
  }
}
