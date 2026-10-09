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

## Rebuild

Use the unrefined original, SHA-256
`d85aa0b2831105a718e4abdde4da7c1dfef4f83e0b4a92e29feF2bb01f3314c78`
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
