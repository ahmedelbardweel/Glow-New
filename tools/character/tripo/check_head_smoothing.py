"""Verify continuous head skin while preserving the rig and facial animation."""
import argparse
import copy
import json
import tempfile
from pathlib import Path

import numpy as np

from check_wave import read, write_diagnostic
from smooth_head import TYPES, WIDTH, smooth
from validate_deformation import Rig


def validate(before, after, output):
    old, old_binary = read(before)
    new, binary = read(after)
    assert binary[:len(old_binary)] == old_binary
    for key in ('nodes', 'skins', 'animations', 'scenes', 'scene'):
        assert old.get(key) == new.get(key), f'Unexpected change to {key}'
    for key in ('accessors', 'bufferViews', 'images', 'textures'):
        assert new[key][:len(old[key])] == old[key]

    def accessor(doc, blob, index):
        a = doc['accessors'][index]
        view = doc['bufferViews'][a['bufferView']]
        return np.frombuffer(blob, dtype=TYPES[a['componentType']],
                             count=a['count']*WIDTH[a['type']],
                             offset=view.get('byteOffset', 0)+a.get('byteOffset', 0)).reshape(a['count'], -1)

    changed = ('Body', 'Scalp', 'EyeSocketSkin')
    geometry = {}
    for node in old['nodes']:
        if 'mesh' not in node:
            continue
        name = node['name']
        a, b = old['meshes'][node['mesh']], new['meshes'][node['mesh']]
        if name not in changed:
            assert a == b, f'Unexpected mesh edit: {name}'
            continue
        expected = copy.deepcopy(a)
        ap, bp = a['primitives'][0], b['primitives'][0]
        allowed = ['POSITION', 'NORMAL'] + ([] if name == 'Body' else ['COLOR_0'])
        for key in allowed:
            expected['primitives'][0]['attributes'][key] = bp['attributes'][key]
        if name == 'Body':
            expected['primitives'][0]['material'] = bp['material']
        assert expected == b, f'Unexpected topology, UV or skin-weight edit: {name}'
        av = accessor(old, old_binary, ap['attributes']['POSITION'])
        bv = accessor(new, binary, bp['attributes']['POSITION'])
        normal = accessor(new, binary, bp['attributes']['NORMAL'])
        assert np.isfinite(bv).all() and np.isfinite(normal).all()
        assert np.abs(np.linalg.norm(normal, axis=1)-1).max() < 1e-6
        protected = av[:, 1] <= .43 + .25*smooth((av[:, 2]-.03)/.15)
        assert np.array_equal(av[protected], bv[protected]), f'Protected face/body moved: {name}'
        assert np.linalg.norm(bv-av, axis=1).max() < .022
        geometry[name] = (av, bv, normal)

    # A single spatial deformation must retain every shared scalp/body point.
    body, scalp = geometry['Body'], geometry['Scalp']
    lookup = {tuple(p): i for i, p in enumerate(np.round(body[0], 6))}
    pairs = [(lookup[tuple(p)], j) for j, p in enumerate(np.round(scalp[0], 6)) if tuple(p) in lookup]
    assert len(pairs) >= 1900
    bi, si = np.array(pairs).T
    assert np.linalg.norm(body[1][bi]-scalp[1][si], axis=1).max() < 1e-6
    assert np.linalg.norm(body[2][bi]-scalp[2][si], axis=1).max() < 1e-6

    output.parent.mkdir(parents=True, exist_ok=True)
    samples, maximum_gap = 0, 0.
    with tempfile.TemporaryDirectory(prefix='head_check_', dir=output.parent) as directory:
        path = Path(directory)/'skeletal.glb'
        write_diagnostic(path, new, binary)
        rig = Rig(path)
        meshes = {p['name']: p for p in rig.primitives}
        for clip, channels in rig.clips.items():
            duration = max(float(channel[2][-1]) for channel in channels)
            for time in np.linspace(0, duration, 9):
                world = rig.world(rig.pose(clip, time))
                a = Rig.deform(meshes['Body'], world)
                b = Rig.deform(meshes['Scalp'], world)
                c = Rig.deform(meshes['EyeSocketSkin'], world)
                assert all(np.isfinite(v).all() for v in (a, b, c))
                maximum_gap = max(maximum_gap, float(np.linalg.norm(a[bi]-b[si], axis=1).max()))
                samples += 1
    assert maximum_gap < 1e-6
    result = dict(existingBinaryBytesPreserved=len(old_binary), unchangedRigAndAnimations=True,
                  faceAndLimbsPreserved=True, accessoriesAndMouthPreserved=True,
                  matchingBoundaryVertices=len(pairs), animatedPoses=samples,
                  maximumAnimatedSeamGap=maximum_gap)
    output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    validate(args.before, args.after, args.output)
