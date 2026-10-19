"""Add a Head-attached expressive mouth v2: deeper cavity, visible lips.

Improvement over v1:
  - Idle mouth is wider and has a visible opening (not a flat line).
  - A distinct dark lip-line gives definition between green and cream.
  - Cavity shading is darker and deeper, giving a 3D feel.
  - Morph targets have more pronounced shapes for expressiveness.
  - Tongue color is richer and more visible when the mouth opens.
  - Lip border ring is thicker for a professional look.

Usage:
    python tools/character/tripo/add_mouth_v2.py <input.glb> <output.glb>
"""
import argparse
import json
import struct
from pathlib import Path
import numpy as np
from validate_deformation import Rig


def build(source, destination):
    rig = Rig(source)
    g = rig.doc
    blob = bytearray(rig.binary)
    assert 'ExpressiveMouth' not in rig.names

    body = next(p for p in rig.primitives if p['name'] == 'Body')
    tri = body['vertices'][body['faces']]
    # Select triangles in the muzzle region for surface projection
    tri = tri[
        (tri[:, :, 2].min(1) > .15)
        & (tri[:, :, 1].max(1) > .42)
        & (tri[:, :, 1].min(1) < .51)
        & (abs(tri[:, :, 0]).min(1) < .1)
    ]

    def surface(xy):
        """Project 2D mouth points onto the existing muzzle surface."""
        out = []
        a = tri[:, 0, :2]
        ab = tri[:, 1, :2] - a
        ac = tri[:, 2, :2] - a
        den = ab[:, 0] * ac[:, 1] - ab[:, 1] * ac[:, 0]
        den = np.where(abs(den) < 1e-12, np.nan, den)
        for q in xy:
            d = q - a
            u = (d[:, 0] * ac[:, 1] - d[:, 1] * ac[:, 0]) / den
            v = (ab[:, 0] * d[:, 1] - ab[:, 1] * d[:, 0]) / den
            good = (u >= -1e-5) & (v >= -1e-5) & (u + v <= 1.00001)
            assert good.any(), f'Mouth outside muzzle: {q}'
            z = tri[:, 0, 2] + u * (tri[:, 1, 2] - tri[:, 0, 2]) + v * (tri[:, 2, 2] - tri[:, 0, 2])
            out.append(np.max(z[good]))
        return np.array(out)

    def acc(values, kind, dtype='<f4', component=5126, target=None):
        data = np.asarray(values, dtype=dtype)
        blob.extend(b'\0' * (-len(blob) % 4))
        view = dict(buffer=0, byteOffset=len(blob), byteLength=data.nbytes)
        if target:
            view['target'] = target
        vi = len(g['bufferViews'])
        g['bufferViews'].append(view)
        blob.extend(data.tobytes())
        item = dict(bufferView=vi, componentType=component, count=len(data), type=kind)
        if kind in ('VEC3', 'SCALAR'):
            item.update(
                min=data.reshape(len(data), -1).min(0).tolist(),
                max=data.reshape(len(data), -1).max(0).tolist(),
            )
        ai = len(g['accessors'])
        g['accessors'].append(item)
        return ai

    # ── Mouth geometry: denser mesh for smoother shape ──
    segments = 120   # was 96 — smoother perimeter
    rings = 14       # was 10 — more depth rings for cavity feel
    params = [(0., 0.)] + [
        (r / rings, t * 2 * np.pi / segments)
        for r in range(1, rings + 1)
        for t in range(segments)
    ]
    params = np.array(params)
    rad, ang = params.T

    # Build triangle indices
    faces = []
    for i in range(segments):
        faces.append([0, 1 + i, 1 + (i + 1) % segments])
    for row in range(rings - 1):
        for i in range(segments):
            a = 1 + row * segments + i
            b = 1 + row * segments + (i + 1) % segments
            c = a + segments
            d = b + segments
            faces.extend([[a, c, b], [b, c, d]])
    faces = np.array(faces)

    def shape(width, height, curve, depth_offset=0.0035):
        """Generate mouth shape projected onto the muzzle surface.
        
        Args:
            width: horizontal half-width of the mouth
            height: vertical half-height (controls how open the mouth is)
            curve: curvature of the mouth line (positive = smile, negative = frown)
            depth_offset: how far in front of the muzzle surface (negative = inside)
        """
        x = width * rad * np.cos(ang)
        y = .472 + curve * ((x / max(width, 1e-6)) ** 2 - .45) + height * rad * np.sin(ang)
        xy = np.c_[x, y]
        z = surface(xy) + depth_offset
        # Push interior vertices inward for cavity depth
        interior_factor = np.clip(1.0 - rad * 1.8, 0, 1)  # inner rings go deeper
        z -= interior_factor * 0.012  # 12mm inward for inner cavity
        return np.c_[xy, z]

    # ── Morph target shapes ──
    # Key change: Idle mouth has more visible height (0.008 vs 0.0016)
    # This creates a visible slit rather than a flat line
    states = [
        shape(.065, .008, .008, depth_offset=0.004),   # Idle: visible closed mouth with slight smile
        shape(.063, .032, .008, depth_offset=0.003),    # MouthOpen: wider opening for talk
        shape(.072, .006, .025, depth_offset=0.004),    # MouthSmile: wide curved smile
        shape(.058, .005, -.022, depth_offset=0.004),   # MouthSad: downturned
        shape(.035, .028, 0, depth_offset=0.003),       # MouthRound: pursed/O shape
    ]

    head = rig.names['Head']
    origin = rig.rest_world[head][:3, 3]

    # ── Vertex colors: deeper cavity + defined lip border ──
    # Tongue: visible pink at bottom interior
    tongue_factor = np.clip((-rad * np.sin(ang) - .15) / .40, 0, 1) * (1 - rad ** 6)
    # Deep interior: dark red/brown
    interior = np.clip(1.0 - rad * 1.3, 0, 1)
    # Base cavity color: very dark red-brown
    color = np.tile([.015, .004, .006], (len(rad), 1))
    # Add tongue pink in the lower interior
    color += tongue_factor[:, None] * np.array([.20, .03, .04])
    # Make deep interior even darker
    color *= (1.0 - interior[:, None] * 0.5)

    # Lip border: distinct darker ring at the perimeter
    lip_edge = np.clip((rad - .78) / .15, 0, 1)
    # Outer lip color: dark brownish-pink for definition
    lip_color = np.array([.10, .055, .03])
    # Blend to lip color at the edge
    color = color * (1 - lip_edge[:, None]) + lip_color * lip_edge[:, None]

    # Very outer rim: slightly lighter to blend with skin
    outer_blend = np.clip((rad - .92) / .08, 0, 1)
    skin_blend_color = np.array([.14, .09, .045])
    color = color * (1 - outer_blend[:, None]) + skin_blend_color * outer_blend[:, None]

    def normals(p):
        n = np.zeros_like(p)
        cross = np.cross(p[faces[:, 1]] - p[faces[:, 0]], p[faces[:, 2]] - p[faces[:, 0]])
        for i in range(3):
            np.add.at(n, faces[:, i], cross)
        lengths = np.linalg.norm(n, axis=1, keepdims=True)
        n = np.where(lengths > 1e-8, n / lengths, n)
        return n

    # Ensure correct face winding
    faces = faces[:, [0, 2, 1]]
    if np.mean(normals(states[0])[:, 2]) < 0:
        faces = faces[:, [0, 2, 1]]

    ns = [normals(s) for s in states]

    # Material: unlit vertex-colored interior
    material = len(g['materials'])
    g['materials'].append(dict(
        name='MouthInterior',
        doubleSided=True,
        pbrMetallicRoughness=dict(
            baseColorFactor=[1, 1, 1, 1],
            roughnessFactor=.90,
            metallicFactor=0,
        ),
    ))

    prim = dict(
        attributes=dict(
            POSITION=acc(states[0] - origin, 'VEC3', target=34962),
            NORMAL=acc(ns[0], 'VEC3', target=34962),
            COLOR_0=acc(color, 'VEC3', target=34962),
        ),
        indices=acc(faces.reshape(-1), 'SCALAR', '<u4', 5125, 34963),
        material=material,
    )
    prim['targets'] = [
        dict(
            POSITION=acc(s - states[0], 'VEC3', target=34962),
            NORMAL=acc(n - ns[0], 'VEC3', target=34962),
        )
        for s, n in zip(states[1:], ns[1:])
    ]

    mesh = len(g['meshes'])
    g['meshes'].append(dict(
        name='ExpressiveMouth',
        primitives=[prim],
        weights=[0, 0, 0, 0],
        extras=dict(targetNames=['MouthOpen', 'MouthSmile', 'MouthSad', 'MouthRound']),
    ))

    node = len(g['nodes'])
    g['nodes'].append(dict(name='ExpressiveMouth', mesh=mesh))
    g['nodes'][head].setdefault('children', []).append(node)

    # ── Animation weight channels ──
    for animation in g['animations']:
        duration = max(float(rig.accessor(s['input']).max()) for s in animation['samplers'])
        times = np.linspace(0, duration, int(duration * 30) + 1)
        weights = np.zeros((len(times), 4))
        name = animation['name']

        if name == 'Talk':
            phase = times / duration
            # More dramatic open/close cycle
            pulse = np.maximum(0, np.sin(2 * np.pi * 5 * phase)) ** 1.2
            envelope = .80 + .20 * np.sin(2 * np.pi * phase) ** 2
            weights[:, 0] = pulse * envelope
            weights[:, 3] = (1 - pulse) * np.maximum(0, np.sin(2 * np.pi * 3.5 * phase)) * .38
        elif name == 'Laugh':
            weights[:, 0] = .35 + .50 * np.sin(np.pi * 4 * times / duration) ** 2
            weights[:, 1] = .75
        elif name in ('Smile', 'Happy', 'Victory', 'Wave'):
            smile_amount = {'Smile': 1, 'Happy': .85, 'Victory': .75, 'Wave': .55}[name]
            weights[:, 1] = smile_amount
            if name == 'Happy':
                weights[:, 0] = .15 + .12 * np.sin(2 * np.pi * times / duration) ** 2
        elif name == 'Sad':
            weights[:, 2] = 1
        elif name == 'Thinking':
            weights[:, 3] = .15

        sampler = len(animation['samplers'])
        animation['samplers'].append(dict(
            input=acc(times, 'SCALAR'),
            output=acc(weights.reshape(-1), 'SCALAR'),
            interpolation='LINEAR',
        ))
        animation['channels'].append(dict(
            sampler=sampler,
            target=dict(node=node, path='weights'),
        ))

    g.setdefault('extras', {})['mouthRefinement'] = dict(
        version=2,
        node=node,
        targets=['MouthOpen', 'MouthSmile', 'MouthSad', 'MouthRound'],
        speech='stylized cadence driven by clip/playback time',
    )

    g['buffers'][0]['byteLength'] = len(blob)
    js = json.dumps(g, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    blob += b'\0' * (-len(blob) % 4)
    Path(destination).write_bytes(
        struct.pack('<III', 0x46546c67, 2, 28 + len(js) + len(blob))
        + struct.pack('<II', len(js), 0x4e4f534a)
        + js
        + struct.pack('<II', len(blob), 0x004e4942)
        + blob
    )
    print(json.dumps(g['extras']['mouthRefinement']))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input')
    parser.add_argument('output')
    args = parser.parse_args()
    assert Path(args.input).resolve() != Path(args.output).resolve()
    build(args.input, args.output)
