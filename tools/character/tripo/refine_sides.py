"""Refine the new Tripo rig's flanks and arm weights without rebaking its atlas.

Run against an untouched input, never repeatedly against the output:
  python tools/character/tripo/refine_sides.py before.glb candidate.glb
Preserves topology, UVs, embedded images, skeleton, and the ten clip names.
"""
import argparse
import json
import struct
from pathlib import Path

import numpy as np
from scipy.sparse import coo_matrix
from scipy.spatial import cKDTree
from scipy.spatial.transform import Rotation

from validate_deformation import Rig


def ramp(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def anatomical_weights(v, names):
    """Continuous local fields: overlapping shells get the same deformation.

    The old harmonic solve had no seeds on intermediate bones. Explicit local
    chains prevent a hand or toe from ever controlling a torso vertex.
    """
    x, y, z = v.T
    ax = np.abs(x)
    weights = np.zeros((len(v), len(names)))
    index = {name: i for i, name in enumerate(names)}

    def chain(coord, knots, bones):
        w = np.zeros_like(weights)
        w[:, index[bones[0]]] = 1
        for lo, hi, bone, nxt in zip(knots[:-1], knots[1:], bones[:-1], bones[1:]):
            blend = ramp(lo, hi, coord)
            take = np.minimum(w[:, index[bone]], blend)
            w[:, index[bone]] -= take
            w[:, index[nxt]] += take
        return w

    # The protruding muzzle belongs to Head, including its low hanging lip.
    face = ramp(.08, .17, z) * ramp(.35, .44, y)
    cy = y * (1 - face) + np.maximum(y, .57) * face
    weights = chain(cy, [.23, .29, .36, .43, .49, .55],
                    ['Hips', 'Spine', 'Spine1', 'Spine2', 'Neck', 'Head'])
    # Soft, compact attachment envelope, not an infinite x-only arm mask.
    attachment = (ramp(.235, .30, y) * (1 - ramp(.415, .48, y))
                  * (1 - ramp(.065, .145, z)))
    # Beyond the shoulder, the whole cross-section is arm, including fingers
    # below the elbow centerline. Do not fade distal vertices back to Spine.
    distal = ramp(.225, .29, ax)
    arm_gate = ramp(.145, .255, ax) * (attachment * (1 - distal) + distal)
    arm_gate *= 1 - ramp(.46, .54, y)  # nearby head/ears are never arm
    for side, sign in [('Left', 1), ('Right', -1)]:
        gate = arm_gate * (x * sign > 0)
        arm = chain(ax, [.245, .355, .425],
                    [side + 'Arm', side + 'ForeArm', side + 'Hand'])
        weights = weights * (1 - gate[:, None]) + arm * gate[:, None]
    leg_gate = (1 - ramp(.13, .225, y)) * ramp(.015, .075, ax)
    for side, sign in [('Left', 1), ('Right', -1)]:
        gate = leg_gate * (x * sign > 0)
        leg = chain(-y, [-.14, -.075, -.02],
                    [side + 'UpLeg', side + 'Leg', side + 'Foot'])
        weights = weights * (1 - gate[:, None]) + leg * gate[:, None]
    tail = ramp(.085, .20, -z) * (1 - ramp(.24, .34, y))
    weights *= 1 - tail[:, None]
    weights[:, index['Tail']] += tail
    return weights / weights.sum(1, keepdims=True)


def fair_sides(v, faces):
    """Low-strength Taubin fairing with a feathered anatomical mask.

    Weld only exact position duplicates so UV seams cannot split. Leave the
    face, belly badge, fingertips, legs and tail out of the sculpt region.
    """
    points, reverse = np.unique(v, axis=0, return_inverse=True)
    f = reverse[faces]
    edges = np.unique(np.sort(np.concatenate([f[:, [0, 1]], f[:, [1, 2]],
                                            f[:, [2, 0]]]), axis=1), axis=0)
    edges = edges[edges[:, 0] != edges[:, 1]]
    a, b = edges.T
    adj = coo_matrix((np.ones(2 * len(a)), (np.r_[a, b], np.r_[b, a])),
                     shape=(len(points), len(points))).tocsr()
    degree = np.maximum(np.asarray(adj.sum(1)).ravel(), 1)
    x, y, z = points.T
    mask = (ramp(.10, .155, np.abs(x)) * (1 - ramp(.37, .43, np.abs(x)))
            * ramp(.17, .24, y) * (1 - ramp(.41, .47, y))
            * (1 - ramp(.035, .11, z)) * ramp(-.19, -.11, z))
    original = points.copy()
    for _ in range(10):
        for factor in [.48, -.50]:
            mean = adj @ points / degree[:, None]
            points += factor * mask[:, None] * (mean - points)
    # A hard displacement bound protects the approved silhouette.
    delta = points - original
    delta *= np.minimum(1, .003 / np.maximum(np.linalg.norm(delta, axis=1), 1e-12))[:, None]
    return (original + delta)[reverse]


def normals(v, f):
    _, first, reverse = np.unique(v, axis=0, return_index=True, return_inverse=True)
    n = np.zeros((len(first), 3))
    cross = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    for k in range(3):
        np.add.at(n, reverse[f[:, k]], cross)
    length = np.linalg.norm(n, axis=1)
    valid = length > 1e-12
    n[valid] /= length[valid, None]
    # A few original vertices belong only to collapsed triangles. Give them
    # the nearest valid surface normal rather than exporting a zero vector.
    if not valid.all():
        nearest = cKDTree(v[first][valid]).query(v[first][~valid])[1]
        n[~valid] = n[valid][nearest]
    return n[reverse]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        raise ValueError('Use a separate output; preserve the original')
    rig = Rig(args.input)
    g = rig.doc
    if g.get('extras', {}).get('sideRefinement'):
        raise ValueError('Input is already refined; use the untouched base GLB')
    blob = bytearray(rig.binary)

    def write(i, values):
        a = g['accessors'][i]
        view = g['bufferViews'][a['bufferView']]
        dtype = {5126: '<f4', 5123: '<u2', 5125: '<u4'}[a['componentType']]
        data = np.asarray(values, dtype=dtype)
        old = rig.accessor(i)
        assert data.shape == old.shape, (data.shape, old.shape)
        assert view.get('byteStride', data.shape[1] * data.dtype.itemsize) == data.shape[1] * data.dtype.itemsize
        off = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        blob[off:off + data.nbytes] = data.tobytes()
        if 'min' in a:
            a['min'] = data.min(0).tolist()
        if 'max' in a:
            a['max'] = data.max(0).tolist()

    body = next(n for n in g['nodes'] if n.get('name') == 'Body')
    prim = g['meshes'][body['mesh']]['primitives'][0]
    attr = prim['attributes']
    v = rig.accessor(attr['POSITION']).astype(float)
    f = rig.accessor(prim['indices']).reshape(-1, 3)
    sculpted = fair_sides(v, f)
    joint_names = [g['nodes'][i]['name'] for i in g['skins'][body['skin']]['joints']]
    dense = anatomical_weights(v, joint_names)
    joints = np.argsort(-dense, axis=1, kind='stable')[:, :4]
    weights = np.take_along_axis(dense, joints, axis=1)
    weights /= weights.sum(1, keepdims=True)
    joints[weights == 0] = 0
    write(attr['POSITION'], sculpted)
    write(attr['NORMAL'], normals(sculpted, f))
    write(attr['JOINTS_0'], joints)
    write(attr['WEIGHTS_0'], weights)
    # Retain accessory shading, repairing only zero normals inherited from
    # collapsed source triangles (two each on the hat and glasses).
    for mesh in g['meshes']:
        for part in mesh['primitives']:
            attrs = part['attributes']
            if attrs['NORMAL'] == attr['NORMAL']:
                continue
            normal = rig.accessor(attrs['NORMAL']).copy()
            valid = np.linalg.norm(normal, axis=1) > 1e-12
            if not valid.all():
                points = rig.accessor(attrs['POSITION'])
                near = cKDTree(points[valid]).query(points[~valid])[1]
                normal[~valid] = normal[valid][near]
                write(attrs['NORMAL'], normal)

    # Two complete gentle waves in a 2s loop: position and velocity match.
    wave = lambda t, period, phase=0: np.sin(2 * np.pi * (t / period + phase))
    for anim in g['animations']:
        if anim['name'] not in ('Wave', 'Idle'):
            continue
        for channel in anim['channels']:
            if channel['target']['path'] != 'rotation':
                continue
            name = g['nodes'][channel['target']['node']]['name']
            sampler = anim['samplers'][channel['sampler']]
            t = rig.accessor(sampler['input']).ravel()
            zero = np.zeros_like(t)
            if anim['name'] == 'Wave':
                params = {
                    'RightArm': (zero - 6, zero, zero - 22),
                    'RightForeArm': (zero, zero, -58 + 12 * wave(t, 1)),
                    'RightHand': (zero, zero, 7 * wave(t, 1, .2)),
                    'Head': (zero - 2, zero, zero - 4),
                    'Spine1': (zero, zero, zero + 1.5),
                    'Tail': (zero, 5 * wave(t, 2), zero),
                }
            else:
                params = {
                    'LeftArm': (zero, zero, -55 + 1.5 * wave(t, 4)),
                    'RightArm': (zero, zero, 55 - 1.5 * wave(t, 4)),
                    'Spine1': (.8 * wave(t, 4), zero, zero),
                    'Head': (-.8 * wave(t, 4), zero, 1.2 * wave(t, 4, .25)),
                    'Tail': (zero, 4 * wave(t, 4), zero),
                }
            if name in params:
                # Same Rz * Ry * Rx composition as the original assembly tool.
                q = Rotation.from_euler('xyz', np.column_stack(params[name]), degrees=True).as_quat()
                write(sampler['output'], q)
    g.setdefault('extras', {})['sideRefinement'] = {
        'version': 2, 'weights': 'anatomical-local-fields',
        'sculptMaxDisplacement': float(np.linalg.norm(sculpted - v, axis=1).max()),
        'wavePeriod': 1.0,
    }
    js = json.dumps(g, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    blob += b'\x00' * (-len(blob) % 4)
    output = (struct.pack('<III', 0x46546c67, 2, 28 + len(js) + len(blob))
              + struct.pack('<II', len(js), 0x4e4f534a) + js
              + struct.pack('<II', len(blob), 0x004e4942) + blob)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output)
    print(json.dumps(g['extras']['sideRefinement'], indent=2))
    print('Saved', args.output)


if __name__ == '__main__':
    main()
