"""CPU-check the legacy procedural mascot, not the supplied port_frontal rig.

For the active asset use check_port_rig.py with the unchanged source GLB.

Run ``python tools/character/check_animation_safety.py`` after generating the GLB.
Unlike check_refinement, this permits new materials, proportions and bind poses.
It samples every vertex, but is a structural safety check, not visual approval.
"""
from __future__ import annotations

import argparse
from bisect import bisect_right
import json
import math
from pathlib import Path
import struct

from check_refinement import Glb, ROOT, geometry, require


CLIPS = {"Idle", "Talk", "Wave", "Happy", "Sad", "Thinking", "Victory", "Walk"}
IDENTITY = (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0)


def expected_parents():
    parents = {"Root": None, "Hips": "Root", "Spine": "Hips", "Chest": "Spine",
               "Neck": "Chest", "Head": "Neck", "Jaw": "Head", "Mouth": "Head"}
    for side, tag in (("Left", "L"), ("Right", "R")):
        parents.update({side + "UpperArm": "Chest", side + "ForeArm": side + "UpperArm",
                        side + "Hand": side + "ForeArm", side + "UpperLeg": "Hips",
                        side + "LowerLeg": side + "UpperLeg", side + "Foot": side + "LowerLeg"})
        for digit in range(1, 4):
            parents[side + f"Finger{digit}"] = side + "Hand"
            parents[side + f"Toe{digit}"] = side + "Foot"
        for face in ("Eye", "UpperEyelid", "LowerEyelid", "Brow"):
            parents[face + "_" + tag] = "Head"
    parents.update({"Tail1": "Hips", "Tail2": "Tail1", "Tail3": "Tail2"})
    return parents


def multiply(a, b):
    # Row-major affine 3 x 4 matrices; the implied last row is (0, 0, 0, 1).
    return tuple(sum(a[r * 4 + k] * b[k * 4 + c] for k in range(3)) +
                 (a[r * 4 + 3] if c == 3 else 0)
                 for r in range(3) for c in range(4))


def affine(values):
    require(len(values) == 16 and all(math.isfinite(v) for v in values),
            "Invalid 4 x 4 matrix")
    require(all(abs(values[i] - v) < 1e-6 for i, v in ((3, 0), (7, 0), (11, 0), (15, 1))),
            "Expected an affine matrix")
    return tuple(values[c * 4 + r] for r in range(3) for c in range(4))


def trs(translation, rotation, scale):
    x, y, z, w = rotation
    require(abs(sum(v * v for v in rotation) - 1) < 1e-4, "Non-unit bone quaternion")
    sx, sy, sz = scale
    tx, ty, tz = translation
    return ((1 - 2 * (y*y + z*z)) * sx, 2 * (x*y - z*w) * sy, 2 * (x*z + y*w) * sz, tx,
            2 * (x*y + z*w) * sx, (1 - 2 * (x*x + z*z)) * sy, 2 * (y*z - x*w) * sz, ty,
            2 * (x*z - y*w) * sx, 2 * (y*z + x*w) * sy, (1 - 2 * (x*x + y*y)) * sz, tz)


def transform(matrix, point):
    x, y, z = point
    return (matrix[0]*x + matrix[1]*y + matrix[2]*z + matrix[3],
            matrix[4]*x + matrix[5]*y + matrix[6]*z + matrix[7],
            matrix[8]*x + matrix[9]*y + matrix[10]*z + matrix[11])


def quaternion_mix(a, b, amount):
    dot = sum(x*y for x, y in zip(a, b))
    if dot < 0:
        b, dot = tuple(-v for v in b), -dot
    if dot > .9995:
        mixed = tuple(x + amount*(y-x) for x, y in zip(a, b))
    else:
        theta = math.acos(max(-1, min(1, dot)))
        denominator = math.sin(theta)
        first, second = math.sin((1-amount)*theta)/denominator, math.sin(amount*theta)/denominator
        mixed = tuple(first*x + second*y for x, y in zip(a, b))
    length = math.sqrt(sum(v*v for v in mixed))
    require(length > 1e-10, "Zero-length interpolated quaternion")
    return tuple(v/length for v in mixed)


def sample(track, time):
    times, values, interpolation, path = track
    index = min(len(times)-1, max(0, bisect_right(times, time)-1))
    if index == len(times)-1 or time <= times[0] or interpolation == "STEP":
        return values[index]
    amount = (time-times[index]) / (times[index+1]-times[index])
    a, b = values[index], values[index+1]
    if path == "rotation":
        return quaternion_mix(a, b, amount)
    return tuple(x + amount*(y-x) for x, y in zip(a, b))


def inspect_rig(glb):
    nodes = glb.doc["nodes"]
    parents = {}
    for parent, node in enumerate(nodes):
        for child in node.get("children", []):
            require(0 <= child < len(nodes) and child not in parents, "Invalid node parent links")
            parents[child] = parent
    require(len(glb.doc["skins"]) == 1, "Expected exactly one mascot skin")
    skin = glb.doc["skins"][0]
    joints = skin["joints"]
    expected = expected_parents()
    names = [nodes[index]["name"] for index in joints]
    require(len(names) == 43 and set(names) == set(expected), "The 43 named rig bones changed")
    for index, name in zip(joints, names):
        parent_name = nodes[parents[index]].get("name") if index in parents else None
        require(parent_name == expected[name], f"{name}: unexpected parent {parent_name}")
    require(skin.get("skeleton") == joints[names.index("Root")], "Skin skeleton is not Root")
    inverse = [affine(row) for row in glb.accessor(skin["inverseBindMatrices"])]
    require(len(inverse) == len(joints), "Inverse bind matrix count differs from joint count")
    return parents, joints, inverse


def world_matrices(nodes, parents, tracks=(), time=0):
    overrides = {(node, path): sample(track, time) for node, path, track in tracks}
    local = []
    for index, node in enumerate(nodes):
        if "matrix" in node:
            require(not any(key[0] == index for key in overrides), "Animated node has a matrix")
            local.append(affine(node["matrix"]))
        else:
            values = [overrides.get((index, key), node.get(key, default)) for key, default in
                      (("translation", (0, 0, 0)), ("rotation", (0, 0, 0, 1)), ("scale", (1, 1, 1)))]
            require(all(math.isfinite(v) for row in values for v in row), "Non-finite bone transform")
            local.append(trs(*values))
    cache, visiting = {}, set()

    def visit(index):
        require(index not in visiting, "Cycle in node hierarchy")
        if index not in cache:
            visiting.add(index)
            cache[index] = multiply(visit(parents[index]), local[index]) if index in parents else local[index]
            visiting.remove(index)
        return cache[index]

    return [visit(index) for index in range(len(nodes))]


def animation_tracks(glb, animation):
    tracks, targets = [], set()
    joint_nodes = set(glb.doc["skins"][0]["joints"])
    for channel in animation["channels"]:
        node, path = channel["target"]["node"], channel["target"]["path"]
        require(node in joint_nodes and path in ("translation", "rotation", "scale"),
                "Expected animation channels to target rig bone TRS")
        require((node, path) not in targets, "Duplicate animation target")
        targets.add((node, path))
        sampler = animation["samplers"][channel["sampler"]]
        interpolation = sampler.get("interpolation", "LINEAR")
        require(interpolation in ("LINEAR", "STEP"), f"Unsupported interpolation: {interpolation}")
        times = [row[0] for row in glb.accessor(sampler["input"])]
        values = glb.accessor(sampler["output"])
        require(len(times) >= 2 and len(times) == len(values), "Invalid animation sample count")
        require(all(math.isfinite(v) for v in times) and times[0] >= 0 and
                all(b > a for a, b in zip(times, times[1:])), "Invalid animation timestamps")
        require(all(len(row) == (4 if path == "rotation" else 3) and
                    all(math.isfinite(v) for v in row) for row in values), "Invalid animation values")
        if path == "rotation":
            require(all(abs(sum(v*v for v in row)-1) < 1e-4 for row in values),
                    "Animation contains a non-unit quaternion")
        tracks.append((node, path, (times, values, interpolation, path)))
    require(tracks, "Empty animation")
    return tracks


def channel_contract(glb):
    return {a["name"]: {(glb.doc["nodes"][c["target"]["node"]]["name"], c["target"]["path"])
                       for c in a["channels"]} for a in glb.doc.get("animations", [])}


def check(glb, samples, distance_ratio, reference=None):
    report = {"geometry": geometry(glb)}
    parents, joints, inverse = inspect_rig(glb)
    animations = glb.doc["animations"]
    require(len(animations) == 8 and {a["name"] for a in animations} == CLIPS,
            "Expected all eight named animations")
    if reference is not None:
        require(channel_contract(glb) == channel_contract(reference), "Animation target channels changed")
        report["referenceChannelsPreserved"] = True
    nodes = glb.doc["nodes"]
    rest_world = world_matrices(nodes, parents)
    rest_skin = [multiply(rest_world[joint], bind) for joint, bind in zip(joints, inverse)]
    vertices, originals = [], []
    for node_index, node in enumerate(nodes):
        if "mesh" not in node:
            continue
        require(node["skin"] == 0, "Expected every mesh to use the mascot skin")
        for primitive in glb.doc["meshes"][node["mesh"]]["primitives"]:
            attributes = primitive["attributes"]
            positions, ids, weights = [glb.accessor(attributes[name]) for name in
                                      ("POSITION", "JOINTS_0", "WEIGHTS_0")]
            for point, joint_ids, influence_weights in zip(positions, ids, weights):
                vertices.append((point, [(joint, weight) for joint, weight in zip(joint_ids, influence_weights)
                                        if weight > 0]))
                originals.append(transform(rest_world[node_index], point))

    def deform(vertex, matrices):
        point, influences = vertex
        x = y = z = 0.0
        for joint, weight in influences:
            px, py, pz = transform(matrices[joint], point)
            x += weight*px
            y += weight*py
            z += weight*pz
        return x, y, z

    bind_error = max(math.dist(deform(vertex, rest_skin), original)
                     for vertex, original in zip(vertices, originals))
    require(bind_error < 1e-4, f"Bind pose does not reconstruct authored geometry: {bind_error:.6g}")
    minimum = [min(p[i] for p in originals) for i in range(3)]
    maximum = [max(p[i] for p in originals) for i in range(3)]
    diagonal = math.dist(minimum, maximum)
    require(diagonal > 1e-5, "Degenerate mascot bounds")
    center = [(a+b)*.5 for a, b in zip(minimum, maximum)]
    limit = distance_ratio*diagonal
    # Irregular times avoid only hitting neutral points of periodic animations.
    normalized_times = sorted(set([i/(samples-1) for i in range(samples)] + [.137, .371, .613, .887]))
    report.update({"bones": len(joints), "maximumBindPoseError": bind_error,
                   "restBounds": {"min": minimum, "max": maximum},
                   "normalizedSampleTimes": normalized_times, "maximumAllowedRadius": limit,
                   "animations": []})
    for animation in animations:
        tracks = animation_tracks(glb, animation)
        start = min(track[0][0] for _, _, track in tracks)
        end = max(track[0][-1] for _, _, track in tracks)
        low, high = [math.inf]*3, [-math.inf]*3
        radius, displacement = 0.0, 0.0
        for normalized in normalized_times:
            time = start + normalized*(end-start)
            world = world_matrices(nodes, parents, tracks, time)
            matrices = [multiply(world[joint], bind) for joint, bind in zip(joints, inverse)]
            for index, (vertex, original) in enumerate(zip(vertices, originals)):
                point = deform(vertex, matrices)
                require(all(math.isfinite(v) for v in point),
                        f"{animation['name']} at {time:.4f}s: non-finite vertex {index}")
                distance = math.dist(point, center)
                require(distance <= limit,
                        f"{animation['name']} at {time:.4f}s: exploding vertex {index}, radius {distance:.4f}")
                radius = max(radius, distance)
                displacement = max(displacement, math.dist(point, original))
                for axis in range(3):
                    low[axis], high[axis] = min(low[axis], point[axis]), max(high[axis], point[axis])
        report["animations"].append({"name": animation["name"], "channels": len(tracks),
                                     "duration": end-start, "bounds": {"min": low, "max": high},
                                     "maximumRadius": radius, "maximumDisplacement": displacement})
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("asset", nargs="?", type=Path, default=ROOT / "build/legacy_character/glow_procedural.glb")
    parser.add_argument("--reference", type=Path, help="Additionally preserve all named animation target channels")
    parser.add_argument("--samples", type=int, default=9, help="Regular samples per clip (minimum 5), plus four irregular times")
    parser.add_argument("--max-distance-ratio", type=float, default=2,
                        help="Maximum vertex distance from rest center / rest bounding-box diagonal")
    args = parser.parse_args()
    report = {"asset": str(args.asset.resolve()), "passed": False}
    try:
        require(args.samples >= 5, "Use at least five samples per clip")
        require(math.isfinite(args.max_distance_ratio) and args.max_distance_ratio > 0,
                "Distance ratio must be finite and positive")
        report.update(check(Glb(args.asset), args.samples, args.max_distance_ratio,
                            Glb(args.reference) if args.reference else None))
        report["passed"] = True
    except (ValueError, KeyError, IndexError, OSError, struct.error, TypeError) as error:
        report["error"] = str(error)
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
