"""
add_jaw_bone_fixed.py

Safer jaw/mouth rig patch for assets/3d/glow_mascot.glb.

Main fixes:
1) Builds the Jaw bone in the correct mesh-local position.
2) Computes a correct inverse bind matrix from real node transforms.
3) Parents Jaw under Head/Neck/Chest when available.
4) Uses a much tighter lower-lip influence band with low weight.
5) Uses smaller mouth cavity/tongue geometry and gentler jaw animation.
6) Preserves the Jaw bind/rest rotation when adding animation.
7) Creates a backup before modifying the GLB.

Run from project root:
    pip install numpy pygltflib
    python tools/character/add_jaw_bone_fixed.py
"""

from __future__ import annotations

import math
import shutil
from pathlib import Path

import numpy as np
from pygltflib import (
    GLTF2,
    Node,
    AnimationChannel,
    AnimationChannelTarget,
    AnimationSampler,
    Accessor,
    BufferView,
    Primitive,
    Attributes,
    Material,
    PbrMetallicRoughness,
)


# ---------------------------------------------------------------------------
# TUNING — these values are intentionally conservative to avoid face collapse
# ---------------------------------------------------------------------------

BODY_X = -0.062

# Mouth/lip region in mesh-local coordinates
MOUTH_HALF = 0.103
MOUTH_Y0 = 0.580

# Hinge position in MESH-LOCAL coordinates.
# Kept close to the mouth instead of far below the muzzle.
JAW_POS = np.array([BODY_X, 0.575, 0.190], dtype=np.float64)

# Only a very thin strip of the lower lip is allowed to follow Jaw.
LIP_BAND_DEPTH = 0.0045
MAX_JAW_WEIGHT = 0.045

# Limit influence to the actual front/mouth region.
MIN_FRONT_Z = 0.255
MIN_LIP_Y = 0.560

# Interior geometry — smaller and pushed inside the mouth.
CAVITY_RADII = (0.094, 0.031, 0.008)
CAVITY_CENTER = (BODY_X, 0.562, 0.300)

TONGUE_RADII = (0.044, 0.011, 0.010)
TONGUE_CENTER = (BODY_X, 0.552, 0.308)


# ---------------------------------------------------------------------------
# Accessor / binary helpers
# ---------------------------------------------------------------------------

def read_acc(gltf: GLTF2, idx: int) -> np.ndarray:
    a = gltf.accessors[idx]
    bv = gltf.bufferViews[a.bufferView]
    blob = gltf.binary_blob()

    dtype = {
        5126: np.float32,
        5123: np.uint16,
        5125: np.uint32,
        5121: np.uint8,
    }[a.componentType]

    comp = {
        "SCALAR": 1,
        "VEC2": 2,
        "VEC3": 3,
        "VEC4": 4,
        "MAT4": 16,
    }[a.type]

    offset = (bv.byteOffset or 0) + (a.byteOffset or 0)