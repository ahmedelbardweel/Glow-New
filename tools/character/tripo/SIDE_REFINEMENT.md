# New Glow rig: sides and hands

`refine_sides.py` repairs the new Tripo rig, not the legacy dinosaur asset.
Both `web/character_rig/glow_rigged.glb` and `assets/3d/glow_rigged.glb`
must receive the same validated output.

The original nearest-bone harmonic seed rule left the spine, upper arms and
forearms without anchors. Hand and toe weights consequently reached the
flanks. Continuous anatomical fields now bind torso, shoulder, elbow and wrist
locally. The full distal arm cross-section receives arm weights; the narrow
shoulder envelope must not also be applied to the fingertips. The elbow blend
is wider to accommodate the thick arm and the existing Thinking pose.

The refinement also applies bounded, feathered surface smoothing to sides and
upper arms, reduces Idle sway, and makes the 2-second Wave a pair of complete,
gentler 1-second oscillations. UVs, textures, topology and skeleton stay intact.
Version 2 fixes the distal-arm leakage present in the first draft (version 1).
Version 3 protects the lower cheek cross-section from arm and spine influence.
The original head is round in its bind pose: only the skin weights made its
lower corners square during Idle. The soft neck transition now ends below the
cheeks, keeping them on Head without changing the geometry or muzzle texture.
Use `check_head_refinement.py v2.glb v3.glb` to check this preservation and all
ten motions. `render_head_review.py` generates offline textured close-ups.
Version 4 mirrors the left shoulder, upper arm, elbow and wrist pivot positions
from the right. The original arm geometry already has matching dimensions; the
asymmetric pivots made the left arm appear longer in Idle. Updating inverse bind
matrices preserves the approved mesh at rest. `check_arm_symmetry.py v3.glb
v4.glb` verifies matching posed hand bounds and unchanged right side/head across
all ten clips. `render_head_review.py --full-body` shows the complete character.

## Rebuild

Use the unrefined original, SHA-256
`d85aa0b2831105a718e4abdde4da7c1dfe4f83e0b4a92e29fef2bb01f3314c78`
(case-insensitive). A local working copy is at
`build/tripo/side_review/before.glb`. The original is also in Git at
`c4058cf:web/character_rig/glow_rigged.glb`. Extract binary data with a
binary-safe Git API or Python subprocess, not Windows text redirection.

```powershell
python tools/character/tripo/refine_sides.py build/tripo/side_review/before.glb build/tripo/side_review/candidate.glb
python tools/character/tripo/validate_deformation.py build/tripo/side_review/before.glb build/tripo/side_review/candidate.glb --output build/tripo/side_review/comparison.json
```

Inspect Idle, Wave (including the loop boundary), Thinking and raised-arm clips
from front, both sides, and three-quarter angles before installing the result.
The numerical report measures edge stretch and UV seam separation; it is not
proof of absence of self-intersections. The surface smoothing is limited to
0.003 model units and does not attempt to reconstruct the source topology.

The local comparison page is `build/tripo/side_review/index.html`, served from
the repository root on port 8874. The left view uses the original, and the
right view uses the refined candidate. Runtime Dart changes are not needed
for this asset refinement; an installed phone app needs a rebuild to bundle it.

## Optional hat

The studio and local comparison page start with the hat hidden. Use
`إظهار الطاقية` to show or hide it without resetting the animation. The new
rig's `Hat` node shares `GlowSkin` with `Body` and `Glasses`, so both runtime
viewers change node visibility, not material opacity or color. The hat remains
inside the GLB. Legacy hat materials retain their existing color controls.
Rebuild the mobile viewer bundle after editing `mobile_viewer.mjs`:
`node tools/character/build_mobile_viewer.mjs`. Offline previews can hide the
same part using `render_head_review.py --full-body --hide-hat`.

## Complete head without the hat

The original Body ends at an open 1,918-edge rim hidden by Hat. Run
`complete_skull.py` after side refinement to close it with a rounded `Scalp`
mesh. The scalp uses the existing Head skin joint and remains visible with
either hat setting. Original geometry, arm repairs, skeleton and animation
accessors are unchanged. Normals blend over a 0.025-unit collar. Version 2
extends the surrounding skin's color variation across a 0.055-unit texture
collar and the dome, removing the flat median-green band used in version 1.
Features outside this strip keep their original texture. Two dense rings
avoid folded triangles at the irregular cut; every scalp face points outward.
Roughness blends from the body's 0.78 at the join to 0.58 above, restoring a
soft highlight without a sharp material boundary. Scalp color and roughness
maps both use UV0 for compatibility with the Flutter glTF loader; vertex colors
retain the existing character palette support.

```powershell
python tools/character/tripo/complete_skull.py build/tripo/arm_review/candidate.glb build/tripo/hat_review/candidate.glb
python tools/character/tripo/check_skull_completion.py build/tripo/arm_review/candidate.glb build/tripo/hat_review/candidate.glb --output build/tripo/hat_review/validation.json
```

The installed result has a closed scalp rim and zero animated seam drift over
90 sampled poses. Use the completed output for both shipped GLBs and the review
candidate. `tools/character/tripo/side_review.html` is the maintained review-page
source; copy it to `build/tripo/side_review/index.html` to serve on port 8874.
Its left pane uses `build/tripo/hat_review/scalp_v1.glb` (the first completed
head with the visible shading seam), and its right pane uses the current result.
`head_material_review.html` provides a fixed-camera Three.js PBR inspection
with the same lights as the interactive preview. `capture_material_review.mjs`
captures it in headless Chrome after model decoding finishes. This checks the
actual material highlights; the offline diffuse renderer cannot validate gloss.

## Independent glasses and animated eyes

Run `refine_eyes.py` on the completed skull-v2 asset. The original `Glasses`
mesh also contained the whites, pupils and strips of face skin. Hiding that
node directly therefore exposed holes. The refinement retains the connected
dark frame faces in `Glasses`, gives them a separate charcoal material, and
reconstructs the missing skin in `EyeSocketSkin`. `eye_socket_surface.py`
extends the surrounding head radius, color and normals in cylindrical
coordinates, with smooth elliptical eye openings. Original Body, Scalp, Hat,
texture images, skeleton and ten clips remain unchanged.

`EyeLeft` and `EyeRight` are equal-size meshes parented to Head, with clean
green irises, round pupils and restrained catchlights. `EyeLids` is a separate
Head child with four half/closed morphs. Its open hood stays visible through
the `keepOpenLids` node extra. Both runtime viewers drive the same morph order;
the mobile viewer and review page share `tools/character/character_eyes.js`.
Glasses and hat toggles affect node visibility without restarting playback.

```powershell
python tools/character/tripo/refine_eyes.py build/tripo/hat_review/shading_candidate.glb build/tripo/eye_review/candidate.glb
python tools/character/tripo/check_eye_refinement.py build/tripo/hat_review/shading_candidate.glb build/tripo/eye_review/candidate.glb --output build/tripo/eye_review/validation.json
node tools/character/build_mobile_viewer.mjs
```

Install the candidate to both shipped `glow_rigged.glb` files and the review
candidate after validation. The review's before pane now uses the accepted
skull-v2 model saved as `build/tripo/eye_review/before.glb`. Its result pane has
independent glasses/hat controls, automatic blinking and a manual lid slider.
`capture_material_review.mjs output.png <review-url>?test=1 --verify-controls`
checks the controls and shared eye controller in the actual Three.js page.
The geometry validator checks all original accessors/images, 90 animation
poses, 21 blink amounts, independent morphs and full frontal iris coverage.
Rendered inspection is still required for oblique views and material joins.

## Smooth frame with original material

Run `refine_glasses.py` after the eye refinement. It replaces only the
Glasses primitive with closed, smooth oval rims, bridge and side arms,
retaining the original GlowSkin material and original frame atlas color.
All other meshes, materials, images, animation and existing binary bytes
are preserved. The frame stays attached to Head and uses the same toggle.

```powershell
python tools/character/tripo/refine_glasses.py build/tripo/frame_review/before.glb build/tripo/eye_review/before.glb build/tripo/frame_review/candidate.glb
python tools/character/tripo/check_frame_refinement.py build/tripo/frame_review/before.glb build/tripo/frame_review/candidate.glb --output build/tripo/frame_review/validation.json
```

Validation checks preserved data, closed tubes, normals and 90 animation
poses. Khronos validation reports zero errors and warnings. Front and side
renders verify material and curvature. The review compares eye-v2 in
`frame_review/before.glb` with this result. Use the eye validator on the
prior eye-stage output and the frame validator after this stage.
### Frame v2: fit the white-eye outline

The rim centerlines now use horizontal/vertical radii 0.0615/0.0655 centered
on the eyes, replacing the old sculpt's uneven radial fit. This closes the
lower gap and makes the rings rounder while retaining tube thickness and
original material. The depth fit still follows the face. Bridge and arm
endpoints follow the new rims. `frame_v1.glb` is the comparison baseline;
`round_candidate.glb` is the installed result. `round_validation.json`
checks preserved non-frame data, 90 poses and actual rim bounds. Front and
side renders were inspected, and controls verified in the review page.

`frame_math.py` provides NumPy-only cubic interpolation and quaternion
rotation when SciPy is unavailable. Cubic reproduction and known rotations
are checked independently. The texture sampler uses the same bilinear rule
as the scalp pipeline.
## Expressive mouth

`add_mouth.py` appends a curved mouth surface on the cream muzzle, attached to
Head, with MouthOpen, MouthSmile, MouthSad and MouthRound morph targets. The
surface follows exact frontal Body intersections. Original geometry, materials
and animation tracks remain intact. Each existing clip gets an additional
weight channel, so the JS and Dart animation mixers handle play, pause, seeking
and crossfades without a separate animation clock. Talk uses stylized syllable
pulses; Smile/Happy/Wave/Victory smile, Sad frowns and Laugh opens rhythmically.
This is not audio phoneme recognition or phoneme-level lip sync.

```powershell
python tools/character/tripo/add_mouth.py build/tripo/mouth_review/before.glb build/tripo/mouth_review/candidate.glb
python tools/character/tripo/check_mouth.py build/tripo/mouth_review/before.glb build/tripo/mouth_review/candidate.glb
```

The mouth validator checks unchanged original data, loop continuity and 610
sampled shapes. Khronos reports no errors/warnings. The browser capture tool's
`--verify-mouth` option checks all ten clips, speech opening/closure, smile,
sadness and idle closure. `head_material_review.html?mouth=sad` (or open, smile,
round, laugh) isolates a mouth shape from skeletal poses for visual inspection.
Older deformation validators intentionally reject animated morph channels;
use `check_mouth.py` and the browser checks on this stage.
## Palm-facing Wave and identity colors

`refine_wave.py` changes only the Wave forearm and wrist rotation outputs.
An 80-degree roll is distributed 72/28 percent around the actual bone axes.
`check_wave.py` verifies unchanged geometry, materials, other clips and mouth
morphs, seamless looping, 61 Wave poses and 18 crossfade poses. The installed
model preserves the latest mouth revision.

The skin palette now runs after `color_fragment`, so atlas and vertex colors
are combined before recoloring. This fixes Scalp, EyeSocketSkin and EyeLids
remaining green. EyeLeft/Right receive a runtime skin-region attribute only
on the outer eye rim; the iris and pupil are excluded. Dart and JS both apply
this rule. `character_palette.js` is shared by the mobile bundle and preview.
Rigged models use luminance 0.106 / contrast 0.75 in both renderers.

Studio identity controls show all six existing names and their color swatches.
The review adds the same six choices, with original green on the left and the
selected identity on the right. `--verify-palette` checks all six rendered
colors, skin-region coverage, iris exclusion and preserved playback. Blue and
red renders with partially closed eyelids were inspected. Rebuild the mobile
bundle after JS palette edits and the Flutter studio after Dart edits.

## Continuous head surface

Run `smooth_head.py` on the latest mouth/Wave model. It fits one rounded
surface through Body and Scalp and applies the same spatial deformation to
EyeSocketSkin, whose glasses repair also wraps around the sides and back.
Leaving that backing unchanged creates a raised band even when the main
scalp seam matches. A small clearance prevents coincident patch triangles.
The deformation fades below the head and preserves the front facial features.

The scalp, body head region and socket backing share a consistent skin tone
and roughness. A separate Body atlas preserves the original hat and glasses
material. The existing palette shader still recolors all three skin surfaces.

```powershell
python tools/character/tripo/smooth_head.py build/tripo/head_smooth_review/before.glb build/tripo/head_smooth_review/candidate.glb
python tools/character/tripo/check_head_smoothing.py build/tripo/head_smooth_review/before.glb build/tripo/head_smooth_review/candidate.glb --output build/tripo/head_smooth_review/validation.json
```

The validator preserves original binary data, topology, skin weights, rig,
animations, mouth and accessories, and checks 1,918 shared boundary vertices
through 90 animated poses. The side review compares before/after smoothing
with synchronized colors and accessory controls. Inspect front, both sides
and back, then verify palette/accessory controls before installing the GLB
into both shipped paths and rebuilding the studio.
