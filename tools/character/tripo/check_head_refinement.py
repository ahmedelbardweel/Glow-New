"""Check that lower-cheek protection preserves the model and clip data."""
import argparse
import numpy as np
from validate_deformation import Rig


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('before')
    p.add_argument('after')
    args = p.parse_args()
    before, after = Rig(args.before), Rig(args.after)
    assert before.doc['nodes'] == after.doc['nodes'], 'Skeleton changed'
    assert before.doc['animations'] == after.doc['animations'], 'Clips changed'
    assert before.doc['materials'] == after.doc['materials'], 'Materials changed'
    for old, new in zip(before.primitives, after.primitives):
        assert np.array_equal(old['vertices'], new['vertices']), 'Sculpture changed'
        assert np.array_equal(old['faces'], new['faces']), 'Topology changed'
    for old, new in zip(before.doc['meshes'], after.doc['meshes']):
        for a, b in zip(old['primitives'], new['primitives']):
            for attribute in ('TEXCOORD_0', 'NORMAL'):
                assert np.array_equal(before.accessor(a['attributes'][attribute]),
                                      after.accessor(b['attributes'][attribute])), attribute
    for old, new in zip(before.doc['images'], after.doc['images']):
        def image(rig, data):
            view = rig.doc['bufferViews'][data['bufferView']]
            start = view.get('byteOffset', 0)
            return rig.binary[start:start + view['byteLength']]
        assert image(before, old) == image(after, new), 'Embedded texture changed'
    body = next(part for part in after.primitives if part['name'] == 'Body')
    v = body['vertices']
    # Weight fields use the original bind coordinates, while v contains the
    # earlier <= .003 side fairing. Stay .004 inside the rigid region so the
    # soft neck boundary is not mistaken for a cheek regression.
    cheek = (v[:, 1] >= .434) & (v[:, 1] < .53) & (np.abs(v[:, 0]) <= .261)
    head = after.names['Head']
    local_head = list(body['joint_nodes']).index(head)
    influence = np.sum(body['weights'] * (body['joints'] == local_head), axis=1)
    assert cheek.any() and np.allclose(influence[cheek], 1), 'Cheek still follows another bone'
    peak = 0.
    count = 0
    for name, channels in after.clips.items():
        duration = max(c[2][-1] for c in channels)
        for t in np.linspace(0, duration, 9):
            world = after.world(after.pose(name, t))
            actual = Rig.deform(body, world)
            transform = world[head] @ body['inverse'][local_head]
            expected = v @ transform[:3, :3].T + transform[:3, 3]
            peak = max(peak, np.linalg.norm(actual[cheek] - expected[cheek], axis=1).max())
            assert np.isfinite(actual).all()
            count += 1
    assert peak < 1e-6, f'Cheek separation {peak}'
    print(f'PASS: {cheek.sum()} lower-head vertices remain rigid across {count} poses; max drift {peak:.3g}')
    print('PASS: shape, normals, UVs, textures, skeleton and animation definitions preserved')


if __name__ == '__main__':
    main()
