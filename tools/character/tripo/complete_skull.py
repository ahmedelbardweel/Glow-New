"""Close the new rig's open scalp with a rounded, Head-skinned dome.

Run after refine_sides.py. Existing geometry, rig and motions are kept; only
the narrow cut-edge shading is blended. Scalp stays visible without Hat.
"""
import argparse
import io
import json
import struct
import copy
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d, minimum_filter, maximum_filter
from scipy.spatial import cKDTree

from validate_deformation import Rig


def upper_boundary(vertices, faces):
    points, first, remap = np.unique(vertices, axis=0, return_index=True,
                                     return_inverse=True)
    welded = remap[faces]
    welded = welded[(welded[:, 0] != welded[:, 1]) &
                    (welded[:, 1] != welded[:, 2]) &
                    (welded[:, 2] != welded[:, 0])]
    edges = np.concatenate([welded[:, [0, 1]], welded[:, [1, 2]],
                            welded[:, [2, 0]]])
    edges, counts = np.unique(np.sort(edges, axis=1), axis=0, return_counts=True)
    edges = edges[(counts == 1) & (points[edges[:, 0], 1] > .60) &
                  (points[edges[:, 1], 1] > .60)]
    adjacent = {}
    for a, b in edges:
        adjacent.setdefault(a, []).append(b)
        adjacent.setdefault(b, []).append(a)
    assert adjacent, 'No open scalp boundary found'
    # Other texture-island borders extend below the head. Select the closed
    # component containing the highest vertex, not those partial seam paths.
    start = max(adjacent, key=lambda i: points[i, 1])
    order, previous, current = [], -1, start
    while True:
        order.append(current)
        assert len(adjacent[current]) == 2, 'Scalp rim is not a simple closed loop'
        nxt = next(v for v in adjacent[current] if v != previous)
        previous, current = current, nxt
        if current == start:
            break
        assert len(order) <= len(adjacent)
    assert points[order, 1].min() > .62 and len(order) > 500
    return first[order]


def linear(rgb):
    return np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4)


def sample(image, uv):
    # glTF UVs use the embedded image's top-left origin; sample texel centers.
    h, w = image.shape[:2]
    xy = np.clip(uv * [w, h] - .5, [0, 0], [w - 1.00001, h - 1.00001])
    ij = np.floor(xy).astype(int)
    fraction = xy - ij
    x, y = ij.T
    fx, fy = fraction.T
    return ((image[y, x] * (1 - fx[:, None]) + image[y, x + 1] * fx[:, None]) * (1 - fy[:, None]) +
            (image[y + 1, x] * (1 - fx[:, None]) + image[y + 1, x + 1] * fx[:, None]) * fy[:, None])


def paint_collar(atlas, uv, faces, strength, color):
    """Feather out the baked hat shadow in the narrow scalp-edge UV strip."""
    h, w = atlas.shape[:2]
    mask = np.zeros((h, w))
    paint = np.zeros_like(atlas)
    for face in faces[np.max(strength[faces], axis=1) > 0]:
        xy = uv[face] * [w, h] - .5
        xs, ys = xy.T
        x0, x1 = max(0, int(np.floor(xs.min()))), min(w, int(np.ceil(xs.max())) + 1)
        y0, y1 = max(0, int(np.floor(ys.min()))), min(h, int(np.ceil(ys.max())) + 1)
        den = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(den) < 1e-10 or x0 >= x1 or y0 >= y1:
            continue
        xx, yy = np.meshgrid(np.arange(x0, x1), np.arange(y0, y1))
        a = ((ys[1] - ys[2]) * (xx - xs[2]) + (xs[2] - xs[1]) * (yy - ys[2])) / den
        b = ((ys[2] - ys[0]) * (xx - xs[2]) + (xs[0] - xs[2]) * (yy - ys[2])) / den
        c = 1 - a - b
        value = (a * strength[face[0]] + b * strength[face[1]] + c * strength[face[2]])
        value *= (a >= -.001) & (b >= -.001) & (c >= -.001)
        update = value > mask[y0:y1, x0:x1]
        target = a[:, :, None] * color[face[0]] + b[:, :, None] * color[face[1]] + c[:, :, None] * color[face[2]]
        mask[y0:y1, x0:x1][update] = value[update]
        paint[y0:y1, x0:x1][update] = target[update]
    # Fill the atlas padding so bilinear filtering does not reveal the old cut.
    # Extend each painted UV island's own color into its two-pixel padding.
    from scipy.ndimage import distance_transform_edt
    indices = distance_transform_edt(mask == 0, return_distances=False, return_indices=True)
    paint = paint[indices[0], indices[1]]
    mask = np.clip(maximum_filter(mask, size=5) / .85, 0, 1)
    return atlas * (1 - mask[:, :, None]) + paint * mask[:, :, None]


def complete(source, destination, apex=.88):
    rig = Rig(source)
    g = rig.doc
    assert 'Scalp' not in rig.names, 'Use the rig before skull completion'
    body = rig.nodes[rig.names['Body']]
    original = g['meshes'][body['mesh']]['primitives'][0]
    attributes = original['attributes']
    positions = rig.accessor(attributes['POSITION'])
    faces = rig.accessor(original['indices']).reshape(-1, 3)
    rim_indices = upper_boundary(positions, faces)
    rim = positions[rim_indices].astype(float)
    # Make the loop counter-clockwise in the x/z plane.
    area = np.sum(rim[:, 0] * np.roll(rim[:, 2], -1) - np.roll(rim[:, 0], -1) * rim[:, 2])
    if area < 0:
        rim_indices, rim = rim_indices[::-1], rim[::-1]
    lengths = np.linalg.norm(np.roll(rim, -1, axis=0) - rim, axis=1)
    progress = np.r_[0, np.cumsum(lengths)] / lengths.sum()
    n = len(rim)
    center = np.array([(rim[:, 0].min() + rim[:, 0].max()) / 2,
                       np.mean(rim[:, 1]),
                       (rim[:, 2].min() + rim[:, 2].max()) / 2])
    height = apex - center[1]
    assert .12 < height < .25

    def interpolate(values, s):
        closed = np.concatenate([values, values[:1]])
        return np.column_stack([np.interp(s, progress, closed[:, d])
                                for d in range(values.shape[1])])

    image_def = g['images'][0]
    view = g['bufferViews'][image_def['bufferView']]
    offset = view.get('byteOffset', 0)
    atlas = np.array(Image.open(io.BytesIO(rig.binary[offset:offset + view['byteLength']])).convert('RGB')) / 255.
    # A bright interior texel provides a constant map sample. Vertex colors
    # carry the scalp's matched green, avoiding unrelated atlas UV islands.
    clean = minimum_filter(atlas.min(2), size=7)
    iy, ix = np.unravel_index(np.argmax(clean), clean.shape)
    reference = linear(atlas[iy, ix])
    assert reference.min() > .5, 'No suitable neutral texture patch'
    # Extend the surrounding skin's baked color/light variation. A single
    # median green made the dome matte and left a distinct band on the forehead.
    color_distance, color_nearest = cKDTree(rim).query(positions)
    original_colors = sample(atlas, rig.accessor(attributes['TEXCOORD_0']))
    clean_skin = original_colors[:, 1] > 1.35 * np.maximum(original_colors[:, 0], original_colors[:, 2])
    sample_strip = ((positions[:, 1] < rim[color_nearest, 1] - .018) &
                    (color_distance > .022) & (color_distance < .065) & clean_skin)
    strip_indices = np.flatnonzero(sample_strip)
    inset = rim.copy()
    inset[:, 1] -= .038
    inset[:, [0, 2]] *= 1.05
    _, nearby = cKDTree(positions[strip_indices]).query(inset, k=12)
    samples = original_colors[strip_indices[nearby]]
    green = samples[:, :, 1] > 1.35 * np.maximum(samples[:, :, 0], samples[:, :, 2])
    samples[~green] = np.nan
    rim_color = np.nanmedian(samples, axis=1)
    invalid = ~np.isfinite(rim_color).all(1)
    rim_color[invalid] = np.nanmedian(rim_color, axis=0)
    rim_color = gaussian_filter1d(rim_color, 18, axis=0, mode='wrap')
    skin_color = rim_color.copy()
    rim_color = linear(rim_color)
    mean_color = np.median(rim_color, axis=0)
    # The source was authored with a permanent hat and has a shaded cut line.
    # Remove only that narrow line, then give the added skin the same base tone.
    color_strength = np.clip(1 - color_distance / .055, 0, 1)
    color_strength = color_strength ** 2 * (3 - 2 * color_strength)
    original_atlas = atlas.copy()
    atlas = paint_collar(atlas, rig.accessor(attributes['TEXCOORD_0']), faces, color_strength, skin_color[color_nearest])

    count, layers = 256, 24
    s = np.arange(count) / count
    profile = gaussian_filter1d(interpolate(rim, s), 1.25, axis=0, mode='wrap')
    profile_color = gaussian_filter1d(interpolate(rim_color, s), 2, axis=0, mode='wrap')
    vertex, colors, triangles = [rim], [rim_color], []
    gloss_uv = [np.column_stack([np.full(n, .5), np.zeros(n)])]
    ring_starts = []
    ring_parameters = [progress[:-1]]
    ring_sizes = [n]
    all_starts = [0]
    phi0 = .25
    tangent = (np.roll(profile, -1, axis=0) - np.roll(profile, 1, axis=0)) / 2

    def surface_normal(phi):
        radius = np.cos(phi) / np.cos(phi0)
        derivative = -np.sin(phi) / np.cos(phi0)
        along = tangent * radius
        along[:, 1] = tangent[:, 1] * radius ** 2
        up = (profile - center) * derivative
        up[:, 1] = (2 * (profile[:, 1] - center[1]) * radius * derivative +
                    height * np.cos(phi) / (1 - np.sin(phi0)))
        normal = np.cross(up, along)
        return normal / np.linalg.norm(normal, axis=1, keepdims=True)

    smooth_rim_normal = surface_normal(phi0)
    boundary_normal = np.column_stack([
        np.interp(progress[:-1], np.r_[s, 1], np.r_[smooth_rim_normal[:, d], smooth_rim_normal[0, d]])
        for d in range(3)])
    cap_normals = [boundary_normal]
    vertex_count = n
    for k in range(1, layers):
        t = k / layers
        phi = phi0 + (np.pi / 2 - phi0) * t
        radius = np.cos(phi) / np.cos(phi0)
        rise = (np.sin(phi) - np.sin(phi0)) / (1 - np.sin(phi0))
        dense = k <= 2
        parameters = progress[:-1] if dense else s
        ring_profile = profile
        ring_color = profile_color
        ring_normal = surface_normal(phi)
        if dense:
            smooth_profile = np.column_stack([np.interp(parameters, np.r_[s, 1], np.r_[profile[:, d], profile[0, d]]) for d in range(3)])
            fade = min(1, k / 3) ** 2 * (3 - 2 * min(1, k / 3))
            ring_profile = rim * (1 - fade) + smooth_profile * fade
            ring_color = rim_color
            ring_normal = np.column_stack([np.interp(parameters, np.r_[s, 1], np.r_[ring_normal[:, d], ring_normal[0, d]]) for d in range(3)])
        ring = center + (ring_profile - center) * radius
        ring[:, 1] = center[1] + (ring_profile[:, 1] - center[1]) * radius ** 2 + height * rise
        ring_starts.append(vertex_count)
        all_starts.append(vertex_count)
        ring_parameters.append(parameters)
        ring_sizes.append(len(ring))
        vertex_count += len(ring)
        vertex.append(ring)
        blend = t ** 2 * (3 - 2 * t)
        colors.append(ring_color * (1 - blend) + mean_color * blend)
        cap_normals.append(ring_normal)
        gloss_uv.append(np.column_stack([np.full(len(ring), .5), np.full(len(ring), t)]))
    # Retain the dense border for two rings before reducing tessellation. This
    # prevents folded slivers where the irregular cut meets the smooth dome.
    for k in range(len(all_starts) - 1):
        lo, hi = all_starts[k:k + 2]
        na, nb = ring_sizes[k:k + 2]
        pa, pb = np.r_[ring_parameters[k], 1], np.r_[ring_parameters[k + 1], 1]
        a = b = 0
        while a < na or b < nb:
            if b == nb or (a < na and pa[a + 1] <= pb[b + 1]):
                triangles.append([lo + a % na, lo + (a + 1) % na, hi + b % nb])
                a += 1
            else:
                triangles.append([lo + a % na, hi + (b + 1) % nb, hi + b % nb])
                b += 1
    top = vertex_count
    vertex.append(np.array([[center[0], apex, center[2]]]))
    cap_normals.append(np.array([[0, 1, 0]]))
    colors.append(mean_color[None, :])
    gloss_uv.append(np.array([[.5, 1]]))
    for j in range(count):
        triangles.append([ring_starts[-1] + j, ring_starts[-1] + (j + 1) % count, top])
    vertex = np.concatenate(vertex)
    triangles = np.asarray(triangles, dtype=np.uint32)
    # Above ordering points down in x/z; the dome's outside faces upward.
    triangles = triangles[:, [0, 2, 1]]
    normal = np.concatenate(cap_normals)
    normal /= np.linalg.norm(normal, axis=1, keepdims=True)
    geometric = np.cross(vertex[triangles[:, 1]] - vertex[triangles[:, 0]], vertex[triangles[:, 2]] - vertex[triangles[:, 0]])
    inward = np.einsum('ij,ij->i', geometric, normal[triangles].mean(1)) < 0
    triangles[inward] = triangles[inward][:, [0, 2, 1]]
    color = np.concatenate(colors) / reference
    assert np.all((color >= 0) & (color <= 1)), 'Scalp color exceeds texture reference'
    joints = np.zeros((len(vertex), 4), dtype=np.uint16)
    joint_nodes = g['skins'][body['skin']]['joints']
    joints[:, 0] = joint_nodes.index(rig.names['Head'])
    weights = np.zeros((len(vertex), 4))
    weights[:, 0] = 1

    blob = bytearray(rig.binary)
    # The cut edge's inherited normals contain spikes from tiny source faces.
    # Match the dome at the rim and feather only a narrow 2.5 cm collar below it.
    distance, nearest = cKDTree(rim).query(positions)
    collar = distance < .025
    t = np.clip(1 - distance[collar] / .025, 0, 1)
    mix = t * t * (3 - 2 * t)
    body_normal = rig.accessor(attributes['NORMAL']).astype(float)
    body_normal[collar] = (body_normal[collar] * (1 - mix[:, None]) +
                           boundary_normal[nearest[collar]] * mix[:, None])
    body_normal[collar] /= np.linalg.norm(body_normal[collar], axis=1, keepdims=True)
    normal_accessor = g['accessors'][attributes['NORMAL']]
    normal_view = g['bufferViews'][normal_accessor['bufferView']]
    normal_offset = normal_view.get('byteOffset', 0) + normal_accessor.get('byteOffset', 0)
    body_normal = body_normal.astype('<f4')
    blob[normal_offset:normal_offset + body_normal.nbytes] = body_normal.tobytes()

    # Replace the existing image span, preserving buffer-view identities and
    # avoiding a second unused atlas in the mobile asset.
    painted = io.BytesIO()
    Image.fromarray(np.round(atlas * 255).clip(0, 255).astype('uint8')).save(painted, format='PNG')
    image_view = g['bufferViews'][g['images'][0]['bufferView']]
    image_start = image_view.get('byteOffset', 0)
    old_span = (image_view['byteLength'] + 3) // 4 * 4
    image_end = image_start + old_span
    new_image = painted.getvalue()
    padded_image = new_image + b'\0' * (-len(new_image) % 4)
    blob[image_start:image_end] = padded_image
    shift = len(padded_image) - old_span
    for view in g['bufferViews']:
        if view.get('byteOffset', 0) >= image_end:
            view['byteOffset'] = view.get('byteOffset', 0) + shift
    image_view['byteLength'] = len(new_image)
    g['images'][0]['mimeType'] = 'image/png'

    def accessor(values, kind, dtype='<f4', component=5126, target=34962):
        data = np.asarray(values, dtype=dtype)
        blob.extend(b'\0' * (-len(blob) % 4))
        view_index = len(g['bufferViews'])
        g['bufferViews'].append({'buffer': 0, 'byteOffset': len(blob), 'byteLength': data.nbytes, 'target': target})
        blob.extend(data.tobytes())
        entry = {'bufferView': view_index, 'componentType': component,
                 'count': len(data), 'type': kind}
        if kind == 'VEC3':
            entry.update(min=data.min(0).tolist(), max=data.max(0).tolist())
        result = len(g['accessors'])
        g['accessors'].append(entry)
        return result

    attrs = {
        'POSITION': accessor(vertex, 'VEC3'),
        'NORMAL': accessor(normal, 'VEC3'),
        'TEXCOORD_0': accessor(np.concatenate(gloss_uv), 'VEC2'),
        'COLOR_0': accessor(color, 'VEC3'),
        'JOINTS_0': accessor(joints, 'VEC4', '<u2', 5123),
        'WEIGHTS_0': accessor(weights, 'VEC4'),
        '_GLOW_SKIN_REGION': accessor(np.ones((len(vertex), 1)), 'SCALAR'),
    }
    # Match the original .78 roughness at the join, gradually recovering the
    # soft highlight missing from the untextured upper surface. Use UV0 for
    # both maps: the Flutter glTF loader does not support UV1 for roughness.
    t_gloss = np.linspace(0, 1, 128)
    blend_gloss = np.clip(t_gloss / .55, 0, 1)
    blend_gloss = blend_gloss ** 2 * (3 - 2 * blend_gloss)
    roughness = .78 * (1 - blend_gloss) + .58 * blend_gloss
    gloss_map = np.zeros((128, 2, 3), dtype='uint8')
    gloss_map[:, :, 0] = 255
    gloss_map[:, :, 1] = np.round(roughness[:, None] / .78 * 255).astype('uint8')
    gloss_png = io.BytesIO()
    Image.fromarray(gloss_map).save(gloss_png, format='PNG')
    blob.extend(b'\0' * (-len(blob) % 4))
    gloss_view = len(g['bufferViews'])
    g['bufferViews'].append({'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(gloss_png.getvalue())})
    blob.extend(gloss_png.getvalue())
    gloss_image = len(g['images'])
    g['images'].append({'name': 'ScalpRoughness', 'bufferView': gloss_view, 'mimeType': 'image/png'})
    gloss_sampler = len(g.setdefault('samplers', []))
    g['samplers'].append({'magFilter': 9729, 'minFilter': 9729, 'wrapS': 33071, 'wrapT': 33071})
    gloss_texture = len(g['textures'])
    g['textures'].append({'source': gloss_image, 'sampler': gloss_sampler})
    # A constant neutral base map preserves vertex-color calibration while
    # allowing the shared UV0 to carry the roughness gradient on every viewer.
    neutral_png = io.BytesIO()
    neutral = np.tile(np.round(original_atlas[iy, ix] * 255).astype('uint8'), (2, 2, 1))
    Image.fromarray(neutral).save(neutral_png, format='PNG')
    blob.extend(b'\0' * (-len(blob) % 4))
    neutral_view = len(g['bufferViews'])
    g['bufferViews'].append({'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(neutral_png.getvalue())})
    blob.extend(neutral_png.getvalue())
    neutral_image = len(g['images'])
    g['images'].append({'name': 'ScalpColorBase', 'bufferView': neutral_view, 'mimeType': 'image/png'})
    neutral_texture = len(g['textures'])
    g['textures'].append({'source': neutral_image, 'sampler': gloss_sampler})
    scalp_material = copy.deepcopy(g['materials'][original['material']])
    scalp_material['name'] = 'GlowScalpSkin'
    scalp_material['pbrMetallicRoughness']['baseColorTexture'] = {'index': neutral_texture}
    scalp_material['pbrMetallicRoughness']['metallicRoughnessTexture'] = {'index': gloss_texture}
    scalp_material_index = len(g['materials'])
    g['materials'].append(scalp_material)
    primitive = {'attributes': attrs, 'indices': accessor(triangles.reshape(-1), 'SCALAR', '<u4', 5125, 34963),
                 'material': scalp_material_index}
    mesh_index, node_index = len(g['meshes']), len(g['nodes'])
    g['meshes'].append({'name': 'Scalp', 'primitives': [primitive]})
    g['nodes'].append({'name': 'Scalp', 'mesh': mesh_index, 'skin': body['skin']})
    parent = rig.parents[rig.names['Body']]
    if parent >= 0:
        g['nodes'][parent].setdefault('children', []).append(node_index)
    else:
        for scene in g['scenes']:
            if rig.names['Body'] in scene.get('nodes', []):
                scene['nodes'].append(node_index)
    g.setdefault('extras', {})['skullCompletion'] = {
        'version': 2, 'rimVertices': n, 'addedVertices': len(vertex),
        'addedTriangles': len(triangles), 'apex': apex,
        'skinJoint': 'Head', 'hatRemainsSeparate': True,
        'textureCollarWidth': .055,
        'scalpColor': 'extended-surrounding-skin',
        'scalpRoughness': [.78, .58],
        'texturePixelsAdjusted': int(np.any(abs(atlas - original_atlas) > .5 / 255, axis=2).sum()),
    }
    g['buffers'][0]['byteLength'] = len(blob)
    js = json.dumps(g, separators=(',', ':')).encode()
    js += b' ' * (-len(js) % 4)
    blob += b'\0' * (-len(blob) % 4)
    output = (struct.pack('<III', 0x46546c67, 2, 28 + len(js) + len(blob)) +
              struct.pack('<II', len(js), 0x4e4f534a) + js +
              struct.pack('<II', len(blob), 0x004e4942) + blob)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(output)
    print(json.dumps(g['extras']['skullCompletion'], indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--apex', type=float, default=.88)
    args = parser.parse_args()
    assert args.input.resolve() != args.output.resolve(), 'Preserve the source rig'
    complete(args.input, args.output, args.apex)
