import * as THREE from 'three';
const HAT_MATERIALS=new Set(['Hat','HatBand','HatTrim','HatSkin']);
const MUSCLE_GLSL = `
vec2 glowPad(vec2 q, vec2 c, vec2 r) {
  vec2 d = (q - c) / r;
  float dist = length(d);
  float body = clamp((1.0 - dist) / 0.28, 0.0, 1.0);
  body = body * body * (3.0 - 2.0 * body);
  float light = body * clamp(d.y, 0.0, 1.0) * 0.42;
  float shadow = body * clamp(-d.y, 0.0, 1.0) * 0.28;
  float band = exp(-(d.y + 0.82) * (d.y + 0.82) / 0.05) * exp(-d.x * d.x / 0.7);
  return vec2(shadow + band * 0.22, light);
}
float glowSeg(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-5), 0.0, 1.0);
  return length(pa - ba * h);
}
vec3 glowMuscleDraw(vec3 p, vec3 n) {
  float cx = p.x + 0.062;
  float front = smoothstep(0.18, 0.55, n.z) * smoothstep(0.07, 0.13, p.z);
  float yIn = smoothstep(0.17, 0.20, p.y) * (1.0 - smoothstep(0.36, 0.39, p.y));
  float side = 1.0 - smoothstep(0.13, 0.20, abs(cx));
  float gate = front * yIn * side;
  vec2 q = vec2(cx, p.y);
  float shadow = clamp((0.007 - abs(cx)) / 0.005, 0.0, 1.0)
    * smoothstep(0.20, 0.225, p.y) * (1.0 - smoothstep(0.34, 0.36, p.y)) * 0.36;
  shadow += clamp((0.0055 - abs(p.y - 0.308)) / 0.0045, 0.0, 1.0) * clamp((0.135 - abs(cx)) / 0.135, 0.0, 1.0) * 0.30;
  shadow += clamp((0.0055 - abs(p.y - 0.264)) / 0.0045, 0.0, 1.0) * clamp((0.140 - abs(cx)) / 0.140, 0.0, 1.0) * 0.30;
  shadow += clamp((0.0055 - abs(p.y - 0.222)) / 0.0045, 0.0, 1.0) * clamp((0.125 - abs(cx)) / 0.125, 0.0, 1.0) * 0.28;
  float light = 0.0;
  vec2 pad = glowPad(q, vec2(-0.058, 0.328), vec2(0.068, 0.026));
  shadow += pad.x; light += pad.y;
  pad = glowPad(q, vec2(0.058, 0.328), vec2(0.068, 0.026));
  shadow += pad.x; light += pad.y;
  pad = glowPad(q, vec2(-0.060, 0.284), vec2(0.072, 0.026));
  shadow += pad.x; light += pad.y;
  pad = glowPad(q, vec2(0.060, 0.284), vec2(0.072, 0.026));
  shadow += pad.x; light += pad.y;
  pad = glowPad(q, vec2(-0.054, 0.242), vec2(0.064, 0.024));
  shadow += pad.x; light += pad.y;
  pad = glowPad(q, vec2(0.054, 0.242), vec2(0.064, 0.024));
  shadow += pad.x; light += pad.y;
  float boltD = glowSeg(q, vec2(-0.030, 0.426), vec2(-0.074, 0.402));
  boltD = min(boltD, glowSeg(q, vec2(-0.074, 0.402), vec2(-0.036, 0.386)));
  boltD = min(boltD, glowSeg(q, vec2(-0.036, 0.386), vec2(-0.080, 0.358)));
  float bolt = clamp((0.0065 - boltD) / 0.0045, 0.0, 1.0);
  return vec3(shadow, light, bolt) * gate;
}
float glowDome(vec2 q, vec2 c, vec2 r) {
  vec2 d = (q - c) / r;
  float body = clamp(1.0 - dot(d, d), 0.0, 1.0);
  return body * body;
}
float glowMuscleHeight(vec3 p, vec3 n) {
  float cx = p.x + 0.062;
  float front = smoothstep(0.18, 0.55, n.z) * smoothstep(0.07, 0.13, p.z);
  float yIn = smoothstep(0.17, 0.20, p.y) * (1.0 - smoothstep(0.36, 0.39, p.y));
  float side = 1.0 - smoothstep(0.13, 0.20, abs(cx));
  float gate = front * yIn * side;
  vec2 q = vec2(cx, p.y);
  float h = 0.0;
  h += glowDome(q, vec2(-0.058, 0.328), vec2(0.068, 0.026)) * 0.010;
  h += glowDome(q, vec2(0.058, 0.328), vec2(0.068, 0.026)) * 0.010;
  h += glowDome(q, vec2(-0.060, 0.284), vec2(0.072, 0.026)) * 0.011;
  h += glowDome(q, vec2(0.060, 0.284), vec2(0.072, 0.026)) * 0.011;
  h += glowDome(q, vec2(-0.054, 0.242), vec2(0.064, 0.024)) * 0.009;
  h += glowDome(q, vec2(0.054, 0.242), vec2(0.064, 0.024)) * 0.009;
  float reach = 1.0 - smoothstep(0.03, 0.16, abs(cx));
  h -= exp(-cx * cx / 0.000045) * 0.003 * smoothstep(0.20, 0.24, p.y) * (1.0 - smoothstep(0.34, 0.36, p.y));
  h -= exp(-(p.y - 0.306) * (p.y - 0.306) / 0.000030) * 0.003 * reach;
  h -= exp(-(p.y - 0.262) * (p.y - 0.262) / 0.000030) * 0.003 * reach;
  h -= exp(-(p.y - 0.222) * (p.y - 0.222) / 0.000030) * 0.002 * reach;
  return h * gate;
}
`;

// Recolor combined atlas and vertex colors, preserving cream and accessories.
export class CharacterSkinPalette {
 constructor({referenceLuminance=.106,shadeContrast=.75}={}) {
  this.referenceLuminance=referenceLuminance;this.shadeContrast=shadeContrast;
  this.target={value:new THREE.Color()};this.strength={value:0};this.muscles={value:0};
  this.bellyTarget={value:new THREE.Color('#efece6')};this.bellyCustom={value:0};
 }
 setColor(color,originalGreen=false){this.target.value.set(color);this.strength.value=originalGreen?0:1;}
 setBellyColor(color, custom=true){
  if (color && custom) {
    this.bellyTarget.value.set(color);
    this.bellyCustom.value = 1.0;
  } else {
    this.bellyCustom.value = 0.0;
  }
 }
 setMuscles(enabled){this.muscles.value=enabled?1:0;}
attach(mesh, seen) {
  const {target,strength,muscles,bellyTarget,bellyCustom}=this;
  // The eye atlas has a green skin rim outside the white. Exclude the iris.
  if(['EyeLeft','EyeRight'].includes(mesh.name)&&mesh.geometry?.getAttribute('uv')&&!mesh.geometry.getAttribute('_glow_skin_region')){
    const uv=mesh.geometry.getAttribute('uv');
    const mask=Float32Array.from({length:uv.count},(_,i)=>Math.hypot(2*uv.getX(i)-1,2*uv.getY(i)-1)>.80?1:0);
    mesh.geometry.setAttribute('_glow_skin_region',new THREE.BufferAttribute(mask,1));
  }
  if (!mesh.geometry?.getAttribute('_glow_skin_region')) return;
  const isScalp = mesh.name === 'Scalp';
  for (const material of [mesh.material].flat()) {
    if (!material || seen.has(material) || HAT_MATERIALS.has(material.name)) continue;
    seen.add(material);
    const scalpMat = isScalp || material.name === 'GlowScalpSkin';
    material.customProgramCacheKey = () => `glow-skin-palette-v16-${scalpMat ? 'scalp' : 'body'}`;
    material.onBeforeCompile = shader => {
      shader.uniforms.glowSkinTarget = target;
      shader.uniforms.glowSkinStrength = strength;
      shader.uniforms.glowMuscles = muscles;
      shader.uniforms.glowBellyTarget = bellyTarget;
      shader.uniforms.glowBellyCustom = bellyCustom;
      shader.vertexShader = 'attribute float _glow_skin_region;\nvarying float vGlowSkinRegion;\nvarying vec3 vGlowMuscle;\nuniform float glowMuscles;\n' + MUSCLE_GLSL + shader.vertexShader;
      shader.vertexShader = shader.vertexShader.replace('#include <beginnormal_vertex>', '#include <beginnormal_vertex>\nfloat glowHdx = glowMuscleHeight(position + vec3(0.004, 0.0, 0.0), normal) - glowMuscleHeight(position - vec3(0.004, 0.0, 0.0), normal);\nfloat glowHdy = glowMuscleHeight(position + vec3(0.0, 0.004, 0.0), normal) - glowMuscleHeight(position - vec3(0.0, 0.004, 0.0), normal);\nobjectNormal = normalize(objectNormal - vec3(glowHdx, glowHdy, 0.0) * (36.0 * glowMuscles));');
      shader.vertexShader = shader.vertexShader.replace('#include <begin_vertex>', '#include <begin_vertex>\nvGlowSkinRegion = _glow_skin_region;\nvGlowMuscle = glowMuscleDraw(position, normal);\ntransformed += normal * glowMuscleHeight(position, normal) * glowMuscles;');
      shader.fragmentShader = 'uniform vec3 glowSkinTarget;\nuniform float glowSkinStrength;\nuniform float glowMuscles;\nuniform vec3 glowBellyTarget;\nuniform float glowBellyCustom;\nvarying float vGlowSkinRegion;\nvarying vec3 vGlowMuscle;\n' + shader.fragmentShader;
      shader.fragmentShader = shader.fragmentShader.replace('#include <color_fragment>', `#include <color_fragment>
        ${scalpMat ? 'float mask = glowSkinStrength;' : `
        float greenDominance = (diffuseColor.g - max(diffuseColor.r, diffuseColor.b)) / max(diffuseColor.g, 0.0001);
        float mask = smoothstep(0.20, 0.42, greenDominance) * clamp(vGlowSkinRegion, 0.0, 1.0) * glowSkinStrength;
        float bellyMask = (1.0 - smoothstep(0.04, 0.20, greenDominance)) * clamp(vGlowSkinRegion, 0.0, 1.0) * glowBellyCustom;
        `}

        if (glowSkinStrength < 0.5) {
          // Original green (Port): Rich, saturated emerald green across body and scalp
          float lum = dot(diffuseColor.rgb, vec3(0.2126, 0.7152, 0.0722));
          diffuseColor.rgb = mix(vec3(lum), diffuseColor.rgb, 1.30);
          diffuseColor.rgb = pow(max(diffuseColor.rgb, vec3(0.0)), vec3(1.05));
        } else {
          // Use the same shading on both sides of the completed scalp seam.
          float lum = dot(diffuseColor.rgb, vec3(0.2126, 0.7152, 0.0722));
          float ao = clamp(lum / 0.16, 0.82, 1.0);
          vec3 recolor = glowSkinTarget * ao;
          diffuseColor.rgb = mix(diffuseColor.rgb, recolor, mask);
        }

        ${scalpMat ? '' : `
        if (glowBellyCustom > 0.5) {
          float bellyLum = dot(diffuseColor.rgb, vec3(0.2126, 0.7152, 0.0722));
          float bellyAo = clamp(bellyLum / 0.65, 0.85, 1.0);
          vec3 bellyRecolor = glowBellyTarget * bellyAo;
          diffuseColor.rgb = mix(diffuseColor.rgb, bellyRecolor, bellyMask);
        }
        `}

        float muscleOn = glowMuscles;
        diffuseColor.rgb *= mix(1.0, 0.62, clamp(vGlowMuscle.x, 0.0, 1.0) * muscleOn);
        diffuseColor.rgb *= mix(1.0, 1.28, clamp(vGlowMuscle.y, 0.0, 1.0) * muscleOn);
        diffuseColor.rgb = mix(diffuseColor.rgb, vec3(1.0, 0.75, 0.08), clamp(vGlowMuscle.z, 0.0, 1.0) * muscleOn);
`);
    };
  }
}
}
