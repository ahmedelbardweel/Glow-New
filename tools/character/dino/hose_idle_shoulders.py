"""Rebuild the Idle-only shoulder corrective as a rounded, hose-like bend.

The arms hang ~120 degrees from their bind pose, and the painted shoulder
weights are uneven, so plain skinning folds the skin and leaves a flap behind
the arm. For the Idle pose only, the shoulder zone is re-evaluated with
harmonic (smooth, monotone) Chest/UpperArm weights and dual-quaternion
blending. The shoulder and arm are then Taubin-faired, and each hanging arm is
pulled onto a fitted, slightly tapered elliptic tube with a rounded end, so the
silhouette stays clean under glossy lighting. The difference to linear skinning is
stored in the existing `IdleShoulderSmooth` morph, which only Idle keys on.
Base vertices, skin weights and every other clip are unchanged.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
import struct

import numpy as np
from scipy.sparse import coo_matrix, diags
from scipy.sparse.linalg import spsolve
from scipy.spatial.transform import Rotation

from harmonic_idle_shoulders import (TARGET, append_sparse, matrix, normalize, normals,
                                     quaternion_multiply, read, smoothstep)
from refine_idle_pose import load

ROOT = Path(__file__).resolve().parents[3]
CENTER_X = -0.062
TAPER = .84


def idle_bones(g, blob):
    nodes = copy.deepcopy(g['nodes'])
    idle = next(a for a in g['animations'] if a['name'] == 'Idle')
    for c in idle['channels']:
        path = c['target']['path']
        if path in ('rotation', 'translation', 'scale'):
            nodes[c['target']['node']][path] = read(g, blob, idle['samplers'][c['sampler']]['output'])[0].tolist()
    parents = {c: i for i, n in enumerate(nodes) for c in n.get('children', [])}
    cache = {}

    def world(i):
        if i not in cache:
            local = matrix(nodes[i])
            cache[i] = world(parents[i]) @ local if i in parents else local
        return cache[i]
    skin = g['skins'][0]
    inverse = read(g, blob, skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
    return np.array([world(i) @ ib for i, ib in zip(skin['joints'], inverse)]), np.linalg.inv(inverse)


def dual_quaternion(bones, weights, pos):
    real = Rotation.from_matrix(bones[:, :3, :3]).as_quat()
    dual = .5 * quaternion_multiply(np.column_stack([bones[:, :3, 3], np.zeros(len(bones))]), real)
    reference = real[np.argmax(weights, axis=1)]
    signed = weights * np.where(reference @ real.T < 0, -1.0, 1.0)
    qr, qd = signed @ real, signed @ dual
    length = np.linalg.norm(qr, axis=1, keepdims=True)
    qr, qd = qr / length, qd / length
    conjugate = qr.copy()
    conjugate[:, :3] *= -1
    return Rotation.from_quat(qr).apply(pos) + 2 * quaternion_multiply(qd, conjugate)[:, :3]


def round_cone(q, a, b, r1, r2):
    ba = b - a
    l2 = ba @ ba
    rr = r1 - r2
    a2 = l2 - rr * rr
    pa = q - a
    y = pa @ ba
    z = y - l2
    x2 = np.sum((pa * l2 - y[:, None] * ba) ** 2, axis=1)
    y2, z2 = y * y * l2, z * z * l2
    k = np.sign(rr) * rr * rr * x2
    body = (np.sqrt(np.maximum(x2 * a2 / l2, 0)) + y * rr) / l2 - r1
    out = np.where(np.sign(y) * a2 * y2 < k, np.sqrt(x2 + y2) / l2 - r1, body)
    return np.where(np.sign(z) * a2 * z2 > k, np.sqrt(x2 + z2) / l2 - r2, out)


def tubify(points, arm, strength):
    """Pull a hanging arm onto a fitted, slightly tapered elliptic tube."""
    centroid = points[arm].mean(0)
    _, _, axes = np.linalg.svd(points[arm] - centroid, full_matrices=False)
    if axes[0][1] > 0:
        axes[0] = -axes[0]
    local = (points - centroid) @ axes.T
    t = local[:, 0]
    top, tip = t[arm].min(), t[arm].max()
    length = tip - top
    mid = arm & (t > top + .25 * length) & (t < tip - .3 * length)
    spread = local[mid][:, 1:].std(0)
    scale = np.array([1, 1, spread[0] / spread[1]])
    q = local * scale
    radial = np.linalg.norm(q[:, 1:], axis=1)
    slope, offset = np.polyfit(t[mid], radial[mid], 1)
    r_top = slope * (top + .2 * length) + offset
    r_tip = np.clip(slope * (tip - .15 * length) + offset, .5 * r_top, TAPER * r_top)
    a = np.array([top + .2 * length, 0, 0])
    b = np.array([tip - r_tip, 0, 0])
    projected = q.copy()
    for _ in range(4):
        d = round_cone(projected, a, b, r_top, r_tip)
        grad = np.zeros_like(projected)
        for axis in range(3):
            step = np.zeros(3)
            step[axis] = 1e-4
            grad[:, axis] = (round_cone(projected + step, a, b, r_top, r_tip) - d) / 2e-4 + \
                (d - round_cone(projected - step, a, b, r_top, r_tip)) / 2e-4
        projected -= d[:, None] * normalize(grad)
    blend = (strength * smoothstep(top + .08 * length, top + .32 * length, t) * arm)[:, None]
    target = (projected / scale) @ axes + centroid
    return points + blend * (target - points)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input', type=Path, default=ROOT / 'assets/3d/glow_mascot.glb')
    p.add_argument('--output', type=Path, default=ROOT / 'build/idle_hand/candidate.glb')
    p.add_argument('--start', type=float, default=-0.07, help='zone start along the arm axis (m)')
    p.add_argument('--end', type=float, default=0.17, help='zone end along the arm axis (m)')
    p.add_argument('--radius', type=float, default=0.14)
    p.add_argument('--fairing', type=int, default=60, help='Taubin passes over the shoulder and whole arm')
    p.add_argument('--arm-threshold', type=float, default=.02)
    p.add_argument('--tube', type=float, default=.9, help='pull toward a fitted tapered tube (0 = off)')
    p.add_argument('--tube-fairing', type=int, default=30)
    p.add_argument('--rings', type=int, default=3)
    args = p.parse_args()

    original = args.input.read_bytes()
    g, start, _ = load(original)
    old_g = copy.deepcopy(g)
    original_blob = original[start:start + g['buffers'][0]['byteLength']]
    blob = bytearray(original_blob)
    mesh = g['meshes'][0]
    if mesh.get('extras', {}).get('targetNames') != [TARGET]:
        raise ValueError(f'Expected mesh 0 to carry only the {TARGET} morph.')
    prim = mesh['primitives'][0]
    pos = read(g, blob, prim['attributes']['POSITION']).astype(float)
    base_normals = read(g, blob, prim['attributes']['NORMAL']).astype(float)
    faces = read(g, blob, prim['indices']).reshape(-1, 3).astype(int)
    joints = read(g, blob, prim['attributes']['JOINTS_0']).astype(int)
    raw = read(g, blob, prim['attributes']['WEIGHTS_0']).astype(float)
    names = [g['nodes'][i]['name'] for i in g['skins'][0]['joints']]
    weights = np.zeros((len(pos), len(names)))
    np.add.at(weights, (np.repeat(np.arange(len(pos)), 4), joints.ravel()), raw.ravel())
    bones, bind = idle_bones(g, blob)
    blended = np.einsum('nj,jab->nab', weights, bones)
    linear = blended[:, :3, :3]
    lbs = np.einsum('nij,nj->ni', linear, pos) + blended[:, :3, 3]

    # Weld UV seams so both sides of a seam get the same displacement.
    _, first, inverse = np.unique(np.round(pos / 1e-6).astype(np.int64), axis=0,
                                  return_index=True, return_inverse=True)
    inverse = inverse.reshape(-1)
    welded_faces = inverse[faces]
    edges = np.concatenate([welded_faces[:, [0, 1]], welded_faces[:, [1, 2]], welded_faces[:, [2, 0]]])
    edges = np.unique(np.sort(edges, axis=1), axis=0)
    edges = edges[edges[:, 0] != edges[:, 1]]
    m = len(first)
    adjacency = coo_matrix((np.ones(2 * len(edges)), (np.r_[edges[:, 0], edges[:, 1]], np.r_[edges[:, 1], edges[:, 0]])),
                           shape=(m, m)).tocsr()
    laplacian = diags(np.asarray(adjacency.sum(1)).ravel()) - adjacency
    rest = pos[first]

    smooth_weights = weights.copy()
    zone = np.zeros(m, bool)
    chest = names.index('Chest')
    for side in ('Left', 'Right'):
        arm_ids = [names.index(side + k) for k in ('UpperArm', 'ForeArm', 'Hand')]
        upper = arm_ids[0]
        shoulder = bind[upper][:3, 3]
        axis = normalize(bind[arm_ids[1]][:3, 3] - shoulder)
        arm = weights[:, arm_ids].sum(1)[first]
        along = (rest - shoulder) @ axis
        radial = np.linalg.norm((rest - shoulder) - along[:, None] * axis, axis=1)
        same_side = (rest[:, 0] - CENTER_X) * np.sign(shoulder[0] - CENTER_X) > .06
        free = same_side & (along > args.start) & (along < args.end) & (radial < args.radius)
        idx, fixed = np.flatnonzero(free), np.flatnonzero(~free)
        harmonic = arm.copy()
        harmonic[idx] = spsolve(laplacian[idx][:, idx].tocsc(), -(laplacian[idx][:, fixed] @ arm[fixed]))
        harmonic = np.clip(harmonic, 0, 1)[inverse]
        sel = free[inverse]
        row = np.zeros((sel.sum(), len(names)))
        row[:, chest] = 1 - harmonic[sel]
        row[:, upper] = harmonic[sel]
        smooth_weights[sel] = row
        zone |= free
        print(side, 'zone vertices', len(idx), flush=True)

    posed = dual_quaternion(bones, smooth_weights, pos)
    arm_joints = [names.index(s + k) for s in ('Left', 'Right') for k in ('UpperArm', 'ForeArm', 'Hand')]
    region = zone | (weights[:, arm_joints].sum(1)[first] > args.arm_threshold)
    for _ in range(args.rings):
        region |= (adjacency @ region.astype(float)) > 0
    averaging = diags(1 / np.maximum(np.asarray(adjacency.sum(1)).ravel(), 1)) @ adjacency
    welded = posed[first].copy()
    def fair(points, passes):
        for _ in range(passes):
            for k in (.5, -.53):
                points = np.where(region[:, None], points + k * (averaging @ points - points), points)
        return points

    welded = fair(welded, args.fairing)
    if args.tube > 0:
        for side in ('Left', 'Right'):
            ids = [names.index(side + k) for k in ('UpperArm', 'ForeArm', 'Hand')]
            arm = weights[:, ids].sum(1)[first] > .5
            welded = tubify(welded, arm, args.tube)
        welded = fair(welded, args.tube_fairing)
    target = welded[inverse]
    touched = region[inverse]
    target[~touched] = lbs[~touched]

    delta_bind = np.linalg.solve(linear, (target - lbs)[..., None])[..., 0]
    delta_bind[~touched] = 0
    delta_bind[np.linalg.norm(delta_bind, axis=1) < 1e-7] = 0

    shaded = normals(welded, welded_faces)
    for _ in range(4):
        shaded = normalize(shaded + .4 * (averaging @ shaded - shaded))
    posed_normals = shaded[inverse]
    normal_bind = normalize(np.einsum('nji,nj->ni', linear, posed_normals))
    delta_normal = np.where(touched[:, None], normal_bind - base_normals, 0)
    if not (np.isfinite(delta_bind).all() and np.isfinite(delta_normal).all()):
        raise ValueError('Non-finite corrective values.')

    prim['targets'] = [dict(POSITION=append_sparse(g, blob, delta_bind), NORMAL=append_sparse(g, blob, delta_normal))]

    assert bytes(blob[:len(original_blob)]) == original_blob
    assert g['animations'] == old_g['animations'] and g['nodes'] == old_g['nodes']
    assert g['skins'] == old_g['skins'] and g['materials'] == old_g['materials']
    g['buffers'][0]['byteLength'] = len(blob)
    encoded = json.dumps(g, separators=(',', ':'), ensure_ascii=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    blob.extend(b'\0' * (-len(blob) % 4))
    output = (struct.pack('<4sIIII', b'glTF', 2, 28 + len(encoded) + len(blob), len(encoded), 0x4e4f534a) +
              encoded + struct.pack('<II', len(blob), 0x004e4942) + blob)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output)
    report = dict(beforeSha256=hashlib.sha256(original).hexdigest(), afterSha256=hashlib.sha256(output).hexdigest(),
                  target=TARGET, movedVertices=int(np.count_nonzero(np.linalg.norm(delta_bind, axis=1))),
                  maxSurfaceOffset=float(np.max(np.linalg.norm(target - lbs, axis=1))),
                  maxBindOffset=float(np.max(np.linalg.norm(delta_bind, axis=1))),
                  addedBytes=len(output) - len(original), activeClips=['Idle'])
    args.output.with_suffix('.validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
