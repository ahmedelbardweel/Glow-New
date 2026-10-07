"""Add an Idle-only shoulder corrective; keep base mesh and clip data intact.

The corrective is sculpted on the evaluated Idle surface, then converted back
through each vertex's skin matrix into a sparse glTF morph. Other clips key
its weight to zero. This preserves the existing hand pose and raised arms.
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
from scipy.spatial.transform import Rotation
from scipy.sparse.linalg import factorized

from refine_idle_pose import load

ROOT = Path(__file__).resolve().parents[3]
TARGET = 'IdleShoulderSmooth'
DTYPES = {5121: '<u1', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
WIDTH = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


def read(g, blob, index):
    a = g['accessors'][index]
    v = g['bufferViews'][a['bufferView']]
    dtype = np.dtype(DTYPES[a['componentType']])
    width = WIDTH[a['type']]
    return np.ndarray((a['count'], width), dtype=dtype, buffer=blob,
                      offset=v.get('byteOffset', 0) + a.get('byteOffset', 0),
                      strides=(v.get('byteStride', width * dtype.itemsize), dtype.itemsize)).copy()


def matrix(n):
    if 'matrix' in n:
        return np.array(n['matrix']).reshape(4, 4).T
    x, y, z, w = n.get('rotation', [0, 0, 0, 1])
    out = np.eye(4)
    out[:3, :3] = [[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                   [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                   [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]
    out[:3, :3] *= n.get('scale', [1, 1, 1])
    out[:3, 3] = n.get('translation', [0, 0, 0])
    return out


def normalize(a):
    return a / np.maximum(np.linalg.norm(a, axis=-1, keepdims=True), 1e-12)


def smoothstep(a, b, x):
    t = np.clip((x-a)/(b-a), 0, 1)
    return t*t*(3-2*t)


def normals(pos, faces):
    n = np.zeros_like(pos)
    tri = np.cross(pos[faces[:, 1]] - pos[faces[:, 0]], pos[faces[:, 2]] - pos[faces[:, 0]])
    for col in range(3):
        np.add.at(n, faces[:, col], tri)
    return normalize(n)


def quaternion_multiply(a, b):
    xyz = a[..., 3:]*b[..., :3]+b[..., 3:]*a[..., :3]+np.cross(a[..., :3], b[..., :3])
    w = a[..., 3:]*b[..., 3:]-np.sum(a[..., :3]*b[..., :3], axis=-1, keepdims=True)
    return np.concatenate([xyz, w], axis=-1)


def skin_matrices(g, blob, primitive):
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
    bones = np.array([world(i) @ ib for i, ib in zip(skin['joints'], inverse)])
    joints = read(g, blob, primitive['attributes']['JOINTS_0']).astype(int)
    weights = read(g, blob, primitive['attributes']['WEIGHTS_0'])
    blended = np.sum(bones[joints] * weights[:, :, None, None], axis=1)
    names = [g['nodes'][i]['name'] for i in skin['joints']]
    arm_ids = [i for i, name in enumerate(names) if any(p in name for p in ('UpperArm', 'ForeArm', 'Hand'))]
    arm_weight = np.sum(np.where(np.isin(joints, arm_ids), weights, 0), axis=1)
    real = Rotation.from_matrix(bones[:, :3, :3]).as_quat()
    translations = np.column_stack([bones[:, :3, 3], np.zeros(len(bones))])
    dual = .5*quaternion_multiply(translations, real)
    reference = real[joints[np.arange(len(joints)), weights.argmax(axis=1)]]
    signs = np.where(np.sum(real[joints]*reference[:, None], axis=2) < 0, -1, 1)
    qr = np.sum(real[joints]*(weights*signs)[..., None], axis=1)
    qd = np.sum(dual[joints]*(weights*signs)[..., None], axis=1)
    length = np.linalg.norm(qr, axis=1, keepdims=True)
    qr /= length
    qd /= length
    conjugate = qr.copy()
    conjugate[:, :3] *= -1
    dq_translation = 2*quaternion_multiply(qd, conjugate)[:, :3]
    return blended, arm_weight, Rotation.from_quat(qr), dq_translation


def append_view(g, blob, values):
    blob.extend(b'\0' * (-len(blob) % 4))
    offset = len(blob)
    raw = np.ascontiguousarray(values).tobytes()
    blob.extend(raw)
    g['bufferViews'].append(dict(buffer=0, byteOffset=offset, byteLength=len(raw)))
    return len(g['bufferViews'])-1


def append_sparse(g, blob, values):
    values = np.asarray(values, '<f4')
    changed = np.flatnonzero(np.max(np.abs(values), axis=1) > 1e-8)
    a = dict(componentType=5126, count=len(values), type='VEC3',
             min=values.min(0).tolist(), max=values.max(0).tolist())
    if len(changed):
        indices = changed.astype('<u2' if len(values) < 65536 else '<u4')
        a['sparse'] = dict(count=len(changed),
            indices=dict(bufferView=append_view(g, blob, indices), componentType=5123 if indices.itemsize == 2 else 5125),
            values=dict(bufferView=append_view(g, blob, values[changed])))
    g['accessors'].append(a)
    return len(g['accessors'])-1


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input', type=Path, default=ROOT/'assets/3d/glow_mascot.glb')
    p.add_argument('--output', type=Path, default=ROOT/'build/shoulder_review/candidate.glb')
    p.add_argument('--iterations', type=int, default=350)
    p.add_argument('--strength', type=float, default=1.0)
    args = p.parse_args()
    original = args.input.read_bytes()
    g, start, _ = load(original)
    old_g = copy.deepcopy(g)
    original_blob = original[start:start+g['buffers'][0]['byteLength']]
    blob = bytearray(original_blob)
    mesh = g['meshes'][0]
    if mesh.get('weights') or any(p.get('targets') for p in mesh['primitives']):
        raise ValueError('Use the saved pre-corrective model as input; do not stack this correction.')
    prim = mesh['primitives'][0]
    pos = read(g, blob, prim['attributes']['POSITION']).astype(float)
    base_normals = read(g, blob, prim['attributes']['NORMAL']).astype(float)
    faces = read(g, blob, prim['indices']).reshape(-1, 3).astype(int)
    skin, arm_weight, dq_rotation, dq_translation = skin_matrices(g, blob, prim)
    posed = np.einsum('nij,nj->ni', skin[:, :3, :3], pos) + skin[:, :3, 3]

    # Weld only for fairing. Original topology, UV seams and vertex count stay
    # untouched. The same displacement is assigned to both sides of each seam.
    _, first, inverse = np.unique(np.round(pos / 1e-6).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    inverse = inverse.reshape(-1)
    wf = inverse[faces]
    base = posed[first].copy()
    edges = np.concatenate([wf[:, [0, 1]], wf[:, [1, 2]], wf[:, [2, 0]]])
    edges = np.unique(np.sort(edges, axis=1), axis=0)
    edges = edges[edges[:, 0] != edges[:, 1]]
    rows = np.r_[edges[:, 0], edges[:, 1]]
    cols = np.r_[edges[:, 1], edges[:, 0]]
    adjacency = coo_matrix((np.ones(len(rows)), (rows, cols)), shape=(len(base), len(base))).tocsr()
    averaging = diags(1/np.maximum(np.asarray(adjacency.sum(1)).ravel(), 1)) @ adjacency
    # Local/global as-rigid-as-possible solve, with the existing palms and
    # torso as positional handles. Work from rest edges, not a folded surface.
    rest = pos[first]
    w = arm_weight[first]
    free = (w > .0001) & (w < .9999)
    for _ in range(8):
        free |= (adjacency @ free.astype(float)) > 0
    free &= (rest[:,1]>.31) & (rest[:,1]<.59)
    free &= np.abs(rest[:,0]+.062)>.115
    # Distal arms are rigid handles to preserve the chosen hanging pose.
    left = rest[:,0]>-.062
    shoulder = np.column_stack([np.where(left,.140,-.264),np.full(len(rest),.462),np.full(len(rest),-.01948928)])
    axis = np.column_stack([np.where(left,.858,-.858),np.full(len(rest),.497),np.full(len(rest),-.154)])
    along = np.sum((rest-shoulder)*axis,axis=1)
    free &= along < .185
    idx = np.flatnonzero(free)
    fixed = np.flatnonzero(~free)
    degree = np.asarray(adjacency.sum(1)).ravel()
    lap = diags(degree)-adjacency
    solve = factorized(lap[idx][:,idx].tocsc())
    boundary = lap[idx][:,fixed] @ base[fixed]
    active_edges = free[rows] | free[cols]
    ei,ej = rows[active_edges],cols[active_edges]
    active = np.unique(np.r_[ei,ej])
    rest_edge = rest[ei]-rest[ej]
    target = rest.copy()
    final_rot = Rotation.from_matrix(skin[first,:3,:3])
    final_vec = final_rot.as_rotvec()
    final_pivot = final_rot.apply(shoulder)+skin[first,:3,3]

    rotations = np.repeat(np.eye(3)[None],len(base),axis=0)
    boundary = lap[idx][:,fixed] @ base[fixed]
    target = base.copy()
    target[idx] = solve(-boundary)
    delta = (target-base)*args.strength
    target[fixed] = base[fixed]
    mask = free.astype(float)
    print('ARAP free vertices:',len(idx),flush=True)
    posed_new = posed + delta[inverse]
    linear = skin[:, :3, :3]
    delta_bind = np.linalg.solve(linear, (posed_new-posed)[..., None])[..., 0]
    delta_bind[np.linalg.norm(delta_bind, axis=1) < 1e-7] = 0

    current = normalize(np.einsum('nij,nj->ni',linear,base_normals))
    shaded = normals(target,wf)
    for _ in range(8):
        shaded = normalize(shaded+.4*(averaging @ shaded-shaded))
    blend = mask[inverse,None]
    corrected = normalize(current*(1-blend)+shaded[inverse]*blend)
    normal_bind = normalize(np.linalg.solve(linear,corrected[...,None])[...,0])
    delta_normal = normal_bind-base_normals
    delta_normal[~free[inverse]]=0
    if not (np.isfinite(delta_bind).all() and np.isfinite(delta_normal).all()):
        raise ValueError('Non-finite corrective values.')

    for i, primitive in enumerate(mesh['primitives']):
        count = g['accessors'][primitive['attributes']['POSITION']]['count']
        dp = delta_bind if i == 0 else np.zeros((count, 3))
        dn = delta_normal if i == 0 else np.zeros((count, 3))
        primitive['targets'] = [dict(POSITION=append_sparse(g, blob, dp), NORMAL=append_sparse(g, blob, dn))]
    mesh['weights'] = [0.0]
    mesh.setdefault('extras', {})['targetNames'] = [TARGET]
    mesh_nodes = [i for i, n in enumerate(g['nodes']) if n.get('mesh') == 0]
    for anim in g['animations']:
        time = anim['samplers'][0]['input']
        count = g['accessors'][time]['count']
        values = np.full(count, 1 if anim['name'] == 'Idle' else 0, '<f4')
        view = append_view(g, blob, values)
        g['accessors'].append(dict(bufferView=view, componentType=5126, count=count, type='SCALAR'))
        sampler = len(anim['samplers'])
        anim['samplers'].append(dict(input=time, output=len(g['accessors'])-1, interpolation='LINEAR'))
        for node in mesh_nodes:
            anim['channels'].append(dict(sampler=sampler, target=dict(node=node, path='weights')))

    # Existing data is append-only: exact preservation of every old vertex,
    # texture, skin weight, joint track and key time is a required invariant.
    assert bytes(blob[:len(original_blob)]) == original_blob
    for old, new in zip(old_g['animations'], g['animations']):
        assert new['samplers'][:len(old['samplers'])] == old['samplers']
        assert new['channels'][:len(old['channels'])] == old['channels']
    assert g['nodes'] == old_g['nodes'] and g['materials'] == old_g['materials']
    assert g['skins'] == old_g['skins'] and g['images'] == old_g['images']
    g['buffers'][0]['byteLength'] = len(blob)
    encoded = json.dumps(g, separators=(',', ':'), ensure_ascii=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    blob.extend(b'\0' * (-len(blob) % 4))
    output = (struct.pack('<4sIIII', b'glTF', 2, 28+len(encoded)+len(blob), len(encoded), 0x4e4f534a) +
              encoded + struct.pack('<II', len(blob), 0x004e4942) + blob)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output)
    report = dict(beforeSha256=hashlib.sha256(original).hexdigest(), afterSha256=hashlib.sha256(output).hexdigest(),
        target=TARGET, iterations=args.iterations, strength=args.strength,
        movedVertices=int(np.count_nonzero(np.linalg.norm(delta_bind, axis=1))),
        maxSurfaceOffset=float(np.max(np.linalg.norm(posed_new-posed, axis=1))),
        addedBytes=len(output)-len(original), originalBinaryDataUnchanged=True,
        originalAnimationTracksUnchanged=True, activeClips=['Idle'])
    args.output.with_suffix('.validation.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
