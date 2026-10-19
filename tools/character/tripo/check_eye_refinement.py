"""Check preserved character data, accessory separation and exported eye/lid geometry.

The blink check evaluates the same piecewise half/closed morph blend used by
the viewers. It samples front-facing iris coverage and ellipsoid clearance;
it does not replace rendered checks of texture joins, gaze or oblique views.
"""
import argparse
import copy
import json
from pathlib import Path

import numpy as np

from validate_deformation import Rig


def mesh_primitive(rig, name):
    node = rig.nodes[rig.names[name]]
    mesh = rig.doc['meshes'][node['mesh']]
    assert len(mesh['primitives']) == 1, f'{name}: expected one primitive'
    return node, mesh, mesh['primitives'][0]


def image_bytes(rig, image):
    view = rig.doc['bufferViews'][image['bufferView']]
    start = view.get('byteOffset', 0)
    return rig.binary[start:start + view['byteLength']]


def transform(points, matrix):
    return points @ matrix[:3, :3].T + matrix[:3, 3]


def projected_depth(points, faces, samples):
    """Front-most Z of the triangle sheet at XY samples, -inf outside it."""
    triangles = points[faces]
    a, b, c = (triangles[:, i] for i in range(3))
    denominator = ((b[:, 1] - c[:, 1]) * (a[:, 0] - c[:, 0])
                   + (c[:, 0] - b[:, 0]) * (a[:, 1] - c[:, 1]))
    valid = abs(denominator) > 1e-15
    a, b, c, denominator = a[valid], b[valid], c[valid], denominator[valid]
    depths = []
    for start in range(0, len(samples), 64):
        q = samples[start:start + 64]
        x, y = q[:, 0, None], q[:, 1, None]
        wa = ((b[:, 1] - c[:, 1]) * (x - c[:, 0])
              + (c[:, 0] - b[:, 0]) * (y - c[:, 1])) / denominator
        wb = ((c[:, 1] - a[:, 1]) * (x - c[:, 0])
              + (a[:, 0] - c[:, 0]) * (y - c[:, 1])) / denominator
        wc = 1 - wa - wb
        inside = (wa >= -1e-7) & (wb >= -1e-7) & (wc >= -1e-7)
        depth = wa * a[:, 2] + wb * b[:, 2] + wc * c[:, 2]
        depths.extend(np.where(inside, depth, -np.inf).max(axis=1))
    return np.array(depths)


def check(before_path, after_path):
    before, after = Rig(before_path), Rig(after_path)
    bg, ag = before.doc, after.doc
    metadata = ag.get('extras', {}).get('eyeRefinement')
    assert metadata and metadata['frameIndependent'], 'Missing eye refinement metadata'
    head = after.names['Head']
    assert len(bg['skins'][0]['joints']) == 29, 'Unexpected source skeleton'
    assert ag['skins'] == bg['skins'], 'Skeleton/bind matrices changed'
    assert ag['animations'] == bg['animations'], 'Existing animations changed'

    # Check every original accessor, not just the references retained by Body.
    for i in range(len(bg['accessors'])):
        assert ag['accessors'][i] == bg['accessors'][i], f'Accessor descriptor changed: {i}'
        assert np.array_equal(before.accessor(i), after.accessor(i)), f'Accessor data changed: {i}'
    for key in ('materials', 'textures', 'images', 'samplers'):
        assert ag.get(key, [])[:len(bg.get(key, []))] == bg.get(key, []), f'Original {key} changed'
    for i, entry in enumerate(bg['images']):
        assert image_bytes(before, entry) == image_bytes(after, ag['images'][i]), f'Texture {i} changed'
    for name in ('Body', 'Scalp', 'Hat'):
        old_node, old_mesh, _ = mesh_primitive(before, name)
        new_node, new_mesh, _ = mesh_primitive(after, name)
        assert new_node == old_node and new_mesh == old_mesh, f'{name} changed'

    expected_children = {after.names[n] for n in ('EyeLeft', 'EyeRight', 'EyeLids')}
    for i, node in enumerate(before.nodes):
        new = copy.deepcopy(after.nodes[i])
        if i == head:
            old_children = node.get('children', [])
            children = new.pop('children', [])
            assert children[:len(old_children)] == old_children, 'Head hierarchy reordered'
            assert set(children[len(old_children):]) == expected_children, 'Unexpected Head attachments'
            assert new == {k: v for k, v in node.items() if k != 'children'}, 'Head transform changed'
        else:
            assert new == node, f'Original node {i} changed'
    frame_node, frame_mesh, frame = mesh_primitive(after, 'Glasses')
    _, old_frame_mesh, old_frame = mesh_primitive(before, 'Glasses')
    reference = copy.deepcopy(frame_mesh)
    reference['primitives'][0]['indices'] = old_frame['indices']
    reference['primitives'][0]['material'] = old_frame['material']
    assert reference == old_frame_mesh, 'Glasses geometry changed beyond the index cut'
    frame_material = ag['materials'][frame['material']]
    assert frame_material['name'] == 'SpectacleFrame'
    assert frame_material['pbrMetallicRoughness']['baseColorTexture'] == bg['materials'][old_frame['material']]['pbrMetallicRoughness']['baseColorTexture']
    old_faces = before.accessor(old_frame['indices']).reshape(-1, 3)
    faces = after.accessor(frame['indices']).reshape(-1, 3)
    assert 0 < len(faces) < len(old_faces), 'Frame eye discs were not removed'
    old_rows = {tuple(face) for face in old_faces.tolist()}
    assert all(tuple(face) in old_rows for face in faces.tolist()), 'Glasses contain new/altered triangles'
    assert not set(frame_node.get('children', [])) & expected_children, 'Eyes depend on glasses visibility'

    normal_error = 0.
    for node in after.nodes:
        if 'mesh' not in node:
            continue
        for primitive in ag['meshes'][node['mesh']]['primitives']:
            attrs = primitive['attributes']
            for name, idx in attrs.items():
                assert np.isfinite(after.accessor(idx)).all(), f'{node["name"]}: invalid {name}'
            points = after.accessor(attrs['POSITION'])
            normal = after.accessor(attrs['NORMAL'])
            error = float(abs(np.linalg.norm(normal, axis=1) - 1).max())
            normal_error = max(normal_error, error)
            assert error < 1e-5, f'{node["name"]}: non-unit normals'
            indices = after.accessor(primitive['indices']).ravel()
            assert indices.min() >= 0 and indices.max() < len(points), 'Index outside mesh'

    eye_centers, eye_radii, attached = [], [], {}
    for name in ('EyeLeft', 'EyeRight', 'EyeLids'):
        ni = after.names[name]
        node, _, primitive = mesh_primitive(after, name)
        assert after.parents[ni] == head and 'skin' not in node, f'{name}: must attach once to Head'
        assert not any(k.startswith('JOINTS') for k in primitive['attributes']), f'{name}: double skinning'
        points = after.accessor(primitive['attributes']['POSITION'])
        attached[name] = points
        if name != 'EyeLids':
            world = transform(points, after.rest_world[ni])
            eye_centers.append((world.min(0) + world.max(0)) / 2)
            eye_radii.append(np.ptp(world, axis=0) / 2)
    centers, radii = np.array(eye_centers), np.array(eye_radii)
    assert np.allclose(centers[0] * [-1, 1, 1], centers[1], atol=1e-6), 'Eye centers are asymmetric'
    assert np.allclose(radii[0], radii[1], atol=1e-7), 'Eye sizes differ'
    assert np.allclose(centers, metadata['eyes'], atol=1e-6), 'Metadata eye centers disagree'
    assert np.allclose(radii, metadata['radius'], atol=1e-6), 'Metadata eye radii disagree'
    assert np.all(radii > 0), 'Empty eye geometry'

    _, lid_mesh, lid = mesh_primitive(after, 'EyeLids')
    targets = lid.get('targets', [])
    names = ['BlinkLeftHalf', 'BlinkLeftClosed', 'BlinkRightHalf', 'BlinkRightClosed']
    assert len(targets) == 4 and lid_mesh.get('weights') == [0, 0, 0, 0]
    assert lid_mesh.get('extras', {}).get('targetNames') == names, 'Blink morph order changed'
    lp = attached['EyeLids']
    ln = after.accessor(lid['attributes']['NORMAL'])
    lf = after.accessor(lid['indices']).reshape(-1, 3)
    lid_matrix = after.rest_world[after.names['EyeLids']]
    world_lids = transform(lp, lid_matrix)
    sides = np.argmin(np.linalg.norm(world_lids[:, None] - centers[None], axis=2), axis=1)
    delta, delta_normal = [], []
    for k, target in enumerate(targets):
        dp, dn = (after.accessor(target[key]) for key in ('POSITION', 'NORMAL'))
        assert dp.shape == lp.shape and dn.shape == ln.shape
        assert np.isfinite(dp).all() and np.isfinite(dn).all()
        assert np.count_nonzero(dp[sides != k // 2]) == 0, f'{names[k]} affects the opposite eye'
        assert np.count_nonzero(dn[sides != k // 2]) == 0, f'{names[k]} shades the opposite eye'
        assert np.count_nonzero(dp[sides == k // 2]) > 0, f'{names[k]} is empty'
        assert abs(np.linalg.norm(ln + dn, axis=1) - 1).max() < 1e-5, f'{names[k]} normals invalid'
        delta.append(dp)
        delta_normal.append(dn)
    delta, delta_normal = np.array(delta), np.array(delta_normal)
    stationary = np.max(abs(delta), axis=(0, 2)) < 1e-10
    assert stationary.sum() >= 100, 'No stationary outer eyelid rim'
    assert all(np.all(sides[face] == sides[face[0]]) for face in lf), 'Lid triangles bridge both eyes'

    # Check vertices AND triangle centroids: vertices alone miss a flat chord
    # passing through the curved eyeball during half/closed interpolation.
    clearance, coverage, blink_samples = np.inf, [], 0
    iris_radius = float(metadata.get('irisRadius', .035))
    for amount in np.linspace(0, 1, 21):
        weights = np.tile([min(amount * 2, 2 - amount * 2), max(0, amount * 2 - 1)], 2)
        posed = lp + np.einsum('i,ijk->jk', weights, delta)
        posed_n = ln + np.einsum('i,ijk->jk', weights, delta_normal)
        assert np.isfinite(posed).all() and np.linalg.norm(posed_n, axis=1).min() > .1
        world = transform(posed, lid_matrix)
        for eye, (center, radius) in enumerate(zip(centers, radii)):
            local_faces = lf[sides[lf[:, 0]] == eye]
            samples = np.concatenate([world[sides == eye], world[local_faces].mean(1)]) - center
            rr = (samples[:, 0] / radius[0]) ** 2 + (samples[:, 1] / radius[1]) ** 2
            inside = rr < 1
            front = center[2] + radius[2] * np.sqrt(1 - rr[inside])
            distance = samples[inside, 2] + center[2] - front
            clearance = min(clearance, float(distance.min()))
            if amount == 1:
                grid = np.linspace(-iris_radius, iris_radius, 35)
                x, y = np.meshgrid(grid, grid)
                disk = x*x + y*y <= iris_radius**2
                xy = np.c_[x[disk] + center[0], y[disk] + center[1]]
                depth = projected_depth(world, local_faces, xy)
                rr_disk = ((xy[:, 0]-center[0])/radius[0])**2 + ((xy[:, 1]-center[1])/radius[1])**2
                eye_depth = center[2] + radius[2] * np.sqrt(np.maximum(0, 1-rr_disk))
                visible = np.isfinite(depth) & (depth >= eye_depth - 2e-5)
                fraction = float(visible.mean())
                coverage.append(fraction)
                assert visible.all(), f'Eye {eye}: closed lid exposes {int((~visible).sum())} iris samples'
        blink_samples += 1
    assert clearance >= -2e-5, f'Lids intersect eyeballs by {-clearance:.6g}'

    # Exact animation/hierarchy preservation plus sampled composed transforms.
    # Morph positions are local to Head, so all blend states share this bound.
    rigid_drift, poses = 0., 0
    local_rest = {}
    for name, points in attached.items():
        ni = after.names[name]
        local_rest[name] = np.linalg.inv(after.rest_world[head]) @ after.rest_world[ni]
    for clip, channels in after.clips.items():
        duration = max(float(channel[2][-1]) for channel in channels)
        for time in np.linspace(0, duration, 9):
            world = after.world(after.pose(clip, time))
            old_world = before.world(before.pose(clip, time))
            assert np.allclose(world[:len(before.nodes)], old_world, atol=1e-10), 'Original animated pose changed'
            for name, points in attached.items():
                ni = after.names[name]
                expected = transform(points, world[head] @ local_rest[name])
                actual = transform(points, world[ni])
                rigid_drift = max(rigid_drift, float(np.linalg.norm(expected - actual, axis=1).max()))
            poses += 1
    assert rigid_drift < 1e-6, 'Eye/lid attachment drifted during animation'
    return dict(originalAccessorsPreserved=len(bg['accessors']), originalImagesPreserved=len(bg['images']),
                originalSkeletonJoints=29, clipsPreserved=len(before.clips), poses=poses,
                bodyScalpHatUnchanged=True, glassesIndependent=True,
                originalFrameFaces=len(old_faces), remainingFrameFaces=len(faces),
                eyeCenters=centers.tolist(), eyeRadii=radii.tolist(),
                maxNormalLengthError=normal_error, maxAnimatedAttachmentDrift=rigid_drift,
                independentMorphTargets=4, stationaryLidVertices=int(stationary.sum()),
                blinkSamples=blink_samples, minSampledLidClearance=float(clearance),
                closedIrisCoverage=coverage, irisTestRadius=iris_radius,
                limitations=['Iris coverage uses frontal orthographic samples; oblique/gaze rendering needs visual review.',
                             'Clearance samples vertices and triangle centers at 21 blink amounts, not continuous collision proof.',
                             'Runtime checkbox behavior, material appearance and blink timing need browser/app verification.'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = check(args.before, args.after)
    text = json.dumps(report, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text + '\n', encoding='utf-8')
    print(text)
