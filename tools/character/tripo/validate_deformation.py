"""Measure actual GLB animation deformation, including UV seams and crossfades.

Usage:
    python tools/character/tripo/validate_deformation.py before.glb after.glb --output report.json

This is a read-only diagnostic, not a visual quality score. It skins vertices
using each file's exported animations. Ratios compare edge length to that file's
bind shape; they therefore do not measure changes to the underlying sculpture.
Percentiles are computed per frame, and the worst frame percentile is reported.
UV-split copies of an edge count once; separation of duplicate vertices is also
checked independently. Tiny bind edges below 1e-5 of body height are excluded.
Requires NumPy and SciPy. Supports ordinary uncompressed glTF 2.0 GLBs with
LINEAR, STEP, or CUBICSPLINE skeletal animation; morph targets are rejected.
"""

import argparse
import json
import struct
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation


DTYPES = {5120: '<i1', 5121: '<u1', 5122: '<i2', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


def slerp(a, b, fraction):
    """Shortest-path quaternion interpolation, glTF's xyzw order."""
    dot = np.sum(a * b, axis=-1, keepdims=True)
    b = np.where(dot < 0, -b, b)
    dot = np.abs(dot).clip(0, 1)
    angle = np.arccos(dot)
    denominator = np.sin(angle)
    safe = np.maximum(denominator, 1e-10)
    curved = (np.sin((1 - fraction) * angle) * a + np.sin(fraction * angle) * b) / safe
    linear = (1 - fraction) * a + fraction * b
    result = np.where(dot > 0.9995, linear, curved)
    return result / np.linalg.norm(result, axis=-1, keepdims=True)


class Rig:
    def __init__(self, path):
        self.path = Path(path)
        raw = self.path.read_bytes()
        magic, version, length = struct.unpack_from('<III', raw)
        if magic != 0x46546C67 or version != 2 or length != len(raw):
            raise ValueError(f'{path}: invalid GLB header')
        chunks = {}
        cursor = 12
        while cursor < len(raw):
            size, kind = struct.unpack_from('<II', raw, cursor)
            cursor += 8
            chunks[kind] = raw[cursor:cursor + size]
            cursor += size
        self.doc = json.loads(chunks[0x4E4F534A])
        self.binary = chunks[0x004E4942]
        self.nodes = self.doc['nodes']
        self.parents = np.full(len(self.nodes), -1, dtype=int)
        for i, node in enumerate(self.nodes):
            for child in node.get('children', []):
                self.parents[child] = i
        self.base = (
            np.array([n.get('translation', [0, 0, 0]) for n in self.nodes], dtype=float),
            np.array([n.get('rotation', [0, 0, 0, 1]) for n in self.nodes], dtype=float),
            np.array([n.get('scale', [1, 1, 1]) for n in self.nodes], dtype=float),
        )
        self.static_matrices = {i: np.array(n['matrix']).reshape(4, 4).T
                                for i, n in enumerate(self.nodes) if 'matrix' in n}
        self.rest_world = self.world(self.base)
        self.names = {n.get('name', ''): i for i, n in enumerate(self.nodes)}
        self.clips = {}
        for i, animation in enumerate(self.doc.get('animations', [])):
            channels = []
            for channel in animation['channels']:
                path = channel['target']['path']
                if path == 'weights':
                    raise ValueError('Morph animation is not supported by this validator')
                sampler = animation['samplers'][channel['sampler']]
                channels.append((channel['target']['node'], path,
                                 self.accessor(sampler['input']).ravel(),
                                 self.accessor(sampler['output']),
                                 sampler.get('interpolation', 'LINEAR')))
            self.clips[animation.get('name', str(i))] = channels
        self.primitives = []
        for node_index, node in enumerate(self.nodes):
            if 'mesh' not in node or 'skin' not in node:
                continue
            skin = self.doc['skins'][node['skin']]
            inverse = (self.accessor(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
                       if 'inverseBindMatrices' in skin else np.tile(np.eye(4), (len(skin['joints']), 1, 1)))
            for primitive in self.doc['meshes'][node['mesh']]['primitives']:
                if primitive.get('mode', 4) != 4 or primitive.get('targets'):
                    raise ValueError('Only triangles without morph targets are supported')
                attrs = primitive['attributes']
                vertices = self.accessor(attrs['POSITION'])
                joints, weights = [], []
                for k in range(8):
                    if f'JOINTS_{k}' not in attrs:
                        break
                    joints.append(self.accessor(attrs[f'JOINTS_{k}']).astype(int))
                    weights.append(self.accessor(attrs[f'WEIGHTS_{k}']))
                if not joints:
                    raise ValueError('Skinned primitive has no weights')
                faces = (self.accessor(primitive['indices']).ravel().astype(int)
                         if 'indices' in primitive else np.arange(len(vertices)))
                self.primitives.append(dict(name=node.get('name', str(node_index)), vertices=vertices,
                                            faces=faces.reshape(-1, 3), joints=np.concatenate(joints, axis=1),
                                            weights=np.concatenate(weights, axis=1), inverse=inverse,
                                            joint_nodes=np.array(skin['joints'])))
        if not self.primitives:
            raise ValueError('No skinned primitives found')

    def accessor(self, index):
        a = self.doc['accessors'][index]
        if 'sparse' in a:
            raise ValueError('Sparse accessors are not supported')
        dtype = np.dtype(DTYPES[a['componentType']])
        width = WIDTHS[a['type']]
        view = self.doc['bufferViews'][a['bufferView']]
        if view.get('buffer', 0) != 0:
            raise ValueError('External buffers are not supported')
        offset = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        value = np.ndarray((a['count'], width), dtype=dtype, buffer=self.binary,
                           offset=offset, strides=(view.get('byteStride', width * dtype.itemsize), dtype.itemsize)).copy()
        if a.get('normalized'):
            limit = np.iinfo(dtype).max
            value = np.maximum(value.astype(float) / limit, -1)
        return value

    def world(self, pose):
        translation, quaternion, scale = pose
        local = np.tile(np.eye(4), (len(self.nodes), 1, 1))
        local[:, :3, :3] = Rotation.from_quat(quaternion).as_matrix() * scale[:, None, :]
        local[:, :3, 3] = translation
        for i, value in self.static_matrices.items():
            local[i] = value
        result = np.empty_like(local)
        done = np.zeros(len(local), dtype=bool)

        def visit(i):
            if not done[i]:
                parent = self.parents[i]
                result[i] = local[i] if parent < 0 else visit(parent) @ local[i]
                done[i] = True
            return result[i]

        for i in range(len(local)):
            visit(i)
        return result

    def pose(self, name, time):
        pose = tuple(value.copy() for value in self.base)
        if name is None:
            return pose
        for node, path, times, values, interpolation in self.clips[name]:
            right = int(np.searchsorted(times, time, side='right').clip(1, len(times) - 1)) if len(times) > 1 else 0
            left = max(0, right - 1)
            duration = float(times[right] - times[left])
            f = np.clip((time - times[left]) / duration, 0, 1) if duration else 0
            if interpolation == 'CUBICSPLINE':
                a, b = values[left * 3 + 1], values[right * 3 + 1]
                value = ((2*f**3 - 3*f**2 + 1)*a + (f**3 - 2*f**2 + f)*duration*values[left*3 + 2]
                         + (-2*f**3 + 3*f**2)*b + (f**3 - f**2)*duration*values[right*3])
                if path == 'rotation':
                    value /= np.linalg.norm(value)
            elif interpolation == 'STEP':
                value = values[int(np.searchsorted(times, time, side='right') - 1).clip(0, len(times)-1)]
            elif interpolation == 'LINEAR':
                value = (slerp(values[left], values[right], f) if path == 'rotation'
                         else (1-f)*values[left] + f*values[right])
            else:
                raise ValueError(f'Unsupported interpolation: {interpolation}')
            pose[{'translation': 0, 'rotation': 1, 'scale': 2}[path]][node] = value
        return pose

    @staticmethod
    def deform(primitive, world):
        matrices = world[primitive['joint_nodes']] @ primitive['inverse']
        vertices = primitive['vertices']
        result = np.zeros_like(vertices, dtype=float)
        for k in range(primitive['joints'].shape[1]):
            matrix = matrices[primitive['joints'][:, k]]
            result += primitive['weights'][:, k, None] * (
                np.einsum('nij,nj->ni', matrix[:, :3, :3], vertices) + matrix[:, :3, 3])
        return result


def prepare_regions(rig, primitive):
    vertices = Rig.deform(primitive, rig.rest_world)
    height = float(np.ptp(vertices[:, 1]))
    tolerance = max(height * 1e-7, 1e-10)
    _, representative, inverse = np.unique(np.rint(vertices / tolerance).astype(np.int64),
                                            axis=0, return_index=True, return_inverse=True)
    faces = primitive['faces']
    edges = np.sort(np.concatenate((faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]])), axis=1)
    physical_edges = np.sort(inverse[edges], axis=1)
    _, first = np.unique(physical_edges, axis=0, return_index=True)
    edges = edges[first]
    lengths = np.linalg.norm(vertices[edges[:, 1]] - vertices[edges[:, 0]], axis=1)
    keep = lengths >= height * 1e-5
    edges, lengths = edges[keep], lengths[keep]
    center = vertices[edges].mean(axis=1)
    masks = {'all': np.ones(len(edges), dtype=bool)}
    region_bounds = {}
    required = ('Hips', 'Neck', 'LeftArm', 'RightArm', 'LeftForeArm', 'RightForeArm')
    if all(name in rig.names for name in required):
        joint = {name: rig.rest_world[rig.names[name], :3, 3] for name in required}
        x0 = float(joint['Hips'][0])
        arm_x = float(np.mean([abs(joint[n][0]-x0) for n in ('LeftArm', 'RightArm')]))
        elbow_x = float(np.mean([abs(joint[n][0]-x0) for n in ('LeftForeArm', 'RightForeArm')]))
        low, high = joint['Hips'][1] - .01*height, joint['Neck'][1] + .01*height
        x = abs(center[:, 0]-x0)
        upper = (center[:, 1] > low) & (center[:, 1] < high)
        masks['torso_sides'] = upper & (x >= arm_x*.4) & (x <= arm_x*1.25)
        masks['upper_arms'] = upper & (x >= arm_x*.8) & (x <= elbow_x*1.08)
        masks['forearms_hands'] = upper & (x > elbow_x*.9)
        for side, sign in (('left', 1), ('right', -1)):
            masks[f'{side}_torso_side'] = masks['torso_sides'] & ((center[:, 0]-x0)*sign > 0)
        region_bounds = dict(y_min=float(low), y_max=float(high), center_x=x0,
                             arm_pivot_x=arm_x, elbow_pivot_x=elbow_x)
    return dict(edges=edges, lengths=lengths, masks=masks, representative=representative[inverse],
                duplicate_count=int(len(vertices)-len(representative)), region_bounds=region_bounds,
                excluded_tiny_edges=int((~keep).sum()))


def update_metrics(destination, posed, region, frame):
    if not np.isfinite(posed).all():
        raise ValueError(f'Non-finite deformed vertices at {frame}')
    edges = region['edges']
    ratios = np.linalg.norm(posed[edges[:, 1]]-posed[edges[:, 0]], axis=1) / region['lengths']
    for name, mask in region['masks'].items():
        values = ratios[mask]
        if not len(values):
            continue
        low, high, extreme, maximum = np.percentile(values, [1, 99, 99.9, 100])
        metrics = {'stretch_p99': high, 'stretch_p999': extreme, 'stretch_max': maximum,
                   'compression_p01': low, 'compression_min': float(values.min())}
        target = destination.setdefault(name, {'edge_count': int(mask.sum())})
        for key, value in metrics.items():
            minimum = key.startswith('compression')
            previous = target.get(key, {}).get('ratio', np.inf if minimum else -np.inf)
            if (value < previous) if minimum else (value > previous):
                target[key] = {'ratio': float(value), 'frame': frame}
    separation = float(np.linalg.norm(posed-posed[region['representative']], axis=1).max())
    if separation > destination.get('uv_seam_separation_max', {}).get('distance', -1):
        destination['uv_seam_separation_max'] = dict(distance=separation, frame=frame)


def validate(path, fps=15, transitions=True, transition_duration=.35):
    rig = Rig(path)
    result = {'path': str(Path(path).resolve()), 'bytes': Path(path).stat().st_size,
              'sample_fps': fps, 'transition_duration': transition_duration, 'meshes': {}}
    prepared = []
    for i, primitive in enumerate(rig.primitives):
        weights, joints, faces = (primitive[k] for k in ('weights', 'joints', 'faces'))
        if not np.isfinite(weights).all() or not np.isfinite(primitive['vertices']).all():
            raise ValueError('Non-finite bind vertex or weight')
        if joints.min() < 0 or joints.max() >= len(primitive['joint_nodes']):
            raise ValueError('Joint index outside skin')
        if faces.min() < 0 or faces.max() >= len(weights):
            raise ValueError('Triangle index outside mesh')
        weight_error = float(np.abs(weights.sum(axis=1)-1).max())
        if weight_error > 1e-4 or weights.min() < 0:
            raise ValueError(f'Invalid skin weights: sum error {weight_error}, minimum {weights.min()}')
        region = prepare_regions(rig, primitive)
        key = primitive['name']
        if key in result['meshes']:
            key += f'_{i}'
        report = dict(vertices=len(weights), triangles=len(faces), weight_sum_max_error=weight_error,
                      duplicate_vertices=region['duplicate_count'], excluded_tiny_edges=region['excluded_tiny_edges'],
                      region_bounds=region['region_bounds'], clips={})
        result['meshes'][key] = report
        prepared.append((primitive, region, report))

    def sample(label, pose, time):
        world = rig.world(pose)
        for primitive, region, report in prepared:
            output = report['clips'].setdefault(label, {'sample_count': 0, 'metrics': {}})
            output['sample_count'] += 1
            update_metrics(output['metrics'], Rig.deform(primitive, world), region, round(float(time), 6))

    sample('bind', rig.base, 0)
    for name, channels in rig.clips.items():
        duration = max(float(channel[2][-1]) for channel in channels)
        frames = np.linspace(0, duration, max(2, int(np.ceil(duration*fps))+1))
        for time in frames:
            sample(name, rig.pose(name, time), time)
        # Evaluate seam closure separately from anatomical deformation.
        start, end = rig.world(rig.pose(name, 0)), rig.world(rig.pose(name, duration))
        for primitive, _, report in prepared:
            displacement = np.linalg.norm(Rig.deform(primitive, end)-Rig.deform(primitive, start), axis=1)
            report['clips'][name]['loop_vertex_displacement_max'] = float(displacement.max())
        if transitions and name != 'Idle' and 'Idle' in rig.clips:
            for reverse in (False, True):
                source, target = (name, 'Idle') if reverse else ('Idle', name)
                for fraction in np.linspace(0, 1, 9):
                    time = fraction * transition_duration
                    a, b = rig.pose(source, time), rig.pose(target, time)
                    mixed = ((1-fraction)*a[0]+fraction*b[0], slerp(a[1], b[1], fraction),
                             (1-fraction)*a[2]+fraction*b[2])
                    sample(f'{source}->{target}', mixed, time)
    return result


def compact(report):
    print(report['path'])
    for mesh, details in report['meshes'].items():
        print(f"  {mesh}: {details['vertices']} vertices; weight sum error {details['weight_sum_max_error']:.2g}")
        if mesh.lower() != 'body':
            continue
        for name, clip in details['clips'].items():
            if '->' in name or name == 'bind':
                continue
            entries = []
            for region in ('torso_sides', 'upper_arms', 'forearms_hands'):
                metric = clip['metrics'].get(region)
                if metric:
                    entries.append(f"{region}: {metric['stretch_p99']['ratio']:.3f}/{metric['stretch_p999']['ratio']:.3f}/{metric['stretch_max']['ratio']:.3f}")
            print(f"    {name}: " + '; '.join(entries) + f"; loop gap {clip['loop_vertex_displacement_max']:.6f}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('paths', nargs='+', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--fps', type=int, default=15)
    parser.add_argument('--no-transitions', action='store_true')
    parser.add_argument('--transition-duration', type=float, default=.35)
    args = parser.parse_args()
    if args.fps < 1 or args.transition_duration <= 0:
        parser.error('fps and transition duration must be positive')
    reports = []
    print('Ratios shown: worst frame p99 / p99.9 / max; 1.0 = unchanged edge length.', flush=True)
    for path in args.paths:
        report = validate(path, args.fps, not args.no_transitions, args.transition_duration)
        reports.append(report)
        compact(report)
    if args.output:
        args.output.write_text(json.dumps({'reports': reports}, indent=2), encoding='utf-8')
        print(f'Wrote {args.output}')


if __name__ == '__main__':
    main()
