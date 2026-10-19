import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { CharacterSkinPalette } from './character_palette.js';
import { CharacterEyes } from './character_eyes.js';
import { CharacterMouth } from './character_mouth.js';

// Bundled as one local classic script: no CDN, network import or model URL.
const send = (type, detail = {}) => window.GlowCharacter?.postMessage(JSON.stringify({ type, ...detail }));
let renderer, scene, camera, controls, model, mixer, skeleton, jaw, jawRest, eyeAnimation, mouthAnimation;
let frame = 0, last = 0, time = 0;
let active, ready = false, disposed = false, firstFrame = false, failed = false;
let sampledFrames = 0, sampleStart = 0;
let state = {
  motion: 'Idle', playing: true, speaking: false, visible: true, interactive: true,
  skeleton: false, hat: false, hatColor: '#2c2c2e', muscles: false, glasses: true,
  cameraFit: 1.10, originalGreen: true, color: '#22592a', position: 0,
  framing: 'body', angle: 0, autoBlink: true, blink: 0, clay: false,
};
const actions = new Map();
const HAT_MATERIALS = new Set(['Hat', 'HatBand', 'HatTrim', 'HatSkin']);
const skinPalette = new CharacterSkinPalette();
let jawRestPos = null;
const jawRotation = new THREE.Quaternion();
const jawAxis = new THREE.Vector3(1, 0, 0);
function applyTalkingMouth(dt) {
  if (mouthAnimation) {
    mouthAnimation.update(dt, state.motion, state.speaking, time);
  }
  if (jaw && jawRest && jawRestPos) {
    const sad = state.motion === 'Sad';
    jaw.position.set(jawRestPos.x, jawRestPos.y + (sad ? 0.024 : 0), jawRestPos.z);
    if (sad) jaw.quaternion.identity();
    else if (state.speaking || state.motion === 'Talk') {
      const u = (time % 2) / 2;
      const syllable = Math.sin(Math.PI * 4 * u) ** 2;
      jaw.quaternion.setFromAxisAngle(jawAxis, 0.08 + 0.30 * syllable);
    } else {
      jaw.quaternion.copy(jawRest);
    }
  }
}
function applyClay() {
  if (!model) return;
  const isClay = state.clay === true;
  model.traverse(o => {
    if (o.isMesh) {
      if (!o.userData.original) o.userData.original = o.material;
      if (!o.userData.clay) {
        o.userData.clay = new THREE.MeshStandardMaterial({
          color: ['Body', 'Scalp', 'EyeLids', 'EyeSocketSkin'].includes(o.name) ? 0x84a996 : 0x686b70,
          roughness: 0.85,
          side: THREE.DoubleSide,
        });
      }
      o.material = isClay ? o.userData.clay : o.userData.original;
      o.material.needsUpdate = true;
    }
  });
}
function updateCameraPosition() {
  if (!camera || !controls) return;
  const fit = Number(state.cameraFit) > 0 ? Number(state.cameraFit) : 1.10;
  const isFace = state.framing === 'face';
  const targetY = isFace ? 2.40 : 1.78;
  const distance = isFace
    ? 1.65 * fit
    : (Math.max(3.5, (model?.userData.frameWidth ?? 3.5) / camera.aspect) / (2 * Math.tan(38 * Math.PI / 360))) * fit;
  const cameraY = isFace ? 2.45 : 2.06;
  const angleRad = ((Number(state.angle) || 0) * Math.PI) / 180;

  const camX = distance * Math.sin(angleRad) + (isFace ? 0 : 0.32);
  const camZ = distance * Math.cos(angleRad);

  camera.position.set(camX, cameraY, camZ);
  controls.target.set(0, targetY, 0);
  controls.update();
}
function selectMotion() {
  const next = actions.get(state.motion) ?? actions.get('Idle') ?? actions.values().next().value;
  if (!next || next === active) return;
  next.reset().setEffectiveWeight(1).play();
  if (active) next.crossFadeFrom(active, .3, false);
  active = next;
}
function applyGlasses() {
  if (!model) return;
  const show = state.glasses === true;
  model.traverse(object => {
    if (object.name === 'Glasses') object.visible = show;
    for (const material of [object.material].flat().filter(Boolean)) {
      if (material.name === 'Glasses') object.visible = show;
    }
  });
}
function hideFittedMesh() {
  if (!model) return;
  model.traverse(object => {
    for (const material of [object.material].flat().filter(Boolean)) {
      if (material.name === 'Muscles') object.visible = false;
    }
  });
}
function applyHat() {
  if (!model) return;
  const show = state.hat === true;
  const tint = new THREE.Color(state.hatColor || '#2c2c2e');
  const skin = new THREE.Color(state.color || '#22592a');
  model.traverse(object => {
    // The rig's Hat node shares its atlas material with Body and Glasses.
    if (object.name === 'Hat') object.visible = show;
    for (const material of [object.material].flat().filter(Boolean)) {
      const name = material.name;
      if (!HAT_MATERIALS.has(name)) continue;
      object.visible = show;
      if (!show) continue;
      if (name === 'HatSkin') material.color.copy(skin);
      else {
        const shade = name === 'HatBand' ? .45 : 1;
        material.color.setRGB(tint.r * shade, tint.g * shade, tint.b * shade);
      }
      material.transparent = false;
      material.opacity = 1;
      material.depthWrite = true;
      material.needsUpdate = true;
    }
  });
}
function resize() {
  if (!renderer || !camera) return;
  const w = Math.max(1, innerWidth), h = Math.max(1, innerHeight);
  // Supersampled buffer plus MSAA. The long side stays at 3072 so the
  // silhouette stays sharp without an 8K framebuffer that stalls the GPU.
  const longSide = Math.max(w, h);
  renderer.setPixelRatio(Math.max(1, Math.min(devicePixelRatio || 1, 3, 3072 / longSide)));
  renderer.setSize(w, h, false);
  camera.aspect = w / h; camera.updateProjectionMatrix();
  updateCameraPosition();
  draw();
}
function draw() {
  if (ready && !disposed && state.visible) renderer.render(scene, camera);
}
function schedule() {
  if (!frame && ready && !disposed && !failed && state.visible && !document.hidden) frame = requestAnimationFrame(tick);
}
function tick(now) {
  frame = 0;
  if (disposed || !state.visible || document.hidden) { last = 0; return; }
  const dt = last ? Math.min((now - last) / 1000, .08) : 0; last = now;
  const orbitChanged = controls.update();
  if (state.playing || !state.autoBlink) {
    time += dt; state.position += dt;
    if (state.playing) {
      selectMotion();
      mixer?.update(dt);
    }
    if (state.autoBlink === false && state.blink !== undefined) {
      eyeAnimation?.setClosure(Number(state.blink) || 0);
    } else if (state.playing) {
      eyeAnimation?.update(dt, state.motion);
    }
    applyTalkingMouth(dt);
  }
  draw();
  if (failed) return;
  if (!firstFrame) { firstFrame = true; send('ready', { triangles: renderer.info.render.triangles, clips: [...actions.keys()] }); }
  if (state.diagnostics) {
    if (!sampleStart) sampleStart = now;
    sampledFrames++;
    if (now - sampleStart >= 5000) {
      send('sample', { fps: +(sampledFrames * 1000 / (now - sampleStart)).toFixed(1), triangles: renderer.info.render.triangles, motion: state.motion, actionTime: active?.time, textures: renderer.info.memory.textures });
      sampledFrames = 0; sampleStart = now;
    }
  }
  if (state.playing || orbitChanged) schedule();
}
function _localUrlAllowed(url) {
  return url.startsWith('blob:') ||
    url.startsWith('data:') ||
    url.startsWith('file:') ||
    url.startsWith('./') ||
    !url.includes('://');
}
function _resourceManager() {
  const manager = new THREE.LoadingManager();
  manager.setURLModifier(url => {
    if (_localUrlAllowed(url)) return url;
    throw new Error('External model resources are not permitted');
  });
  return manager;
}
async function _mountGltf(data) {
  if (disposed) return;
  model = data.scene; scene.add(model);
  const seen = new Set();
  const maxAniso = renderer.capabilities.getMaxAnisotropy?.() ?? 1;
  model.traverse(object => {
    if (object.isMesh) {
      object.frustumCulled = false;
      const meshName = (object.name || '').toLowerCase();
      for (const material of [object.material].flat().filter(Boolean)) {
        const matName = (material.name || '').toLowerCase();
        const isEye = meshName.includes('eye') || matName.includes('eye');
        const isGlasses = meshName.includes('glasses') || matName.includes('glasses') || meshName.includes('spectacle') || matName.includes('spectacle');
        const isMouth = meshName.includes('mouth') || matName.includes('mouth') || meshName.includes('jaw') || matName.includes('teeth') || matName.includes('tongue');
        const isScalp = meshName.includes('scalp') || matName.includes('scalp');

        if (isEye) {
          material.roughness = 0.06;
          material.metalness = 0.0;
          material.envMapIntensity = 1.5;
        } else if (isGlasses) {
          material.roughness = 0.16;
          material.metalness = 0.15;
          material.envMapIntensity = 1.3;
        } else if (isMouth) {
          material.roughness = 0.25;
          material.metalness = 0.0;
          material.envMapIntensity = 0.8;
        } else if (isScalp) {
          // Remove roughness map and match Body properties identically
          material.roughnessMap = null;
          material.roughness = 0.38;
          material.metalness = 0.02;
          material.envMapIntensity = 0.95;
        } else {
          material.roughness = 0.38;
          material.metalness = 0.02;
          material.envMapIntensity = 0.95;
        }

        if (material.map) {
          material.map.colorSpace = THREE.SRGBColorSpace;
          material.map.anisotropy = Math.min(16, maxAniso);
          material.map.needsUpdate = true;
        }
        if (material.normalMap) {
          material.normalMap.anisotropy = Math.min(16, maxAniso);
          material.normalMap.needsUpdate = true;
        }
        if (material.roughnessMap) {
          material.roughnessMap.anisotropy = Math.min(16, maxAniso);
          material.roughnessMap.needsUpdate = true;
        }
        material.needsUpdate = true;
      }
    }
    skinPalette.attach(object, seen);
  });
  eyeAnimation = new CharacterEyes(model);
  mouthAnimation = new CharacterMouth(model);
  jaw = model.getObjectByName('Jaw'); jawRest = jaw?.quaternion.clone(); jawRestPos = jaw?.position.clone();
  const bounds = new THREE.Box3().setFromObject(model), size = bounds.getSize(new THREE.Vector3()), center = bounds.getCenter(new THREE.Vector3());
  if (!(size.y > 0)) throw new Error('Empty model bounds');
  const scale = 3.5 / size.y;
  model.scale.setScalar(scale); model.position.set(-center.x * scale, -bounds.min.y * scale, -center.z * scale);
  model.userData.frameWidth = size.x * scale;
  mixer = new THREE.AnimationMixer(model);
  for (const clip of data.animations) actions.set(clip.name, mixer.clipAction(clip));
  applyHat();
  applyGlasses();
  applyClay();
  hideFittedMesh();
  update(state); selectMotion(); mixer.update(0); ready = true; send('loaded'); resize(); schedule();
}
async function loadLocal(fileName) {
  try {
    const data = await new GLTFLoader(_resourceManager()).loadAsync(fileName);
    await _mountGltf(data);
  } catch (error) {
    send('localLoadFailed', { message: String(error?.message ?? error) });
  }
}
let buffer = null;
function begin(length) { buffer = new Uint8Array(length); }
function appendBatch(parts) {
  for (const [encoded, offset] of parts) {
    const binary = atob(encoded);
    const len = binary.length;
    const view = new Uint8Array(len);
    const len8 = len & ~7;
    let i = 0;
    for (; i < len8; i += 8) {
      view[i] = binary.charCodeAt(i);
      view[i + 1] = binary.charCodeAt(i + 1);
      view[i + 2] = binary.charCodeAt(i + 2);
      view[i + 3] = binary.charCodeAt(i + 3);
      view[i + 4] = binary.charCodeAt(i + 4);
      view[i + 5] = binary.charCodeAt(i + 5);
      view[i + 6] = binary.charCodeAt(i + 6);
      view[i + 7] = binary.charCodeAt(i + 7);
    }
    for (; i < len; i++) {
      view[i] = binary.charCodeAt(i);
    }
    buffer.set(view, offset);
  }
}
async function loadBuffered() {
  try {
    const bytes = buffer.buffer; buffer = null;
    const data = await new GLTFLoader(_resourceManager()).parseAsync(bytes, '');
    await _mountGltf(data);
  } catch (error) { fail(error); }
}
async function loadFromBase64(encoded) {
  try {
    const binary = atob(encoded);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; ++i) bytes[i] = binary.charCodeAt(i);
    const data = await new GLTFLoader(_resourceManager()).parseAsync(bytes.buffer, '');
    await _mountGltf(data);
  } catch (error) { fail(error); }
}
function update(next) {
  const wasSpeaking = state.speaking;
  const seek = next.seek === true;
  const fitChanged = next.cameraFit !== undefined && next.cameraFit !== state.cameraFit;
  const cameraChanged = fitChanged || next.framing !== undefined || next.angle !== undefined;
  const hatChanged = next.hat !== undefined || next.hatColor !== undefined || next.color !== undefined;
  const glassesChanged = next.glasses !== undefined;
  const clayChanged = next.clay !== undefined;
  const blinkChanged = next.autoBlink !== undefined || next.blink !== undefined;
  state = { ...state, ...next };
  skinPalette.setColor(state.color, state.originalGreen);
  skinPalette.setMuscles(state.muscles);
  if (next.muscles !== undefined || next.seek === true) hideFittedMesh();
  if (controls) controls.enabled = state.interactive;
  if (state.skeleton && model && !skeleton) { skeleton = new THREE.SkeletonHelper(model); scene.add(skeleton); }
  if (skeleton) skeleton.visible = state.skeleton;
  if (hatChanged || next.seek === true) applyHat();
  if (glassesChanged || next.seek === true) applyGlasses();
  if (clayChanged || next.seek === true) applyClay();
  if (blinkChanged && state.autoBlink === false && eyeAnimation) {
    eyeAnimation.setClosure(Number(state.blink) || 0);
  }
  if (mixer) {
    selectMotion();
    if (seek) { mixer.stopAllAction(); active = null; selectMotion(); if (active) active.time = state.position % active.getClip().duration; mixer.update(0); }
    if (wasSpeaking && !state.speaking && jaw && jawRest && jawRestPos) {
      jaw.quaternion.copy(jawRest);
      jaw.position.copy(jawRestPos);
      mixer.update(0);
    }
  }
  if (cameraChanged) updateCameraPosition();
  if (fitChanged) resize();
  if (!state.visible) { cancelAnimationFrame(frame); frame = 0; last = 0; }
  else schedule();
}
function fail(error) { if (disposed || failed) return; failed = true; cancelAnimationFrame(frame); frame = 0; send('error', { message: String(error?.message ?? error) }); }
function dispose() {
  if (disposed) return;
  disposed = true; ready = false;
  cancelAnimationFrame(frame); controls?.dispose(); mixer?.stopAllAction();
  const textures = new Set(), materials = new Set(), geometries = new Set();
  scene?.traverse(object => {
    if (object.geometry) geometries.add(object.geometry);
    for (const material of [object.material].flat().filter(Boolean)) {
      materials.add(material); for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    }
  });
  if (scene?.environment) textures.add(scene.environment);
  for (const texture of textures) { texture.source?.data?.close?.(); texture.dispose(); }
  for (const material of materials) material.dispose();
  for (const geometry of geometries) geometry.dispose();
  renderer?.dispose(); renderer?.forceContextLoss();
}
window.GlowViewer = { loadLocal, loadFromBase64, begin, appendBatch, loadBuffered, update, dispose };
try {
  // MSAA on: WebView GL is stable (unlike native flutter_angle FBOs).
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
    powerPreference: 'high-performance',
    preserveDrawingBuffer: false,
  });
  renderer.setClearColor(0x000000, 0);
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
  if ('physicallyCorrectLights' in renderer) renderer.physicallyCorrectLights = false;
  renderer.debug.onShaderError = () => fail(new Error('Character shader compilation failed'));
  document.body.appendChild(renderer.domElement);
  renderer.domElement.addEventListener('webglcontextlost', event => { event.preventDefault(); fail(new Error('Graphics context lost')); });
  scene = new THREE.Scene();

  // Procedural Studio Environment for rich specular reflections & gloss
  const pmremGenerator = new THREE.PMREMGenerator(renderer);
  pmremGenerator.compileEquirectangularShader();
  const roomEnv = new RoomEnvironment();
  scene.environment = pmremGenerator.fromScene(roomEnv, 0.04).texture;
  if ('environmentIntensity' in scene) scene.environmentIntensity = 0.95;
  roomEnv.dispose();
  pmremGenerator.dispose();

  camera = new THREE.PerspectiveCamera(38, 1, .05, 100);
  controls = new OrbitControls(camera, renderer.domElement); controls.enablePan = false; controls.enableZoom = true; controls.enableDamping = true; controls.minDistance = 0.7; controls.maxDistance = 20; controls.target.set(0, 1.78, 0);
  controls.addEventListener('change', () => { if (!state.playing) { draw(); schedule(); } });
  scene.add(new THREE.HemisphereLight(0xfff8f2, 0x1f2e24, 0.45));
  const key = new THREE.DirectionalLight(0xffffff, 1.6); key.position.set(-2, 4.5, 4.5); scene.add(key);
  const fill = new THREE.DirectionalLight(0xbdd7ee, 0.50); fill.position.set(3, 2, 2); scene.add(fill);
  const rim = new THREE.DirectionalLight(0xffffff, 1.35); rim.position.set(0, 3.5, -4); scene.add(rim);
  for (let i = 0; i < 5; i++) {
    const shadow = new THREE.Mesh(new THREE.SphereGeometry(1, 32, 8), new THREE.MeshBasicMaterial({ color: 0x31483b, transparent: true, opacity: .025, depthWrite: false }));
    shadow.position.set(0, -.04 - i * .001, 0); shadow.scale.set(.6 + i * .1, .018, .38 + i * .07); scene.add(shadow);
  }
  addEventListener('resize', resize);
  document.addEventListener('visibilitychange', () => { last = 0; if (document.hidden) { cancelAnimationFrame(frame); frame = 0; } else schedule(); });
  addEventListener('pagehide', dispose);
  addEventListener('error', event => {
    if (event.target && event.target !== window) return;
    const message = String(event.error?.message ?? event.message ?? '');
    if (/failed to fetch|networkerror|internet disconnected|err_internet/i.test(message)) return;
    fail(event.error ?? event.message);
  });
  addEventListener('unhandledrejection', event => {
    const message = String(event.reason?.message ?? event.reason ?? '');
    if (/failed to fetch|networkerror|internet disconnected|err_internet/i.test(message)) return;
    fail(event.reason);
  });
  send('boot');
} catch (error) { fail(error); }
