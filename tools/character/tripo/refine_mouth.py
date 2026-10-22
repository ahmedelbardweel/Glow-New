"""Replace the painted mouth with split lips, a moving jaw and recessed details.

Run on the current completed-head GLB. Existing data is retained, with local
Body topology refinement and four shared mouth morphs added to the jaw,
cavity, teeth and tongue. No external modelling dependencies are needed.
"""
import argparse
import json
import struct
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from port_lip_surface import split_lips
from check_wave import read
from smooth_head import TYPES, WIDTH, smooth

TARGETS = ['MouthOpen', 'MouthSmile', 'MouthSad', 'MouthRound']


def lip_height(x):
    # Measured from the source atlas's green/cream boundary.
    return .5119+1.52*x*x+45*x**4


def normals(points, faces):
    _, first, inverse = np.unique(np.round(points, 7), axis=0,
                                  return_index=True, return_inverse=True)
    result = np.zeros((len(first), 3))
    cross = np.cross(points[faces[:, 1]]-points[faces[:, 0]],
                     points[faces[:, 2]]-points[faces[:, 0]])
    for k in range(3):
        np.add.at(result, inverse[faces[:, k]], cross)
    result /= np.maximum(np.linalg.norm(result, axis=1, keepdims=True), 1e-12)
    return result[inverse]


def build(source, destination):
    g, original_binary = read(source)
    blob = bytearray(original_binary)

    def get(index):
        a = g['accessors'][index]
        v = g['bufferViews'][a['bufferView']]
        return np.frombuffer(blob, dtype=TYPES[a['componentType']],
                             count=a['count']*WIDTH[a['type']],
                             offset=v.get('byteOffset', 0)+a.get('byteOffset', 0)).reshape(a['count'], -1).copy()

    def acc(data, kind='VEC3', component=5126, target=34962):
        data = np.asarray(data, dtype=TYPES[component])
        blob.extend(b'\0'*(-len(blob) % 4))
        view = dict(buffer=0, byteOffset=len(blob), byteLength=data.nbytes)
        if target:
            view['target'] = target
        vi = len(g['bufferViews']); g['bufferViews'].append(view)
        blob.extend(data.tobytes())
        item = dict(bufferView=vi, componentType=component, count=len(data), type=kind,
                    min=data.reshape(len(data), -1).min(0).tolist(),
                    max=data.reshape(len(data), -1).max(0).tolist())
        ai = len(g['accessors']); g['accessors'].append(item)
        return ai

    nodes = {n.get('name'): i for i, n in enumerate(g['nodes'])}
    body_node, head, mouth_node = (nodes[n] for n in ['Body', 'Head', 'ExpressiveMouth'])
    body_mesh = g['meshes'][g['nodes'][body_node]['mesh']]
    p = body_mesh['primitives'][0]
    attrs = p['attributes']
    old = get(attrs['POSITION'])
    surface = split_lips(old, get(attrs['NORMAL']), get(attrs['TEXCOORD_0']), get(p['indices']),
                         f=old[:, 1]-lip_height(old[:, 0]), cut_x=.108,
                         cut_z=.21, mouth_half=.101, max_path_points=3000, join_contours=True)
    assert len(surface['upper']) > 100, 'The lip contour must span the entire mouth'
    pos = surface['positions'].astype(float)
    faces = surface['indices'].astype(int)
    x = pos[:, 0]
    field = pos[:, 1]-lip_height(x)
    # Classify interpolated polygon centers with the clipping field itself.
    # Evaluating the curved contour again can put a tiny triangle on the wrong
    # lip and stretch it across the opening.
    original_field = old[:, 1]-lip_height(old[:, 0])
    for i, record in enumerate(surface['surfaceVertexSources'], len(old)):
        field[i] = np.array(record['weights'])@original_field[record['indices']]
    lower = field < 0
    lower[surface['upperCopies']] = False
    lower[surface['lowerCopies']] = True
    envelope = smooth(1-(x/.107)**2)
    edge_samples = pos[surface['upper']]
    edge_fit = np.linalg.lstsq(np.c_[np.ones(len(edge_samples)), edge_samples[:, 0]**2, edge_samples[:, 0]**4], edge_samples[:, 2], rcond=None)[0]
    rounded_depth = np.c_[np.ones(len(pos)), x*x, x**4]@edge_fit + .12*field
    collar = smooth(1-abs(field)/.014)*envelope*smooth((pos[:, 2]-.20)/.03)
    pos[:, 2] += (rounded_depth-pos[:, 2])*collar
    attenuation = envelope*smooth(1-abs(field)/np.where(lower, .085, .050))*smooth((pos[:, 2]-.19)/.04)
    # The lips are nearly closed at rest, with a narrow natural dark crease.
    base = pos.copy()
    base[:, 1] += np.where(lower, -.0006, .00015)*attenuation
    deltas = [np.zeros_like(pos) for _ in TARGETS]
    deltas[0][:, 1] = np.where(lower, -.030, .0015)*attenuation
    deltas[0][:, 2] = np.where(lower, -.009, 0)*attenuation
    deltas[1][:, 0] = .04*x*attenuation
    deltas[1][:, 1] = (-.003+.008*(abs(x)/.08)**2-np.where(lower, .0015, 0))*attenuation
    deltas[2][:, 0] = -.06*x*attenuation
    deltas[2][:, 1] = .024*attenuation
    deltas[3][:, 0] = -.30*x*attenuation
    deltas[3][:, 1] = np.where(lower, -.018, .006)*attenuation
    deltas[3][:, 2] = np.where(lower, -.003, .0015)*attenuation
    states = [base]+[base+d for d in deltas]
    # Retain the approved head normals outside the mouth's moving region.
    affected = np.zeros(len(base), bool)
    affected[np.unique(faces[np.any(attenuation[faces] > 0, axis=1)])] = True
    body_normals = []
    for state in states:
        n = surface['normals'].copy()
        computed = normals(state, faces)
        valid = affected & (np.linalg.norm(computed, axis=1) > .5)
        n[valid] = computed[valid]
        body_normals.append(n)

    for name, index in list(attrs.items()):
        if name in ('POSITION', 'NORMAL', 'TEXCOORD_0'):
            continue
        values = get(index)
        appended = []
        for record in surface['surfaceVertexSources']:
            ids, weights = record['indices'], np.array(record['weights'])
            if name == 'JOINTS_0':
                # All refined lip edges are rigidly attached to Head.
                assert np.all(values[ids] == values[ids[0]])
                appended.append(values[ids[0]])
            else:
                appended.append(weights@values[ids])
        a = g['accessors'][index]
        attrs[name] = acc(np.concatenate([values, appended]), a['type'], a['componentType'])
    attrs['TEXCOORD_0'] = acc(surface['uvs'], 'VEC2')
    p['indices'] = acc(faces.reshape(-1), 'SCALAR', 5125, 34963)

    def morph(mesh, primitive, points, ns, origin=0):
        primitive['attributes']['POSITION'] = acc(points[0]-origin)
        primitive['attributes']['NORMAL'] = acc(ns[0])
        primitive['targets'] = [dict(POSITION=acc(v-points[0]), NORMAL=acc(n-ns[0]))
                                for v, n in zip(points[1:], ns[1:])]
        mesh['weights'] = [0]*4
        mesh.setdefault('extras', {})['targetNames'] = TARGETS

    morph(body_mesh, p, states, body_normals)
    skin = g['skins'][g['nodes'][body_node]['skin']]
    origin = -get(skin['inverseBindMatrices'])[skin['joints'].index(head)].reshape(4, 4).T[:3, 3]
    upper_ids, lower_ids = surface['upper'], surface['lower']
    # Traverse left to right for a consistent mouth opening.
    order = np.argsort(pos[upper_ids, 0])
    upper_ids, lower_ids = upper_ids[order], lower_ids[order]

    # Smooth interior borders avoid inheriting the reconstructed mesh's UV
    # slits and tiny overlapping islands. The lips remain the original skin.
    cx = np.linspace(-.107, .107, 241)
    samples = pos[upper_ids]
    fit = np.linalg.lstsq(np.c_[np.ones(len(samples)), samples[:, 0]**2, samples[:, 0]**4], samples[:, 2], rcond=None)[0]
    curve = np.c_[cx, lip_height(cx), np.c_[np.ones(len(cx)), cx**2, cx**4]@fit-.0012]
    ce = smooth(1-(cx/.107)**2)
    borders = []
    for is_lower in [False, True]:
        rest = curve.copy(); rest[:, 1] += (-.0006 if is_lower else .00015)*ce
        change = [np.zeros_like(curve) for _ in TARGETS]
        change[0][:, 1] = (-.030 if is_lower else .0015)*ce
        change[0][:, 2] = (-.009 if is_lower else 0)*ce
        change[1][:, 0] = .04*cx*ce
        change[1][:, 1] = (-.003+.008*(abs(cx)/.08)**2-(.0015 if is_lower else 0))*ce
        change[2][:, 0] = -.06*cx*ce
        change[2][:, 1] = .024*ce
        change[3][:, 0] = -.30*cx*ce
        change[3][:, 1] = (-.018 if is_lower else .006)*ce
        change[3][:, 2] = (-.003 if is_lower else .0015)*ce
        borders.append([rest]+[rest+d for d in change])

    def strip_faces(rows, columns):
        f = []
        for row in range(rows-1):
            for col in range(columns-1):
                a = row*columns+col; b = a+1; c = a+columns; d = c+1
                f.extend([[a, c, b], [b, c, d]])
        return np.array(f)

    def material(name, color, roughness):
        index = len(g['materials'])
        g['materials'].append(dict(name=name, doubleSided=True,
                                  pbrMetallicRoughness=dict(baseColorFactor=color+[1],
                                                          roughnessFactor=roughness, metallicFactor=0)))
        return index

    def component(name, points, triangles, colors, mat, existing=None):
        # Face outwards for correct double-sided lighting.
        if np.mean(normals(points[1], triangles)[:, 2]) < 0:
            triangles = triangles[:, [0, 2, 1]]
        primitive = dict(attributes={'COLOR_0': acc(colors)},
                         indices=acc(triangles.reshape(-1), 'SCALAR', 5125, 34963), material=mat)
        mesh = dict(name=name, primitives=[primitive])
        morph(mesh, primitive, points, [normals(v, triangles) for v in points], origin)
        if existing is not None:
            g['meshes'][g['nodes'][existing]['mesh']] = mesh
            return existing
        mi = len(g['meshes']); g['meshes'].append(mesh)
        ni = len(g['nodes']); g['nodes'].append(dict(name=name, mesh=mi))
        g['nodes'][head]['children'].append(ni)
        return ni

    # A recessed cavity follows the exact cut edges, rather than sitting on skin.
    count = len(cx)
    cavity = []
    rows = 9
    for upper, low in zip(*borders):
        points = []
        for v in np.linspace(0, 1, rows):
            ring = upper*(1-v)+low*v
            ring[:, 2] -= .0005+.020*np.sin(np.pi*v)*ce
            points.extend(ring)
        cavity.append(np.array(points))
    colors = np.concatenate([np.tile(np.array([.022, .004, .008])*(.65+.35*abs(2*v-1)), (count, 1))
                             for v in np.linspace(0, 1, rows)])
    component('ExpressiveMouth', cavity, strip_faces(rows, count), colors,
              material('MouthCavity', [1, 1, 1], .86), mouth_node)

    # Rounded upper tooth arch; hidden behind the lower lip when closed.
    xs = np.linspace(-.079, .079, 97)
    teeth = []
    for upper in borders[0]:
        factor = (upper[len(cx)//2+60, 0]-upper[len(cx)//2-60, 0])/(cx[len(cx)//2+60]-cx[len(cx)//2-60])
        xgrid = xs*factor
        path = np.c_[xgrid, np.interp(xgrid, upper[:, 0], upper[:, 1]), np.interp(xgrid, upper[:, 0], upper[:, 2])]
        points = []
        for v in np.linspace(0, 1, 5):
            ring = path.copy()
            ring[:, 1] -= -.001+.009*v*(1-(xs/.081)**4)
            ring[:, 2] -= .003-.0012*np.sin(np.pi*v)
            points.extend(ring)
        teeth.append(np.array(points))
    teeth_node = component('MouthTeeth', teeth, strip_faces(5, len(xs)),
                           np.ones((5*len(xs), 3)), material('MouthEnamel', [.83, .80, .69], .36))

    # Soft tongue with actual curvature, kept below the upper tooth arch.
    segments, rings = 64, 7
    params = np.array([(0., 0.)]+[(r/rings, 2*np.pi*i/segments) for r in range(1, rings+1) for i in range(segments)])
    radius, angle = params.T
    tf = [[0, 1+i, 1+(i+1) % segments] for i in range(segments)]
    for row in range(rings-1):
        for i in range(segments):
            a = 1+row*segments+i; b = 1+row*segments+(i+1) % segments
            tf.extend([[a, a+segments, b], [b, a+segments, b+segments]])
    tongue = []
    for low in borders[1]:
        factor = (low[len(cx)//2+60, 0]-low[len(cx)//2-60, 0])/(cx[len(cx)//2+60]-cx[len(cx)//2-60])
        tx = .052*radius*np.cos(angle)*factor
        ty = np.interp(0, low[:, 0], low[:, 1])+.007+.0045*radius*np.sin(angle)
        tz = np.interp(tx, low[:, 0], low[:, 2])-.009+.003*(1-radius**2)
        tongue.append(np.c_[tx, ty, tz])
    tc = np.tile([.30, .045, .065], (len(radius), 1))*(.86+.14*(1-radius**2))[:, None]
    tongue_node = component('MouthTongue', tongue, np.array(tf), tc, material('MouthTongueSkin', [1, 1, 1], .58))

    # All mouth surfaces share the same four weights, including standalone GLB playback.
    for animation in g['animations']:
        channel = next(c for c in animation['channels'] if c['target'] == dict(node=mouth_node, path='weights'))
        sampler = animation['samplers'][channel['sampler']]
        times = get(sampler['input']).ravel()
        phase = times/times[-1]
        weights = np.zeros((len(times), 4))
        name = animation['name']
        if name == 'Talk':
            syllable = np.maximum(0, np.sin(2*np.pi*9*phase))**1.35
            phrase = smooth(np.minimum(phase/.025, (1-phase)/.16))
            weights[:, 0] = .78*syllable*phrase
            weights[:, 1] = .16
            weights[:, 3] = .42*syllable*np.maximum(0, np.sin(2*np.pi*3*phase))*phrase
        elif name == 'Laugh':
            weights[:, 0] = .12+.65*np.maximum(0, np.sin(2*np.pi*5*phase))**1.2
            weights[:, 1] = .80
        elif name == 'Sad':
            weights[:, 2] = .95
        elif name == 'Thinking':
            weights[:, 3] = .16
        else:
            weights[:, 1] = dict(Smile=.95, Happy=.80, Victory=.80, Wave=.50).get(name, .12)
            weights[:, 0] = dict(Smile=.12, Happy=.22, Victory=.16, Wave=.04).get(name, 0)
        weights[-1] = weights[0]
        sampler['output'] = acc(weights.reshape(-1), 'SCALAR', target=None)
        for node in [body_node, teeth_node, tongue_node]:
            animation['channels'].append(dict(sampler=channel['sampler'], target=dict(node=node, path='weights')))
    g.setdefault('extras', {})['mouthRefinement'] = dict(version=4, node=mouth_node, targets=TARGETS,
        drivenNodes=[body_node, mouth_node, teeth_node, tongue_node], splitLipPoints=len(upper_ids),
        speech='stylized syllables with closures and phrase rests')
    g['buffers'][0]['byteLength'] = len(blob)
    js = json.dumps(g, separators=(',', ':')).encode(); js += b' '*(-len(js) % 4)
    blob += b'\0'*(-len(blob) % 4)
    Path(destination).write_bytes(struct.pack('<III', 0x46546C67, 2, 28+len(js)+len(blob))+
                                 struct.pack('<II', len(js), 0x4E4F534A)+js+
                                 struct.pack('<II', len(blob), 0x004E4942)+blob)
    print(json.dumps(g['extras']['mouthRefinement'], indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source'); parser.add_argument('destination')
    args = parser.parse_args()
    assert Path(args.source).resolve() != Path(args.destination).resolve()
    build(args.source, args.destination)
