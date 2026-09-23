# Supplied Glow character, facial rig and palette

The active model is `assets/3d/glow_mascot.glb`, built directly from the user's
`port_frontal.glb`. The unchanged source is saved outside the Flutter bundle at
`tools/character/source/port_frontal.glb`.

Source SHA-256: `5b316a34733e59fa7206568e0173745e6e310aab5053c156c8fbb7400fb71a84`.
The builder refuses other source hashes and refuses to overwrite the source.
The legacy procedural builder exports only under `build/legacy_character/`.

## Preservation contract

All 55,164 original vertices retain their decoded positions, normals and UVs.
The source material, texture transforms and three embedded 2048px JPEGs are
retained. Quantized positions are decoded to float32 for the installed Flutter
loader; maximum rounding error is about `2.98e-8` source units. Original height
remains approximately 0.9798 units.

The original mouth is a closed surface. To open it, `port_lip_surface.py`
subdivides the lip contour and duplicates its coincident upper/lower boundary.
It adds 203 vertices through barycentric interpolation on original triangles.
The external surface has 55,367 vertices and 95,132 triangles, compared with
94,874 original triangles. This changes local topology, not the neutral surface.
Provenance for each added vertex and triangle is embedded in the GLB and checked
against the source. A recessed mouth lining and tongue add two primitives and
1,776 triangles. They are hidden when the mouth is closed.

Idle restores the original rest pose. Facial weights are confined to the
mouth; the eyes, nose, glasses, hat, central torso, belly and tail remain fixed.
The 140 original index-connected pieces are UV islands on one surface.
Coincident UV-seam vertices share identical skeletal weights and remain joined.

## Skeleton and expressions

19 joints: Root, Hips, Spine, Chest, 12 limb joints, Jaw, MouthCornerLeft and
MouthCornerRight. Body joints remain fixed. This is a runtime deformation
skeleton, not a Blender IK control rig.

`port_rig_weights.py` solves four pinned harmonic limb fields with diagonally
preconditioned conjugate gradients to a relative residual below `1e-9`.
Protected vertices are pinned to Root. Each vertex has at most four
nonnegative influences, with exactly zero weights in unused slots.

`port_face_rig.py` adds local jaw and lip-corner fields on 745 external surface
vertices. The jaw hinges behind the lower lip, while the corner controls move
the closed lips into a smile or a restrained sad expression. The matching inner
mouth boundary uses the same weights.

Ten clips: Idle, Talk, Wave, Happy, Sad, Thinking, Victory, Walk, Smile and Laugh.
Every clip keys all 12 limb rotations, the jaw rotation and both corner
translations, including explicit rest values. This clears previous expressions
during the existing crossfades. Speech preview blends a modest jaw opening with
the clip's opening, preserving laughter. It is a procedural speech preview,
not phoneme-level audio lip synchronization.

The source has inner arms fused to the torso. Gestures remain restrained.
Full overhead waving, hand-to-chin contact, deep knee bends and large strides
would require separating hidden arm/body surfaces and additional deformation
work. This export does not claim that work is complete.

## Five colors on one model

`CharacterHelper` maps the five saved identities to the same asset. Uploaded
HTTP/file models remain independent.

`character_skin_palette.dart` modifies the supplied material's shader once.
A vertex attribute, `_GLOW_SKIN_REGION` (loaded as `_glow_skin_region`), protects
the eyes/lenses. Within that region, green texture chroma isolates skin from the
cream belly/muzzle, dark hat/glasses and gold badge. Recoloring retains texture
luminance, the original normal/roughness maps and subsequent PBR lighting.
The original green identity bypasses recoloring entirely.

Selecting another identity changes shader uniforms, without reloading the
model, replacing textures, resetting the animation mixer or making a network
request. Lighting and texture shading still affect the rendered color; a lit
3D surface is not a flat UI swatch. The palette selector previously targeted
only the old procedural BodyColor/BodyDetail materials, which is why it had no
effect on the supplied textured model.

All textures are embedded in the approximately 5.70 MB GLB. Skeletal playback,
facial expressions and palette changes need no network or external service.
The viewer retains its existing lifecycle, cache, orbit/zoom and retry handling.

## Rebuild and validate

Python requires the installed `numpy` and `pygltflib`. Khronos validation uses
the dependency pinned in `tools/character/package-lock.json`.

```powershell
python tools/character/rig_port_frontal.py tools/character/source/port_frontal.glb assets/3d/glow_mascot.glb
python tools/character/check_port_rig.py tools/character/source/port_frontal.glb assets/3d/glow_mascot.glb --report tools/character/port_rig_report.json
node tools/character/validate_mascot.cjs assets/3d/glow_mascot.glb --source tools/character/source/port_frontal.glb
```

The checker verifies source positions, texture bytes, material data, normals,
UVs, barycentric lip refinement, source surface coverage, bind matrices, weights,
eye protection and UV-seam continuity. It samples 250 clip poses and 270
crossfade poses. Idle leaves the source surface unchanged; Smile/Sad keep the
lips closed, and Talk/Happy/Laugh open them. Protected vertices and original UV
seams have zero measured displacement/separation. Maximum sampled edge stretch
is about 2.60 on a small limb attachment edge. These are regression measurements,
not proof against every possible self-intersection.

Khronos reports zero errors and one warning inherited from the source:
`MESH_PRIMITIVE_GENERATED_TANGENT_SPACE`. The source has a normal map without
tangent attributes; the renderer generates its basis. The report retains and
compares this warning with the source baseline.

The Flutter web studio is built from `lib/character_studio_main.dart`.
The asset-loader test was updated for 19 bones, three primitives, the palette
attribute and all ten clips. The Flutter test suite and Android/device
performance tests were not run for this change.

## Refresh the local preview

Dart/shader changes require rebuilding the studio, not only copying the GLB:

```powershell
C:\src\flutter\bin\flutter.bat build web --no-pub --target lib/character_studio_main.dart --output build/character_face_studio --no-wasm-dry-run
Get-ChildItem -LiteralPath build/character_face_studio -Force | Copy-Item -Destination build/character_preview -Recurse -Force
python tools/character/serve_web_preview.py --root build/character_preview --port 8767
```

The server uses content-versioned paths and displays the GLB hash to prevent
stale previews. It does not compile Dart. Installed app binaries need both the
updated viewer code and the asset in their next Flutter build.
