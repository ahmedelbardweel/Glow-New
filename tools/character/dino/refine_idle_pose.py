"""Set the relaxed arm pose without rebuilding the dinosaur or other clips.

Only four existing Idle tracks are edited: the two shoulder rotations and
translations. Forearm/hand rotations remain identity, keeping the sculpted
arm continuous. No vertices, normals, weights, textures or bind matrices move.

Run with --write to publish; otherwise validate the proposed change in memory.
The binary-isolation check is mandatory, including when publishing.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
import struct

import numpy as np

ROOT = Path(__file__).resolve().parents[3]
MODEL = ROOT / 'assets/3d/glow_mascot.glb'

# Mirrored local rotations, tuned against the supplied front reference and
# checked from the side. Keep the paw/forearm together to avoid a wrist fold.
HANG = 1.86
AXIAL_ROLL = math.radians(-85)
FORWARD_PITCH = -0.12
SHOULDER_DROP = 0.055


def load(data):
    magic, version, length = struct.unpack_from('<4sII', data)
    if magic != b'glTF' or version != 2 or length != len(data):
        raise ValueError('Expected a complete glTF 2 binary.')
    json_size, json_type = struct.unpack_from('<II', data, 12)
    bin_header = 20 + json_size
    bin_size, bin_type = struct.unpack_from('<II', data, bin_header)
    if json_type != 0x4E4F534A or bin_type != 0x004E4942:
        raise ValueError('Expected JSON and BIN chunks.')
    if bin_header + 8 + bin_size != len(data):
        raise ValueError('Unexpected extra GLB chunks.')
    return json.loads(data[20:bin_header]), bin_header + 8, json_size


def axis_quat(axis, angle):
    axis = np.asarray(axis, dtype=np.float64)
    axis /= np.linalg.norm(axis)
    return np.r_[axis * math.sin(angle / 2), math.cos(angle / 2)]


def multiply(a, b):
    av, bv = a[:3], b[:3]
    return np.r_[a[3] * bv + b[3] * av + np.cross(av, bv),
                 a[3] * b[3] - np.dot(av, bv)]


def accessor_range(g, index, bin_start):
    a = g['accessors'][index]
    v = g['bufferViews'][a['bufferView']]
    width = {'VEC3': 3, 'VEC4': 4}[a['type']]
    if (a['componentType'] != 5126 or a.get('sparse') or
            v.get('byteStride', 4 * width) != 4 * width or v.get('buffer', 0) != 0):
        raise ValueError(f'Accessor {index} is not a packed float track.')
    start = bin_start + v.get('byteOffset', 0) + a.get('byteOffset', 0)
    size = a['count'] * width * 4
    return start, start + size, width


def refine(original):
    g, bin_start, json_size = load(original)
    old_json = copy.deepcopy(g)
    nodes = {n['name']: i for i, n in enumerate(g['nodes']) if 'name' in n}
    idle = next(a for a in g['animations'] if a['name'] == 'Idle')
    tracks = {(g['nodes'][c['target']['node']]['name'], c['target']['path']):
              idle['samplers'][c['sampler']] for c in idle['channels']}
    data = bytearray(original)
    changed = []
    output_indices = set()
    for side, sign in [('Left', 1), ('Right', -1)]:
        # This rig has translation-only rest joints. Reject another skeleton
        # rather than silently interpreting its local coordinate system wrong.
        for part in ('UpperArm', 'ForeArm', 'Hand'):
            node = g['nodes'][nodes[side + part]]
            if node.get('rotation', [0, 0, 0, 1]) != [0, 0, 0, 1] or node.get('scale', [1, 1, 1]) != [1, 1, 1]:
                raise ValueError('The rest arm axes have changed.')
        for part in ('ForeArm', 'Hand'):
            idx = tracks[(side + part, 'rotation')]['output']
            start, end, _ = accessor_range(g, idx, bin_start)
            if not np.allclose(np.frombuffer(original[start:end], '<f4').reshape(-1, 4), [0, 0, 0, 1], atol=1e-7):
                raise ValueError('Expected the existing continuous Idle arm.')
        axis = (np.asarray(g['nodes'][nodes[side + 'ForeArm']]['translation']) +
                np.asarray(g['nodes'][nodes[side + 'Hand']]['translation']))
        rotation = multiply(axis_quat([1, 0, 0], FORWARD_PITCH),
                            multiply(axis_quat([0, 0, 1], -sign * HANG),
                                     axis_quat(axis, sign * AXIAL_ROLL)))
        rotation /= np.linalg.norm(rotation)
        translation = np.asarray(g['nodes'][nodes[side + 'UpperArm']]['translation']) + [0, -SHOULDER_DROP, 0]
        for path, value in [('rotation', rotation), ('translation', translation)]:
            sampler = tracks[(side + 'UpperArm', path)]
            if sampler.get('interpolation', 'LINEAR') not in ('LINEAR', 'STEP'):
                raise ValueError('Cubic spline tracks require tangent handling.')
            index = sampler['output']
            output_indices.add(index)
            a = g['accessors'][index]
            start, end, width = accessor_range(g, index, bin_start)
            values = np.tile(value.astype('<f4'), (a['count'], 1))
            assert values.shape[1] == width and values.nbytes == end - start
            data[start:end] = values.tobytes()
            for bound, row in [('min', values.min(0)), ('max', values.max(0))]:
                if bound in a:
                    a[bound] = row.tolist()
            changed.append((start, end, index, side + 'UpperArm', path))

    # Prove no other animation or model accessor aliases edited storage.
    allowed = [(s - bin_start, e - bin_start) for s, e, *_ in changed]
    for index, a in enumerate(g['accessors']):
        if index in output_indices or 'bufferView' not in a:
            continue
        view = g['bufferViews'][a['bufferView']]
        begin = view.get('byteOffset', 0)
        end = begin + view['byteLength']
        if any(begin < hi and end > lo for lo, hi in allowed):
            raise ValueError(f'Edited storage shared with accessor {index}.')
    for anim in g['animations']:
        if anim is idle:
            continue
        if any(s[k] in output_indices for s in anim['samplers'] for k in ('input', 'output')):
            raise ValueError(f'Edited accessor shared with {anim["name"]}.')

    # All BIN bytes outside these four tracks must remain exactly identical.
    comparison = bytearray(data)
    for start, end, *_ in changed:
        comparison[start:end] = original[start:end]
    assert comparison == original, 'Unexpected edit outside Idle arm tracks.'
    restored = copy.deepcopy(g)
    for index in output_indices:
        restored['accessors'][index] = old_json['accessors'][index]
    assert restored == old_json, 'Unexpected change to model metadata.'

    # Accessor offsets are relative to BIN and stay fixed. JSON bounds may need
    # a few more characters, so resize its padding without relocating BIN data.
    encoded = json.dumps(g, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    json_size = max(json_size, (len(encoded) + 3) // 4 * 4)
    encoded = encoded.ljust(json_size, b' ')
    binary_chunk = data[bin_start - 8:]
    length = 20 + json_size + len(binary_chunk)
    data = (struct.pack('<4sIIII', b'glTF', 2, length, json_size, 0x4E4F534A) +
            encoded + binary_chunk)
    load(data)
    report = {
        'beforeSha256': hashlib.sha256(original).hexdigest(),
        'afterSha256': hashlib.sha256(data).hexdigest(),
        'bytes': len(data),
        'pose': {'hang': HANG, 'rollDegrees': -85, 'forwardPitch': FORWARD_PITCH,
                 'shoulderDrop': SHOULDER_DROP},
        'editedTracks': [dict(node=n, path=p, accessor=i) for _, _, i, n, p in changed],
        'otherClipsByteIdentical': [a['name'] for a in g['animations'] if a is not idle],
        'geometryTexturesWeightsBindMatricesByteIdentical': True,
        'idleLegsFaceForearmsHandsByteIdentical': True,
    }
    return bytes(data), report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=MODEL)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    original = args.input.read_bytes()
    updated, report = refine(original)
    if args.write:
        if args.input.read_bytes() != original:
            raise RuntimeError('Model changed during validation; refusing to overwrite.')
        temporary = args.input.with_suffix('.idle.tmp')
        temporary.write_bytes(updated)
        temporary.replace(args.input)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'written': args.write, **report}, indent=2))


if __name__ == '__main__':
    main()
