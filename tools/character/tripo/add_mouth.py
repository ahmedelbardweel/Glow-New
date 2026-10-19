"""Add a Head-attached expressive mouth v3: correctly located at the green-cream seam.

Fixes over v1/v2:
  - Correct anatomical placement: located at the natural seam between the green snout
    and cream lower jaw (y ≈ 0.509), horizontally centered between the nostrils.
  - Asymmetric jaw opening: lower jaw drops naturally while upper lip stays stable under the snout.
  - Stylized teeth & tongue: pearly white upper teeth accent and warm 3D tongue inside cavity.
  - Seamless skin blending: outer lip ring blends to dark green on top and cream on bottom.
  - Rich cavity shading: dark maroon/crimson depth shading.

Usage:
    python tools/character/tripo/add_mouth_v3.py <input.glb> <output.glb>
"""
import argparse
import json
import struct
from pathlib import Path
# pyrefly: ignore[missing-import]
import numpy as np
from validate_deformation import Rig


def build(source, destination):
    rig = Rig(source)
    g = rig.doc
    blob = bytearray(rig.binary)
    assert 'ExpressiveMouth' not in rig.names

    body = next(p for p in rig.primitives if p['name'] == 'Body')
    tri = body['vertices'][body['faces']]
    # Select triangles covering the entire snout and upper jaw region
    tri = tri[
        (tri[:, :, 2].min(1) > 0.15)
        & (tri[:, :, 1].max(1) > 0.44)
        & (tri[:, :, 1].min(1) < 0.56)
        & (abs(tri[:, :, 0]).min(1) < 0.15)
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
            good = (u >= -1e-4) & (v >= -1e-4) & (u + v <= 1.0001)
            if good.any():
                z = tri[:, 0, 2] + u * (tri[:, 1, 2] - tri[:, 0, 2]) + v * (tri[:, 2, 2] - tri[:, 0, 2])
                out.append(float(np.max(z[good])))
            else:
                # Clamp to nearest triangle point for sub-millimeter seam gaps
                u_c = np.clip(u, 0, 1)
                v_c = np.clip(v, 0, 1)
                w_c = np.clip(1.0 - u_c - v_c, 0, 1)
                total = u_c + v_c + w_c
                u_c /= total
                v_c /= total
                w_c /= total
                proj_xy = a * w_c[:, None] + (a + ab) * u_c[:, None] + (a + ac) * v_c[:, None]
                dist2 = np.sum((proj_xy - q) ** 2, axis=1)
                best = np.argmin(dist2)
                z_proj = tri[best, 0, 2] * w_c[best] + tri[best, 1, 2] * u_c[best] + tri[best, 2, 2] * v_c[best]
                out.append(float(z_proj))
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

    # ── Polar mesh geometry ──
    segments = 120
    rings = 14
    params = [(0.0, 0.0)] + [
        (r / rings, t * 2 * np.pi / segments)
        for r in range(1, rings + 1)
        for t in range(segments)
    ]
    params = np.array(params)
    rad, ang = params.T

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

    sin_a = np.sin(ang)
    cos_a = np.cos(ang)

    # Base Y location and curvature fitting the natural seam from cheek to cheek:
    # y(x) = 0.5110 + 1.86 * x^2  (for x in [-0.092, +0.092])
    BASE_Y = 0.5110
    SEAM_COEFF = 1.86

    def shape(width, h_up, h_down, curve=0.0, depth_offset=0.0032):
        """Generate mouth shape positioned across the full green-cream seam.
        
        Args:
            width: horizontal half-width of the mouth (spans across the snout/cheeks)
            h_up: vertical half-height of upper lip
            h_down: vertical half-height of lower lip
            curve: additional smile/sad curvature beyond natural seam
            depth_offset: projection offset in front of body
        """
        x = width * rad * cos_a
        # Natural seam curvature of the snout line: y_seam = 1.86 * x^2
        seam_curvature = SEAM_COEFF * (x ** 2)
        
        # Asymmetric vertical displacement: upper lip stable, lower jaw drops
        v_h = np.where(sin_a >= 0, h_up, h_down)
        # Extra curvature (curve > 0 lifts corners higher, curve < 0 droops corners)
        extra_curve = curve * ((x / max(width, 1e-6)) ** 2)
        y = BASE_Y + seam_curvature + extra_curve + v_h * rad * sin_a

        xy = np.c_[x, y]
        z = surface(xy) + depth_offset
        return np.c_[xy, z]

    # ── Morph target states ──
    # Full width mouth spanning the entire green-cream seam:
    # 0: Idle: closed razor-thin slit along the entire seam line (width = 0.091)
    # 1: MouthOpen: lower jaw drops naturally across the width (h_down = 0.024)
    # 2: MouthSmile: wide joyful smile lifting the cheek corners
    # 3: MouthSad: corners turn down
    # 4: MouthRound: pursed O-shape for speaking vowels
    states = [
        shape(0.091, 0.0008, 0.0010, curve=0.000),   # Idle
        shape(0.088, 0.0038, 0.0240, curve=0.000),   # MouthOpen
        shape(0.096, 0.0018, 0.0035, curve=0.014),   # MouthSmile
        shape(0.083, 0.0010, 0.0015, curve=-0.013),  # MouthSad
        shape(0.052, 0.0100, 0.0170, curve=0.000),   # MouthRound
    ]

    head = rig.names['Head']
    origin = rig.rest_world[head][:3, 3]

    # ── Vertex colors: cavity, teeth, tongue, and skin blend ──
    # Deep cavity base color: dark maroon/shadow
    color = np.tile([0.035, 0.007, 0.010], (len(rad), 1))

    # Upper teeth accent: pearly white teeth arch across the upper jaw
    teeth_horizontal = np.clip(1.0 - (abs(cos_a) / 0.80) ** 4, 0, 1)
    teeth_radial = np.clip(1.0 - abs(rad - 0.65) / 0.22, 0, 1)
    teeth_vertical = np.clip((sin_a - 0.18) / 0.45, 0, 1)
    teeth_weight = teeth_horizontal * teeth_radial * teeth_vertical
    teeth_color = np.array([0.96, 0.96, 0.93])
    color = color * (1.0 - teeth_weight[:, None]) + teeth_color * teeth_weight[:, None]

    # Tongue: warm fleshy pink arch in lower jaw
    tongue_horizontal = np.clip(1.0 - (abs(cos_a) / 0.76) ** 4, 0, 1)
    tongue_radial = np.clip(1.0 - abs(rad - 0.54) / 0.28, 0, 1)
    tongue_vertical = np.clip((-sin_a - 0.15) / 0.50, 0, 1)
    tongue_weight = tongue_horizontal * tongue_radial * tongue_vertical
    tongue_color = np.tile([0.76, 0.20, 0.26], (len(rad), 1))
    center_highlight = np.clip(1.0 - abs(cos_a) * 2.2, 0, 1) * 0.14
    tongue_color[:, 0] += center_highlight
    tongue_color[:, 1] += center_highlight * 0.4
    tongue_color[:, 2] += center_highlight * 0.4
    color = color * (1.0 - tongue_weight[:, None]) + tongue_color * tongue_weight[:, None]

    # Darker depth shading towards the interior center
    interior_shade = np.clip(1.0 - rad * 1.5, 0, 1)
    color *= (1.0 - interior_shade[:, None] * 0.45)

    # Lip borders:
    # Outer lip ring (rad > 0.78)
    lip_ring = np.clip((rad - 0.78) / 0.14, 0, 1)
    # Upper lip border: dark olive/shadow under the green snout
    upper_lip_color = np.array([0.08, 0.13, 0.06])
    # Lower lip border: warm cream tone matching the jaw
    lower_lip_color = np.array([0.74, 0.69, 0.58])
    lip_blend = np.where(sin_a[:, None] >= 0, upper_lip_color, lower_lip_color)
    color = color * (1.0 - lip_ring[:, None]) + lip_blend * lip_ring[:, None]

    # Very outer blend rim (rad > 0.91): blend seamlessly into surrounding skin
    outer_ring = np.clip((rad - 0.91) / 0.09, 0, 1)
    upper_skin = np.array([0.12, 0.22, 0.10]) # green snout skin
    lower_skin = np.array([0.85, 0.80, 0.69]) # cream jaw skin
    skin_blend = np.where(sin_a[:, None] >= 0, upper_skin, lower_skin)
    color = color * (1.0 - outer_ring[:, None]) + skin_blend * outer_ring[:, None]

    def normals(p):
        n = np.zeros_like(p)
        cross = np.cross(p[faces[:, 1]] - p[faces[:, 0]], p[faces[:, 2]] - p[faces[:, 0]])
        for i in range(3):
            np.add.at(n, faces[:, i], cross)
        lengths = np.linalg.norm(n, axis=1, keepdims=True)
        n = np.where(lengths > 1e-8, n / lengths, n)
        return n

    # Winding check for frontal orientation
    faces = faces[:, [0, 2, 1]]
    if np.mean(normals(states[0])[:, 2]) < 0:
        faces = faces[:, [0, 2, 1]]

    ns = [normals(s) for s in states]

    # Material: double-sided with subtle sheen
    material = len(g['materials'])
    g['materials'].append(dict(
        name='MouthInterior',
        doubleSided=True,
        pbrMetallicRoughness=dict(
            baseColorFactor=[1, 1, 1, 1],
            roughnessFactor=0.82,
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

    # ── Animation tracks ──
    for animation in g['animations']:
        duration = max(float(rig.accessor(s['input']).max()) for s in animation['samplers'])
        times = np.linspace(0, duration, int(duration * 30) + 1)
        weights = np.zeros((len(times), 4))
        name = animation['name']

        if name == 'Talk':
            phase = times / duration
            # Natural speech cadence: bursts of syllables
            syllable_cadence = np.maximum(0, np.sin(2 * np.pi * 5.5 * phase)) ** 1.3
            envelope = 0.75 + 0.25 * np.sin(2 * np.pi * phase) ** 2
            weights[:, 0] = syllable_cadence * envelope
            # Alternate vowel shapes
            weights[:, 3] = (1 - syllable_cadence) * np.maximum(0, np.sin(2 * np.pi * 3.8 * phase)) * 0.40
            # Subtle pleasant expression while talking
            weights[:, 1] = 0.15
        elif name == 'Laugh':
            weights[:, 0] = 0.35 + 0.55 * np.sin(np.pi * 4 * times / duration) ** 2
            weights[:, 1] = 0.80
        elif name in ('Smile', 'Happy', 'Victory', 'Wave'):
            smile_amount = {'Smile': 1.0, 'Happy': 0.88, 'Victory': 0.75, 'Wave': 0.60}[name]
            weights[:, 1] = smile_amount
            if name == 'Happy':
                weights[:, 0] = 0.15 + 0.12 * np.sin(2 * np.pi * times / duration) ** 2
        elif name == 'Sad':
            weights[:, 2] = 1.0
        elif name == 'Thinking':
            weights[:, 3] = 0.20
            weights[:, 2] = 0.15

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
        version=3,
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
