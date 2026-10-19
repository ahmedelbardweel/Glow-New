"""Check a Wave-only palm turn; retain original mouth/eye animation payloads.

The skeletal deformation check omits morph channels in a temporary diagnostic
copy. Exact JSON/binary checks separately prove those channels and their data
are unchanged in the delivered model.
"""
import argparse
import copy
import json
import struct
import tempfile
from pathlib import Path

import numpy as np

from validate_deformation import Rig, prepare_regions, slerp


def read(path):
    raw = Path(path).read_bytes()
    magic, version, length = struct.unpack_from('<III', raw)
    assert (magic, version, length) == (0x46546C67, 2, len(raw))
    chunks = {}
    offset = 12
    while offset < len(raw):
        size, kind = struct.unpack_from('<II', raw, offset)
        chunks[kind] = raw[offset + 8:offset + 8 + size]
        offset += 8 + size
    return json.loads(chunks[0x4E4F534A]), chunks[0x004E4942]


def write_diagnostic(path, doc, binary):
    doc = copy.deepcopy(doc)
    for animation in doc['animations']:
        animation['channels'] = [channel for channel in animation['channels']
                                 if channel['target']['path'] != 'weights']
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            primitive.pop('targets', None)
    text = json.dumps(doc, separators=(',', ':')).encode()
    text += b' ' * (-len(text) % 4)
    binary += b'\0' * (-len(binary) % 4)
    Path(path).write_bytes(
        struct.pack('<III', 0x46546C67, 2, 28 + len(text) + len(binary))
        + struct.pack('<II', len(text), 0x4E4F534A) + text
        + struct.pack('<II', len(binary), 0x004E4942) + binary)


def measure(rig):
    primitive = next(p for p in rig.primitives if p['name'] == 'Body')
    region = prepare_regions(rig, primitive)
    edges = region['edges']
    right = primitive['vertices'][edges].mean(1)[:, 0] < -.27
    edges, lengths = edges[right], region['lengths'][right]
    duration = max(float(c[2][-1]) for c in rig.clips['Wave'])
    result = dict(wavePoses=61, crossfadePoses=18, stretchP99=0.,
                  compressionP01=1., uvSeamSeparation=0., finite=True)

    def sample(pose):
        posed = Rig.deform(primitive, rig.world(pose))
        assert np.isfinite(posed).all(), 'Non-finite skeletal deformation'
        ratios = np.linalg.norm(posed[edges[:, 0]] - posed[edges[:, 1]], axis=1) / lengths
        low, high = np.percentile(ratios, [1, 99])
        result['stretchP99'] = max(result['stretchP99'], float(high))
        result['compressionP01'] = min(result['compressionP01'], float(low))
        seam = np.linalg.norm(posed - posed[region['representative']], axis=1).max()
        result['uvSeamSeparation'] = max(result['uvSeamSeparation'], float(seam))

    for time in np.linspace(0, duration, 61):
        sample(rig.pose('Wave', time))
    for source, target in [('Idle', 'Wave'), ('Wave', 'Idle')]:
        for fraction in np.linspace(0, 1, 9):
            a, b = rig.pose(source, fraction * .35), rig.pose(target, fraction * .35)
            pose = ((1-fraction)*a[0] + fraction*b[0],
                    slerp(a[1], b[1], fraction),
                    (1-fraction)*a[2] + fraction*b[2])
            sample(pose)
    start = Rig.deform(primitive, rig.world(rig.pose('Wave', 0)))
    end = Rig.deform(primitive, rig.world(rig.pose('Wave', duration)))
    result['loopDisplacement'] = float(np.linalg.norm(end-start, axis=1).max())
    assert result['loopDisplacement'] < 1e-5
    assert result['uvSeamSeparation'] < 1e-5
    return result


def validate(before, after, output):
    old, old_binary = read(before)
    new, new_binary = read(after)
    assert new_binary[:len(old_binary)] == old_binary, 'Existing binary data changed'
    assert new['accessors'][:len(old['accessors'])] == old['accessors']
    assert new['bufferViews'][:len(old['bufferViews'])] == old['bufferViews']
    assert len(new['accessors']) == len(old['accessors']) + 2
    assert len(new['bufferViews']) == len(old['bufferViews']) + 2
    expected = copy.deepcopy(old)
    expected['accessors'] = new['accessors']
    expected['bufferViews'] = new['bufferViews']
    expected['buffers'][0]['byteLength'] = new['buffers'][0]['byteLength']
    expected.setdefault('extras', {})['wavePalmRefinement'] = new['extras']['wavePalmRefinement']
    changed = []
    for i, (original, candidate) in enumerate(zip(old['animations'], new['animations'])):
        if original['name'] != 'Wave':
            assert original == candidate, f"Changed clip: {original['name']}"
            continue
        assert original['channels'] == candidate['channels']
        for channel in original['channels']:
            target = channel['target']
            name = old['nodes'][target['node']]['name']
            if target['path'] != 'rotation' or name not in ('RightForeArm', 'RightHand'):
                continue
            index = channel['sampler']
            old_sampler, new_sampler = original['samplers'][index], candidate['samplers'][index]
            assert old_sampler['output'] != new_sampler['output']
            expected['animations'][i]['samplers'][index]['output'] = new_sampler['output']
            changed.append(name)
    assert sorted(changed) == ['RightForeArm', 'RightHand']
    assert expected == new, 'Unexpected change outside the two Wave rotation outputs'
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='wave_check_', dir=output.parent) as temp:
        old_path, new_path = Path(temp) / 'before.glb', Path(temp) / 'after.glb'
        write_diagnostic(old_path, old, old_binary)
        write_diagnostic(new_path, new, new_binary)
        old_rig, new_rig = Rig(old_path), Rig(new_path)
        quaternion_error = 0.
        for node, path, _, values, _ in new_rig.clips['Wave']:
            if path == 'rotation' and new_rig.nodes[node]['name'] in changed:
                quaternion_error = max(quaternion_error, float(np.abs(np.linalg.norm(values, axis=1)-1).max()))
                assert abs(float(values[0] @ values[-1])) > 1-1e-6
        assert quaternion_error < 1e-5
        old_metrics, new_metrics = measure(old_rig), measure(new_rig)
    # Bound deformation relative to the approved mesh's existing Wave. The
    # anatomical twist may stretch skin modestly but must not collapse a cuff.
    assert new_metrics['stretchP99'] <= old_metrics['stretchP99'] * 1.25
    assert new_metrics['compressionP01'] >= old_metrics['compressionP01'] * .75
    result = dict(onlyWaveForearmAndHandChanged=True, existingBinaryBytesPreserved=len(old_binary),
                  allOtherClipsAndMorphsPreserved=True, geometryAndMaterialsPreserved=True,
                  quaternionNormError=quaternion_error, before=old_metrics, after=new_metrics)
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    validate(args.before, args.after, args.output)
