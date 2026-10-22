"""Validate the four-part mouth and preserve all unrelated model changes."""
import argparse
import json
from pathlib import Path
import numpy as np
from check_wave import read
from smooth_head import TYPES, WIDTH


def validate(before, after, output):
    old, old_binary = read(before)
    new, binary = read(after)
    assert binary[:len(old_binary)] == old_binary
    for key in ('accessors', 'bufferViews', 'materials', 'images', 'textures'):
        assert new[key][:len(old[key])] == old[key], key
    assert new['skins'] == old['skins'] and new['scenes'] == old['scenes']
    names = {n['name']: i for i, n in enumerate(new['nodes'])}
    for i, node in enumerate(old['nodes']):
        expected = dict(node)
        if node['name'] == 'Head':
            expected['children'] = node['children'] + [names['MouthTeeth'], names['MouthTongue']]
        assert new['nodes'][i] == expected
        if 'mesh' in node and node['name'] not in ('Body', 'ExpressiveMouth'):
            assert new['meshes'][node['mesh']] == old['meshes'][node['mesh']], node['name']

    def get(g, blob, index):
        a = g['accessors'][index]; view = g['bufferViews'][a['bufferView']]
        return np.frombuffer(blob, dtype=TYPES[a['componentType']],
                             count=a['count']*WIDTH[a['type']],
                             offset=view.get('byteOffset', 0)+a.get('byteOffset', 0)).reshape(a['count'], -1)

    op = old['meshes'][old['nodes'][names['Body']]['mesh']]['primitives'][0]
    bp = new['meshes'][new['nodes'][names['Body']]['mesh']]['primitives'][0]
    source = get(old, old_binary, op['attributes']['POSITION'])
    rest = get(new, binary, bp['attributes']['POSITION'])
    protected = ((abs(source[:, 0]) > .115) | (source[:, 1] > .585) |
                 (source[:, 1] < .42) | (source[:, 2] < .19))
    assert np.array_equal(source[protected], rest[:len(source)][protected])
    for key in ('TEXCOORD_0', 'JOINTS_0', 'WEIGHTS_0', '_GLOW_SKIN_REGION'):
        assert np.array_equal(get(old, old_binary, op['attributes'][key]),
                              get(new, binary, bp['attributes'][key])[:len(source)])
    weights = get(new, binary, bp['attributes']['WEIGHTS_0'])
    assert np.max(abs(weights.sum(1)-1)) < 1e-6
    moving = new['extras']['mouthRefinement']['drivenNodes']
    assert len(moving) == 4
    meshes = []
    for node in moving:
        p = new['meshes'][new['nodes'][node]['mesh']]['primitives'][0]
        base = get(new, binary, p['attributes']['POSITION'])
        delta = np.array([get(new, binary, target['POSITION']) for target in p['targets']])
        normal = get(new, binary, p['attributes']['NORMAL'])
        assert len(delta) == 4 and np.isfinite(delta).all()
        assert np.max(abs(np.linalg.norm(normal, axis=1)-1)) < 1e-5
        if node == names['Body']:
            assert np.all(delta[:, :len(source), :][:, protected] == 0)
        else:
            assert node in new['nodes'][names['Head']]['children']
        meshes.append((base, delta))
    samples = 0
    for original, candidate in zip(old['animations'], new['animations']):
        original_channels = [c for c in original['channels'] if c['target']['node'] != names['ExpressiveMouth']]
        untouched_channels = [c for c in candidate['channels'] if c['target']['node'] not in moving]
        assert original_channels == untouched_channels
        for channel in untouched_channels:
            s = channel['sampler']
            assert candidate['samplers'][s] == original['samplers'][s]
        channels = [c for c in candidate['channels'] if c['target']['node'] in moving]
        assert len(channels) == 4 and len({c['sampler'] for c in channels}) == 1
        s = candidate['samplers'][channels[0]['sampler']]
        times = get(new, binary, s['input']).ravel()
        values = get(new, binary, s['output']).reshape(-1, 4)
        assert np.array_equal(values[0], values[-1])
        assert values.min() >= 0 and values.max() <= 1
        for t in np.linspace(0, times[-1], 61):
            w = np.array([np.interp(t, times, values[:, i]) for i in range(4)])
            for base, delta in meshes:
                posed = base + np.einsum('i,ijk->jk', w, delta)
                assert np.isfinite(posed).all()
                assert np.max(np.linalg.norm(posed-base, axis=1)) < .055
            samples += 1
    result = dict(existingBinaryPreserved=True, headAndAccessoriesPreserved=True,
                  originalUVsAndRigPreserved=True, localizedJawDeformation=True,
                  synchronizedMouthParts=4, loopedClips=len(new['animations']), poseSamples=samples)
    Path(output).write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before'); parser.add_argument('after'); parser.add_argument('--output', required=True)
    args = parser.parse_args(); validate(args.before, args.after, args.output)
