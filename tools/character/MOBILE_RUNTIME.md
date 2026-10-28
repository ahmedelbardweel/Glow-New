# Mobile character runtime

Android and iOS use `MobileCharacterViewer` through `SmartCharacterViewer`.
The bundled `assets/3d/glow_rigged.glb` contains the same 20 clips, head,
hands, mouth morphs, eyelids, removable hat/glasses and attached celebration
props as the reference review. Rendering uses the shared palette, surface,
mouth, eye and motion-blending modules. The studio route uses this same
mobile viewer on phones; it does not require the preview server.

After changing the GLB or any JavaScript runtime module, run:

```
node tools/character/build_mobile_viewer.mjs
node tools/character/check_mobile_quality.mjs
node tools/character/check_motion_blend.mjs
flutter test test/story_motion_test.dart --no-pub
```

The bundler regenerates `character_mobile.js` and `character_pack_version.dart`.
Commit both together with changed assets. The content fingerprint invalidates
the on-device offline pack even for equal-length model edits. The app copies
the updated local files on its next launch; it needs no CDN or preview server.

Rendering retains MSAA and full geometry/morphs. The framebuffer is limited to
2 million pixels, a 2048-pixel long side and DPR 2. Sustained frame rate below
45 lowers resolution gradually; sustained rate above 57 restores it slowly.
This is a resolution controller, not a guarantee of 60 FPS. Invisible props
are skipped, offscreen/background rendering stops, and texture anisotropy is
capped at 4. Repeated playback messages do not reset the orbit camera or
recompile unchanged accessory materials. Disposing also frees cached clay
and original materials, buffered model bytes and animation actions.

For actual Android/iOS measurements:

```
flutter run --profile -d DEVICE -t tools/character/mobile_smoke_main.dart --dart-define=GLOW_CHARACTER_DIAGNOSTICS=true
```

The smoke screen cycles all 20 motions and six colors, toggles accessories,
resizes, opens another 3D route and returns. Diagnostics report FPS, draw calls,
triangles, textures and effective pixel ratio. Inspect several minutes of
playback, suspend/resume and route changes on a physical device. Desktop
SwiftShader screenshots verify behavior but do not measure phone performance.
Speech still uses a stylized speaking cadence, not phoneme recognition.
