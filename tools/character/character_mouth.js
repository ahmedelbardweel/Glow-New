import * as THREE from 'three';

/**
 * Real-time expressive mouth animation for the updated Glow mascot.
 * Controls the 4 morph targets on ExpressiveMouth:
 * - MouthOpen
 * - MouthSmile
 * - MouthSad
 * - MouthRound
 */
export class CharacterMouth {
  constructor(model) {
    this.mouth = model.getObjectByName('ExpressiveMouth');
    this.time = 0;
    this.current = { open: 0, smile: 0.14, sad: 0, round: 0 };
    this.dict = this.mouth?.morphTargetDictionary || {};
    this.hasTargets = Boolean(
      this.mouth &&
      this.mouth.morphTargetInfluences &&
      (this.dict.MouthOpen !== undefined || this.mouth.morphTargetInfluences.length >= 4)
    );
  }

  update(dt, motion, speaking, clockTime) {
    if (!this.hasTargets) return;
    this.time += dt;

    let targetOpen = 0.0;
    let targetSmile = 0.0;
    let targetSad = 0.0;
    let targetRound = 0.0;

    // Emotion expressions driven by the current animation motion
    switch (motion) {
      case 'Smile':
        targetSmile = 0.85;
        targetOpen = 0.04;
        break;
      case 'Happy':
        targetSmile = 0.75;
        targetOpen = 0.16;
        break;
      case 'Laugh':
        targetSmile = 0.72;
        targetOpen = 0.38 + 0.36 * Math.sin(this.time * 8.5);
        break;
      case 'Sad':
        targetSad = 0.85;
        targetOpen = 0.0;
        break;
      case 'Thinking':
        targetRound = 0.35;
        targetSmile = 0.05;
        targetOpen = 0.06;
        break;
      case 'Victory':
        targetSmile = 0.65;
        targetOpen = 0.25;
        break;
      case 'Talk':
        targetSmile = 0.22;
        if (!speaking) {
          const u = this.time * 3.5;
          targetOpen = 0.12 + 0.32 * Math.pow(Math.sin(u), 2);
        }
        break;
      case 'Idle':
      case 'Wave':
      case 'Walk':
      default:
        targetSmile = 0.14; // Friendly soft rest
        targetOpen = 0.0;
        break;
    }

    // Dynamic speech cadence when speaking is active
    if (speaking) {
      const u = (clockTime !== undefined ? clockTime : this.time) * 4.4;
      const syllable = Math.pow(Math.sin(u), 2) * 0.72 + Math.pow(Math.sin(u * 1.6), 2) * 0.28;
      targetOpen = Math.max(targetOpen, 0.18 + 0.62 * syllable);
      if (motion !== 'Sad') {
        targetSmile = Math.max(targetSmile, 0.24 + 0.18 * Math.sin(u * 0.6));
      }
    }

    // Fluid exponential lerping for buttery 60fps transitions
    const blendRate = 1 - Math.exp(-dt * 22);
    this.current.open += (targetOpen - this.current.open) * blendRate;
    this.current.smile += (targetSmile - this.current.smile) * blendRate;
    this.current.sad += (targetSad - this.current.sad) * blendRate;
    this.current.round += (targetRound - this.current.round) * blendRate;

    const inf = this.mouth.morphTargetInfluences;
    const openIdx = this.dict.MouthOpen ?? 0;
    const smileIdx = this.dict.MouthSmile ?? 1;
    const sadIdx = this.dict.MouthSad ?? 2;
    const roundIdx = this.dict.MouthRound ?? 3;

    if (inf.length > openIdx) inf[openIdx] = THREE.MathUtils.clamp(this.current.open, 0, 1);
    if (inf.length > smileIdx) inf[smileIdx] = THREE.MathUtils.clamp(this.current.smile, 0, 1);
    if (inf.length > sadIdx) inf[sadIdx] = THREE.MathUtils.clamp(this.current.sad, 0, 1);
    if (inf.length > roundIdx) inf[roundIdx] = THREE.MathUtils.clamp(this.current.round, 0, 1);
  }
}
