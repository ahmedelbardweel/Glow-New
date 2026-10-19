"""Verify the left pivot correction against the approved right arm."""
import argparse
import numpy as np
from validate_deformation import Rig


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('before'); p.add_argument('after')
    args = p.parse_args()
    old, new = Rig(args.before), Rig(args.after)
    assert old.doc['animations'] == new.doc['animations']
    for a, b in zip(old.primitives, new.primitives):
        for key in ('vertices', 'faces', 'weights', 'joints'):
            assert np.array_equal(a[key], b[key]), f'{key} changed'
        assert np.allclose(Rig.deform(a, old.rest_world),
                           Rig.deform(b, new.rest_world), atol=1e-7), 'Bind shape changed'
    a, b = old.primitives[0], new.primitives[0]
    v = b['vertices']
    right = v[:, 0] <= 0
    head = (v[:, 1] >= .434) & (np.abs(v[:, 0]) <= .261)
    max_right = max_head = 0.
    samples = 0
    for name, channels in new.clips.items():
        duration = max(c[2][-1] for c in channels)
        for t in np.linspace(0, duration, 9):
            before = Rig.deform(a, old.world(old.pose(name, t)))
            after = Rig.deform(b, new.world(new.pose(name, t)))
            assert np.isfinite(after).all()
            max_right = max(max_right, np.linalg.norm(after[right] - before[right], axis=1).max())
            max_head = max(max_head, np.linalg.norm(after[head] - before[head], axis=1).max())
            samples += 1
    assert max_right < 2e-7 and max_head < 2e-7, (max_right, max_head)
    idle = Rig.deform(b, new.world(new.pose('Idle', 0)))
    extents = []
    for sign in (1, -1):
        mask = (v[:, 0] * sign > .36) & (v[:, 1] > .15) & (v[:, 1] < .43)
        points = idle[mask].copy(); points[:, 0] *= sign
        extents.append((points.min(0), points.max(0)))
    error = np.max(np.abs(np.array(extents[0]) - np.array(extents[1])))
    assert error < .002, f'Posed hand bounding boxes differ by {error}'
    print(f'PASS: mirrored hand bounds match within {error:.6f} model units')
    print(f'PASS: bind geometry preserved, right side and round head unchanged across {samples} poses')
    print(f'Right drift {max_right:.3g}; head drift {max_head:.3g}')


if __name__ == '__main__':
    main()
