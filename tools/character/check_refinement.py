"""Check geometry refinements of the legacy procedural mascot.

For the active supplied character use check_port_rig.py instead.

Uses only Python's standard library. Run from any directory; optional positional
arguments select the original and refined GLB files, respectively.
"""
from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
COMPONENTS = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
              5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4,
          "MAT2": 4, "MAT3": 9, "MAT4": 16}


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Glb:
    def __init__(self, path):
        self.path = path
        raw = path.read_bytes()
        require(len(raw) >= 12, "Truncated GLB header")
        magic, version, size = struct.unpack_from("<III", raw)
        require(magic == 0x46546C67 and version == 2, "Expected a glTF 2 GLB")
        require(size == len(raw), "GLB length differs from its header")
        chunks = {}
        offset = 12
        while offset < size:
            require(offset + 8 <= size, "Truncated GLB chunk header")
            length, kind = struct.unpack_from("<II", raw, offset)
            offset += 8
            require(offset + length <= size, "Truncated GLB chunk")
            require(kind not in chunks, "Duplicate GLB chunk")
            chunks[kind] = raw[offset:offset + length]
            offset += length
        require(0x4E4F534A in chunks and 0x004E4942 in chunks,
                "Expected JSON and embedded binary chunks")
        self.doc = json.loads(chunks[0x4E4F534A])
        self.binary = chunks[0x004E4942]
        self.bytes = size

    def accessor(self, index):
        accessor = self.doc["accessors"][index]
        require("sparse" not in accessor, "Sparse accessors are not supported by this checker")
        view = self.doc["bufferViews"][accessor["bufferView"]]
        require(view.get("buffer", 0) == 0, "Expected embedded buffer 0")
        kind = accessor["type"]
        component = accessor["componentType"]
        code, size = COMPONENTS[component]
        width = WIDTHS[kind]
        require(not kind.startswith("MAT") or component == 5126,
                "Only float matrix accessors are supported")
        item_size = width * size
        stride = view.get("byteStride", item_size)
        require(stride >= item_size, "Accessor stride is shorter than its element")
        local_offset = accessor.get("byteOffset", 0)
        offset = view.get("byteOffset", 0) + local_offset
        count = accessor["count"]
        end = local_offset + ((count - 1) * stride + item_size if count else 0)
        require(end <= view["byteLength"], "Accessor exceeds its buffer view")
        require(view.get("byteOffset", 0) + view["byteLength"] <= len(self.binary),
                "Buffer view exceeds binary chunk")
        rows = [struct.unpack_from("<" + code * width, self.binary, offset + i * stride)
                for i in range(count)]
        if accessor.get("normalized"):
            divisors = {5120: 127, 5121: 255, 5122: 32767, 5123: 65535}
            require(component in divisors, "Unsupported normalized component type")
            divisor = divisors[component]
            rows = [tuple(max(-1, value / divisor) for value in row) for row in rows]
        return rows

    def animation_contract(self):
        contracts = []
        for animation in self.doc.get("animations", []):
            contract = {key: value for key, value in animation.items() if key != "samplers"}
            contract["samplers"] = []
            for sampler in animation["samplers"]:
                data = {key: value for key, value in sampler.items()
                        if key not in ("input", "output")}
                for key in ("input", "output"):
                    accessor = self.doc["accessors"][sampler[key]]
                    data[key] = {"type": accessor["type"],
                                 "componentType": accessor["componentType"],
                                 "values": self.accessor(sampler[key])}
                contract["samplers"].append(data)
            contracts.append(contract)
        return contracts


def preservation(before, after):
    require(before.doc["nodes"] == after.doc["nodes"],
            "Scene nodes, bone bind transforms, or parent/child links changed")
    require(before.doc.get("scene") == after.doc.get("scene") and
            before.doc["scenes"] == after.doc["scenes"], "Scene roots changed")
    require(before.doc["materials"] == after.doc["materials"], "Material definitions changed")
    old_skins, new_skins = before.doc["skins"], after.doc["skins"]
    require(len(old_skins) == len(new_skins), "Skin count changed")
    bone_names = []
    for index, (old, new) in enumerate(zip(old_skins, new_skins)):
        require({k: v for k, v in old.items() if k != "inverseBindMatrices"} ==
                {k: v for k, v in new.items() if k != "inverseBindMatrices"},
                f"Skin {index} joint order or skeleton changed")
        names = [after.doc["nodes"][node]["name"] for node in new["joints"]]
        require(names == [before.doc["nodes"][node]["name"] for node in old["joints"]],
                f"Skin {index} ordered bone names changed")
        require(before.accessor(old["inverseBindMatrices"]) ==
                after.accessor(new["inverseBindMatrices"]),
                f"Skin {index} inverse bind matrix data changed")
        bone_names.extend(names)
    old_animations, new_animations = before.animation_contract(), after.animation_contract()
    require(len(old_animations) == len(new_animations), "Animation count changed")
    for index, (old, new) in enumerate(zip(old_animations, new_animations)):
        require(old == new, f"Animation {index} ({old.get('name')}) changed: "
                "name, targets, timing, interpolation, metadata, or sampled output")
    return {"bones": len(bone_names), "orderedBoneNames": bone_names,
            "materials": len(after.doc["materials"]),
            "animations": [animation.get("name") for animation in new_animations],
            "checks": ["exact scene nodes and bind transforms", "ordered skin joints",
                       "inverse bind matrix data", "material definitions",
                       "animation targets, timing and every sampled output"]}


def geometry(glb):
    stats = {"bytes": glb.bytes, "meshes": len(glb.doc["meshes"]),
             "primitives": 0, "vertices": 0, "triangles": 0,
             "maximumInfluences": 0, "maximumWeightSumError": 0.0,
             "maximumNormalLengthError": 0.0}
    for node in glb.doc["nodes"]:
        if "mesh" not in node:
            continue
        require("skin" in node, "Expected every mascot mesh to be skinned")
        joints = len(glb.doc["skins"][node["skin"]]["joints"])
        for primitive in glb.doc["meshes"][node["mesh"]]["primitives"]:
            label = f"Primitive {stats['primitives']}"
            require(primitive.get("mode", 4) == 4, f"{label}: expected triangles")
            attributes = primitive["attributes"]
            expected = {"POSITION": "VEC3", "NORMAL": "VEC3",
                        "JOINTS_0": "VEC4", "WEIGHTS_0": "VEC4"}
            values = {}
            for name, kind in expected.items():
                require(name in attributes, f"{label}: missing {name}")
                require(glb.doc["accessors"][attributes[name]]["type"] == kind,
                        f"{label}: incorrect {name} accessor type")
                values[name] = glb.accessor(attributes[name])
            require(not any(name.startswith(("JOINTS_", "WEIGHTS_")) and
                            name not in ("JOINTS_0", "WEIGHTS_0") for name in attributes),
                    f"{label}: more than four skin influence slots")
            count = len(values["POSITION"])
            require(all(len(rows) == count for rows in values.values()),
                    f"{label}: unequal vertex attribute counts")
            for vertex, (position, normal, joint_ids, weights) in enumerate(zip(
                    values["POSITION"], values["NORMAL"], values["JOINTS_0"], values["WEIGHTS_0"])):
                require(all(math.isfinite(value) for value in position + normal + weights),
                        f"{label} vertex {vertex}: non-finite geometry")
                normal_error = abs(math.sqrt(sum(value * value for value in normal)) - 1)
                require(normal_error <= 1e-4, f"{label} vertex {vertex}: non-unit normal")
                require(all(0 <= weight <= 1 for weight in weights),
                        f"{label} vertex {vertex}: weight outside [0, 1]")
                weight_error = abs(sum(weights) - 1)
                require(weight_error <= 1e-5, f"{label} vertex {vertex}: weights do not sum to 1")
                active = [joint for joint, weight in zip(joint_ids, weights) if weight > 0]
                require(1 <= len(active) <= 4 and len(set(active)) == len(active),
                        f"{label} vertex {vertex}: invalid or duplicate skin influences")
                require(all(isinstance(joint, int) and 0 <= joint < joints for joint in joint_ids),
                        f"{label} vertex {vertex}: joint index outside skin")
                stats["maximumInfluences"] = max(stats["maximumInfluences"], len(active))
                stats["maximumWeightSumError"] = max(stats["maximumWeightSumError"], weight_error)
                stats["maximumNormalLengthError"] = max(stats["maximumNormalLengthError"], normal_error)
            indices = glb.accessor(primitive["indices"])
            require(len(indices) % 3 == 0, f"{label}: incomplete triangle")
            require(all(len(row) == 1 and isinstance(row[0], int) and 0 <= row[0] < count
                        for row in indices), f"{label}: index outside vertex buffer")
            stats["primitives"] += 1
            stats["vertices"] += count
            stats["triangles"] += len(indices) // 3
    require(stats["vertices"] > 0, "No skinned geometry found")
    return stats


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", nargs="?", type=Path,
                        default=ROOT / "build/character_refinement/glow_mascot_before.glb")
    parser.add_argument("after", nargs="?", type=Path,
                        default=ROOT / "build/legacy_character/glow_procedural.glb")
    args = parser.parse_args()
    report = {"before": str(args.before.resolve()), "after": str(args.after.resolve())}
    try:
        before, after = Glb(args.before), Glb(args.after)
        report["preserved"] = preservation(before, after)
        report["beforeGeometry"] = geometry(before)
        report["afterGeometry"] = geometry(after)
        report["passed"] = True
    except (ValueError, KeyError, IndexError, OSError, struct.error) as error:
        report["passed"] = False
        report["error"] = str(error)
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
