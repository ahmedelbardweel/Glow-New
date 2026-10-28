// Blend from the current weight distribution, including an interrupted blend.
// All weights sum to one; completed actions stop instead of accumulating.
export class MotionBlend {
  constructor(actions) { this.actions=actions;this.weights=new Map();this.start=new Map();this.active=null;this.elapsed=0;this.duration=.7; }
  select(name, immediate=false) {
    const next=this.actions.get(name)||this.actions.get('Idle')||this.actions.values().next().value;
    if(!next || next===this.active)return next;
    if(!this.weights.has(next))next.reset().setEffectiveWeight(0).play();
    this.start=new Map(this.weights);this.weights.set(next,this.weights.get(next)||0);
    this.active=next;this.elapsed=0;
    if(immediate||!this.start.size)this.update(this.duration);
    return next;
  }
  update(dt) {
    if(!this.active)return;
    this.elapsed=Math.min(this.duration,this.elapsed+Math.max(0,dt));
    const u=this.elapsed/this.duration, ease=u*u*u*(10+u*(-15+6*u));
    for(const action of [...this.weights.keys()]) {
      const initial=this.start.get(action)||0;
      const weight=initial*(1-ease)+(action===this.active?ease:0);
      action.setEffectiveWeight(weight);this.weights.set(action,weight);
      if(u===1 && action!==this.active){action.stop();this.weights.delete(action);}
    }
  }
  clear() {
    for(const action of this.weights.keys())action.stop();
    this.weights.clear();this.start.clear();this.active=null;
  }
}
