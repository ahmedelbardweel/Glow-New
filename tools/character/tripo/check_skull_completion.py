"""Verify skull closure, preserved character data and animated seam continuity."""
import argparse
import json
import io
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

from complete_skull import upper_boundary, sample
from validate_deformation import Rig


def check(before_path, after_path):
    before, after = Rig(before_path), Rig(after_path)
    bg, ag = before.doc, after.doc
    body = next(p for p in before.primitives if p['name'] == 'Body')
    new_body = next(p for p in after.primitives if p['name'] == 'Body')
    scalp = next(p for p in after.primitives if p['name'] == 'Scalp')
    rim = upper_boundary(body['vertices'], body['faces'])
    assert np.array_equal(scalp['vertices'][:len(rim)], body['vertices'][rim]) or np.array_equal(scalp['vertices'][:len(rim)], body['vertices'][rim[::-1]])
    body_attrs = bg['meshes'][0]['primitives'][0]['attributes']
    changed = body_attrs['NORMAL']
    for i in range(len(bg['accessors'])):
        if i != changed:
            assert np.array_equal(before.accessor(i), after.accessor(i)), f'Original accessor changed: {i}'
    for key in ('animations', 'skins', 'materials', 'textures', 'meshes'):
        actual = ag[key][:len(bg[key])]
        assert actual == bg[key], key
    for i, node in enumerate(bg['nodes']):
        original = {k: v for k, v in node.items() if k != 'children'}
        current = {k: v for k, v in ag['nodes'][i].items() if k != 'children'}
        assert current == original, f'Node {i} changed'
        assert ag['nodes'][i].get('children', [])[:len(node.get('children', []))] == node.get('children', [])
    def texture(rig):
        view = rig.doc['bufferViews'][rig.doc['images'][0]['bufferView']]
        start = view.get('byteOffset', 0)
        return np.array(Image.open(io.BytesIO(rig.binary[start:start + view['byteLength']])).convert('RGB')) / 255.
    old_texture, new_texture = texture(before), texture(after)
    assert old_texture.shape == new_texture.shape
    changed_pixels = np.any(abs(old_texture - new_texture) > .5 / 255, axis=2)
    assert changed_pixels.mean() < .02, 'Texture repair exceeded scalp collar budget'
    normal_before, normal_after = before.accessor(changed), after.accessor(changed)
    distance = cKDTree(body['vertices'][rim]).query(body['vertices'])[0]
    assert np.array_equal(normal_before[distance >= .025], normal_after[distance >= .025]), 'Normals outside scalp collar changed'
    uv = before.accessor(body_attrs['TEXCOORD_0'])
    texture_width = ag['extras']['skullCompletion']['textureCollarWidth']
    unaffected = distance > texture_width + .018
    texture_drift = float(np.max(abs(sample(old_texture, uv[unaffected]) - sample(new_texture, uv[unaffected]))))
    assert texture_drift < .025, 'Texture outside scalp collar changed'
    for node in ag['nodes']:
        if 'mesh' not in node:
            continue
        for primitive in ag['meshes'][node['mesh']]['primitives']:
            normal = after.accessor(primitive['attributes']['NORMAL'])
            assert np.isfinite(normal).all()
            assert np.max(abs(np.linalg.norm(normal, axis=1) - 1)) < 1e-5

    head_slot = ag['skins'][0]['joints'].index(after.names['Head'])
    assert np.all(scalp['joints'][:, 0] == head_slot)
    assert np.all(scalp['weights'][:, 0] == 1) and np.all(scalp['weights'][:, 1:] == 0)
    vertices = np.concatenate([body['vertices'], scalp['vertices']])
    faces = np.concatenate([body['faces'], scalp['faces'] + len(body['vertices'])])
    _, reverse = np.unique(vertices, axis=0, return_inverse=True)
    faces = reverse[faces]
    valid = (faces[:, 0] != faces[:, 1]) & (faces[:, 1] != faces[:, 2]) & (faces[:, 2] != faces[:, 0])
    faces = faces[valid]
    edges, counts = np.unique(np.sort(np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]]), axis=1), axis=0, return_counts=True)
    edge_counts = {tuple(e): int(c) for e, c in zip(edges, counts)}
    welded_rim = reverse[rim]
    assert all(edge_counts[tuple(sorted((a, b)))] == 2 for a, b in zip(welded_rim, np.roll(welded_rim, -1))), 'Open scalp seam'
    # Every added vertex above the seam belongs to a closed manifold patch.
    cap_ids = set(reverse[len(body['vertices']) + len(rim):])
    assert all(edge_counts[tuple(e)] == 2 for e in edges if e[0] in cap_ids or e[1] in cap_ids), 'Open or nonmanifold dome'
    sf = scalp['faces']
    cross = np.cross(scalp['vertices'][sf[:, 1]] - scalp['vertices'][sf[:, 0]], scalp['vertices'][sf[:, 2]] - scalp['vertices'][sf[:, 0]])
    assert np.linalg.norm(cross, axis=1).min() > 1e-12, 'Degenerate cap triangles'
    cap_node = ag['nodes'][after.names['Scalp']]
    cap_primitive = ag['meshes'][cap_node['mesh']]['primitives'][0]
    cap_normal = after.accessor(cap_primitive['attributes']['NORMAL'])
    assert np.all(np.einsum('ij,ij->i', cross, cap_normal[sf].mean(1)) > 0), 'Inward scalp faces'
    if 'scalpRoughness' in ag['extras']['skullCompletion']:
        surface = ag['materials'][cap_primitive['material']]['pbrMetallicRoughness']
        assert surface['metallicRoughnessTexture'].get('texCoord', 0) == 0
        gloss_uv = after.accessor(cap_primitive['attributes']['TEXCOORD_0'])
        assert np.all(gloss_uv[:len(rim), 1] == 0) and gloss_uv[-1, 1] == 1
    # Match the exact boundary order used by the cap.
    nearest = cKDTree(body['vertices']).query(scalp['vertices'][:len(rim)])[1]
    seam_drift, rigid_drift, poses = 0., 0., 0
    for clip, channels in after.clips.items():
        duration = max(float(channel[2][-1]) for channel in channels)
        for time in np.linspace(0, duration, 9):
            world = after.world(after.pose(clip, time))
            old_world = before.world(before.pose(clip, time))
            assert np.allclose(world[:len(before.nodes)], old_world, atol=1e-10)
            cap = Rig.deform(scalp, world)
            current_body = Rig.deform(new_body, world)
            seam_drift = max(seam_drift, float(np.linalg.norm(cap[:len(rim)] - current_body[nearest], axis=1).max()))
            lengths = np.linalg.norm(cap - cap[-1], axis=1)
            original = np.linalg.norm(scalp['vertices'] - scalp['vertices'][-1], axis=1)
            rigid_drift = max(rigid_drift, float(np.max(abs(lengths - original))))
            poses += 1
    assert seam_drift < 1e-6 and rigid_drift < 1e-6
    return {'closedRimEdges': len(rim), 'addedVertices': len(scalp['vertices']),
            'poses': poses, 'maxAnimatedSeamDrift': seam_drift,
            'maxRigidHeadDistanceDrift': rigid_drift,
            'texturePixelsAdjusted': int(changed_pixels.sum()),
            'maxTextureDriftOutsideCollar': texture_drift,
            'scalpFacesOutward': True,
            'originalGeometryRigAndMotionsPreserved': True}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = check(args.before, args.after)
    text = json.dumps(report, indent=2)
    if args.output:
        args.output.write_text(text, encoding='utf-8')
    print(text)
