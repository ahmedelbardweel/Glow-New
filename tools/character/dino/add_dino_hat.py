"""Append a toggleable fedora (+ round ears) to the dinosaur mascot GLB.

Materials are named ``Hat`` / ``HatBand`` so the studio can show/hide and
recolor them without touching body skin. Vertices are rigid to Chest.

Run from tools/character:
    python dino/add_dino_hat.py ../../assets/3d/glow_mascot.glb
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from pygltflib import (
    GLTF2, Attributes, Material, PbrMetallicRoughness, Primitive,
)

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rig_port_frontal import append_accessor, read_accessor  # noqa: E402

TAU = math.tau
# Brim above brows; raised flush into the crown to seal any seam gap.
CX, CY, CZ = -.062, .925, .025
SCALE = .385
# Slight negative lift pulls the crown down onto the brim to close the crack.
CROWN_LIFT = -.012
CROWN_INFLATE = 1.03
# Tip the whole hat slightly forward so it doesn't lean to the back.
TIP_FWD = .22  # radians about local +X


def _xform(x, y, z, *, crown=False):
    # Level source coords around the brim, tip forward, then map into dino space.
    y0, z0 = y - 2.555, z
    c, s = math.cos(TIP_FWD), math.sin(TIP_FWD)
    y1 = y0 * c - z0 * s
    z1 = y0 * s + z0 * c
    inflate = CROWN_INFLATE if crown else 1.0
    return (
        CX + SCALE * x * inflate,
        CY + SCALE * y1 + (CROWN_LIFT if crown else 0.0),
        CZ + SCALE * z1 * inflate,
    )


def _norm(v):
    n = np.linalg.norm(v, axis=-1, keepdims=True)
    return v / np.maximum(n, 1e-8)


def _sphere(center, radius, lon=28, lat=18):
    positions, normals, indices = [], [], []
    cx, cy, cz = center
    rx, ry, rz = radius if isinstance(radius, tuple) else (radius, radius, radius)
    for j in range(lat + 1):
        v = j / lat
        phi = (v - .5) * math.pi
        for i in range(lon + 1):
            u = i / lon
            th = u * TAU
            nx = math.cos(phi) * math.cos(th)
            ny = math.sin(phi)
            nz = math.cos(phi) * math.sin(th)
            positions.append((cx + rx * nx, cy + ry * ny, cz + rz * nz))
            normals.append((nx, ny, nz))
    for j in range(lat):
        for i in range(lon):
            a = j * (lon + 1) + i
            b = a + lon + 1
            indices.extend((a, b, a + 1, a + 1, b, b + 1))
    return np.array(positions, np.float32), np.array(normals, np.float32), np.array(indices, np.uint32)


def _surface(fn, us, vs, reverse=False):
    positions, normals, indices = [], [], []
    for j in range(vs + 1):
        for i in range(us + 1):
            positions.append(fn(i / us, j / vs))
    positions = np.array(positions, np.float64)
    normals = np.zeros_like(positions)
    for j in range(vs):
        for i in range(us):
            a = j * (us + 1) + i
            b = a + us + 1
            tris = ((a, b, a + 1), (a + 1, b, b + 1))
            if reverse:
                tris = tuple(t[::-1] for t in tris)
            for tri in tris:
                indices.extend(tri)
                p0, p1, p2 = positions[list(tri)]
                n = np.cross(p1 - p0, p2 - p0)
                for idx in tri:
                    normals[idx] += n
    return positions.astype(np.float32), _norm(normals).astype(np.float32), np.array(indices, np.uint32)


def build_hat_parts():
    parts = []  # (name, color, roughness, positions, normals, indices)

    def brim_y(phi):
        # Level brim — no front/back droop (that made the hat lean backward).
        return 2.555

    def brim_top(u, v):
        phi = u * TAU
        rx, rz = .64 + .14 * v, .52 + .11 * v
        return _xform(rx * math.cos(phi), brim_y(phi) + .012 + .004 * math.sin(math.pi * v), rz * math.sin(phi))

    def brim_bottom(u, v):
        x, y, z = brim_top(u, v)
        return x, y - .040 * SCALE, z

    def crown(u, v):
        phi = u * TAU
        rx = .625 - .150 * v + .016 * math.sin(math.pi * v)
        rz = .500 - .135 * v + .012 * math.sin(math.pi * v)
        x = rx * math.cos(phi)
        z = rz * math.sin(phi)
        y = 2.565 + .420 * v + .010 * math.sin(math.pi * v)
        return _xform(x, y, z, crown=True)

    def hat_top(u, v):
        phi = u * TAU
        radius = 1 - v
        x, z = .475 * radius * math.cos(phi), .365 * radius * math.sin(phi)
        y = 2.985 + .012 * (1 - radius * radius)
        return _xform(x, y, z, crown=True)

    def band(u, v):
        x, y, z = crown(u, .020 + .135 * v)
        return (
            CX + (x - CX) * 1.03,
            y,
            CZ + (z - CZ) * 1.03,
        )

    hat_geo = []
    for fn, us, vs, rev in (
        (brim_top, 72, 5, False),
        (brim_bottom, 72, 5, True),
        (crown, 80, 28, False),
        (hat_top, 80, 16, False),
    ):
        hat_geo.append(_surface(fn, us, vs, reverse=rev))

    def merge(geos):
        pos, nor, idx, offset = [], [], [], 0
        for p, n, i in geos:
            pos.append(p); nor.append(n); idx.append(i + offset); offset += len(p)
        return np.concatenate(pos), np.concatenate(nor), np.concatenate(idx)

    # Matte felt for the whole hat + ear balls (same look, no fuzzy mismatch).
    felt = (0.22, 0.22, 0.24, 1.)
    felt_rough = 0.88
    hp, hn, hi = merge(hat_geo)
    parts.append(('Hat', felt, felt_rough, hp, hn, hi))

    bp, bn, bi = _surface(band, 80, 6, reverse=False)
    parts.append(('HatBand', (0.10, 0.10, 0.11, 1.), 0.80, bp, bn, bi))

    # Smooth round ears perched on the crown top (same felt material).
    for sign in (-1, 1):
        ear_c = _xform(sign * .28, 3.06, .02, crown=True)
        ear_r = .092 * SCALE
        ear_c = (ear_c[0], ear_c[1] + ear_r * .65, ear_c[2])
        ep, en, ei = _sphere(ear_c, ear_r, lon=36, lat=24)
        parts.append(('Hat', felt, felt_rough, ep, en, ei))

    return parts


def _chest_index(gltf) -> int:
    order = [gltf.nodes[j].name for j in gltf.skins[0].joints]
    return order.index('Chest')


def add_hat(path: Path) -> None:
    gltf = GLTF2().load_binary(str(path))
    # Drop any previous hat primitives so the script is idempotent.
    mesh = gltf.meshes[0]
    old_mats = list(gltf.materials or [])
    new_mats, remap = [], {}
    for i, mat in enumerate(old_mats):
        if mat.name in ('Hat', 'HatBand', 'HatTrim'):
            continue
        remap[i] = len(new_mats)
        new_mats.append(mat)
    gltf.materials = new_mats
    keep = []
    for prim in mesh.primitives:
        mid = prim.material
        if mid is not None and mid not in remap:
            continue  # dropped hat primitive
        if mid is not None:
            prim.material = remap[mid]
        keep.append(prim)
    mesh.primitives = keep

    chest = _chest_index(gltf)
    binary = bytearray(gltf.binary_blob())
    for name, color, rough, positions, normals, indices in build_hat_parts():
        count = len(positions)
        joints = np.zeros((count, 4), np.uint16)
        weights = np.zeros((count, 4), np.float32)
        joints[:, 0] = chest
        weights[:, 0] = 1.0
        mat = Material(
            name=name, doubleSided=True, alphaMode='OPAQUE',
            pbrMetallicRoughness=PbrMetallicRoughness(
                baseColorFactor=list(color), metallicFactor=0., roughnessFactor=rough))
        gltf.materials.append(mat)
        attrs = Attributes(
            POSITION=append_accessor(gltf, binary, positions, 5126, 'VEC3', target=34962, bounds=True),
            NORMAL=append_accessor(gltf, binary, normals, 5126, 'VEC3', target=34962),
            JOINTS_0=append_accessor(gltf, binary, joints, 5123, 'VEC4', target=34962),
            WEIGHTS_0=append_accessor(gltf, binary, weights, 5126, 'VEC4', target=34962),
        )
        setattr(attrs, '_GLOW_SKIN_REGION',
                append_accessor(gltf, binary, np.ones(count, np.float32), 5126, 'SCALAR', target=34962))
        mesh.primitives.append(Primitive(
            attributes=attrs, material=len(gltf.materials) - 1,
            indices=append_accessor(gltf, binary, indices, 5125, 'SCALAR', target=34963)))
        print(name, 'verts', count, 'tris', len(indices) // 3)

    extras = dict(gltf.extras or {})
    extras['hat'] = 'fedora-ears-v1'
    gltf.extras = extras
    gltf.buffers[0].byteLength = len(binary)
    gltf.set_binary_blob(bytes(binary))
    gltf.save_binary(str(path))
    print('saved', path)


if __name__ == '__main__':
    target = Path(sys.argv[1] if len(sys.argv) > 1 else '../../assets/3d/glow_mascot.glb')
    add_hat(target.resolve())
