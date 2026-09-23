"""Rig the supplied ``port_frontal.glb`` without changing its visual design.

The source mesh is a static, mesh-quantized GLB. The build decodes its original
attributes, rigs the limbs, and refines the lip crease without altering the
source rest surface. Local facial controls and recessed oral geometry add
expressions while keeping the head, glasses, nose, hat and body fixed.

Run:
    python tools/character/rig_port_frontal.py INPUT.glb OUTPUT.glb
    python tools/character/rig_port_frontal.py INPUT.glb --inspect
"""
from __future__ import annotations

import argparse
import json
import math
import hashlib
from collections import Counter
from pathlib import Path

import numpy as np
from port_rig_weights import ANCHORS, solve_weights, ease
from port_face_rig import FACE_ANCHORS, build_face, expression
from pygltflib import (
    Accessor,
    Animation,
    AnimationChannel,
    AnimationChannelTarget,
    AnimationSampler,
    BufferView,
    GLTF2,
    Node,
    Skin,
    Attributes,
    Material,
    PbrMetallicRoughness,
    Primitive,
)


COMPONENT_DTYPES = {
    5120: np.dtype("i1"),
    5121: np.dtype("u1"),
    5122: np.dtype("<i2"),
    5123: np.dtype("<u2"),
    5125: np.dtype("<u4"),
    5126: np.dtype("<f4"),
}
TYPE_WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
SOURCE_SHA256 = '5b316a34733e59fa7206568e0173745e6e310aab5053c156c8fbb7400fb71a84'


def quat(x: float = 0.0, y: float = 0.0, z: float = 0.0) -> tuple[float, float, float, float]:
    sx, sy, sz = math.sin(x/2), math.sin(y/2), math.sin(z/2)
    cx, cy, cz = math.cos(x/2), math.cos(y/2), math.cos(z/2)
    return (
        sx*cy*cz+cx*sy*sz,
        cx*sy*cz-sx*cy*sz,
        cx*cy*sz+sx*sy*cz,
        cx*cy*cz-sx*sy*sz,
    )


def read_accessor(gltf: GLTF2, index: int) -> np.ndarray:
    """Read an accessor, expanding glTF normalized integer attributes."""
    accessor = gltf.accessors[index]
    if accessor.bufferView is None:
        raise ValueError(f"Accessor {index} has no buffer view.")
    view = gltf.bufferViews[accessor.bufferView]
    dtype = COMPONENT_DTYPES[accessor.componentType]
    columns = TYPE_WIDTHS[accessor.type]
    item_size = dtype.itemsize
    stride = view.byteStride or columns*item_size
    offset = (view.byteOffset or 0)+(accessor.byteOffset or 0)
    result = np.ndarray(
        (accessor.count, columns), dtype=dtype, buffer=gltf.binary_blob(),
        offset=offset, strides=(stride, item_size),
    ).copy()
    if accessor.normalized:
        if dtype.kind == "u":
            result = result.astype(np.float32)/np.iinfo(dtype).max
        elif dtype.kind == "i":
            result = np.maximum(
                result.astype(np.float32)/np.iinfo(dtype).max, -1.0,
            )
    return result


def append_bytes(gltf: GLTF2, binary: bytearray, payload: bytes, target: int | None = None) -> int:
    while len(binary) % 4:
        binary.append(0)
    offset = len(binary)
    binary.extend(payload)
    gltf.bufferViews.append(BufferView(
        buffer=0, byteOffset=offset, byteLength=len(payload), target=target,
    ))
    return len(gltf.bufferViews)-1


def append_accessor(
    gltf: GLTF2,
    binary: bytearray,
    values: np.ndarray,
    component_type: int,
    kind: str,
    *,
    target: int | None = None,
    bounds: bool = False,
) -> int:
    values = np.ascontiguousarray(values)
    view = append_bytes(gltf, binary, values.tobytes(), target)
    accessor = Accessor(
        bufferView=view,
        byteOffset=0,
        componentType=component_type,
        count=len(values),
        type=kind,
    )
    if bounds:
        rows = values.reshape(-1, 1) if kind == "SCALAR" else values
        accessor.min = [float(value) for value in rows.min(axis=0)]
        accessor.max = [float(value) for value in rows.max(axis=0)]
    gltf.accessors.append(accessor)
    return len(gltf.accessors)-1


def components(indices: np.ndarray, vertex_count: int) -> tuple[np.ndarray, list[int]]:
    """Find triangle-connected components without changing the mesh."""
    parent = np.arange(vertex_count, dtype=np.int32)

    def find(value: int) -> int:
        while parent[value] != value:
            parent[value] = parent[parent[value]]
            value = int(parent[value])
        return value

    for first, second, third in indices.reshape(-1, 3):
        first, second, third = int(first), int(second), int(third)
        root_first, root_second, root_third = find(first), find(second), find(third)
        if root_first != root_second:
            parent[root_second] = root_first
        root_first, root_third = find(first), find(third)
        if root_first != root_third:
            parent[root_third] = root_first
    labels = np.array([find(index) for index in range(vertex_count)], dtype=np.int32)
    count_by_label = Counter(labels.tolist())
    return labels, sorted(count_by_label, key=count_by_label.get, reverse=True)


def print_inspection(positions: np.ndarray, indices: np.ndarray) -> None:
    labels, order = components(indices, len(positions))
    report = []
    for label in order[:24]:
        members = positions[labels == label]
        report.append({
            "vertices": int(len(members)),
            "min": [round(float(value), 5) for value in members.min(axis=0)],
            "max": [round(float(value), 5) for value in members.max(axis=0)],
        })
    print(json.dumps({
        "components": len(order),
        "bounds": {
            "min": [round(float(value), 5) for value in positions.min(axis=0)],
            "max": [round(float(value), 5) for value in positions.max(axis=0)],
        },
        "largestComponents": report,
    }, indent=2))


def prune_quantized_source_attributes(gltf: GLTF2) -> None:
    """Drop source packed attributes after their portable replacements exist."""
    references=[]
    for primitive in gltf.meshes[0].primitives:
        references.append((primitive,'indices'))
        for field in ('POSITION','NORMAL','TANGENT','TEXCOORD_0','JOINTS_0','WEIGHTS_0','_GLOW_SKIN_REGION'):
            if getattr(primitive.attributes,field,None) is not None:
                references.append((primitive.attributes,field))
    for skin in gltf.skins:
        references.append((skin,'inverseBindMatrices'))
    for animation in gltf.animations:
        for sampler in animation.samplers:
            references.extend(((sampler,'input'),(sampler,'output')))
    used=sorted({getattr(obj,key) for obj,key in references})
    remap={old:new for new,old in enumerate(used)}
    for obj,key in references:
        setattr(obj,key,remap[getattr(obj,key)])
    gltf.accessors=[gltf.accessors[index] for index in used]
    views=sorted({a.bufferView for a in gltf.accessors}|{im.bufferView for im in gltf.images})
    remap={old:new for new,old in enumerate(views)}
    for obj in [*gltf.accessors,*gltf.images]:
        obj.bufferView=remap[obj.bufferView]
    gltf.bufferViews=[gltf.bufferViews[index] for index in views]


def make_skeleton(gltf: GLTF2, layout: dict[str, tuple[float, float, float]]) -> dict[str, int]:
    """Append limb and mouth bones under the original scene root."""
    mesh_node = gltf.nodes[0]
    parents = {
        "Root": None,
        "Hips": "Root",
        "Spine": "Hips",
        "Chest": "Spine",
        "LeftUpperArm": "Chest",
        "LeftForeArm": "LeftUpperArm",
        "LeftHand": "LeftForeArm",
        "RightUpperArm": "Chest",
        "RightForeArm": "RightUpperArm",
        "RightHand": "RightForeArm",
        "LeftUpperLeg": "Hips",
        "LeftLowerLeg": "LeftUpperLeg",
        "LeftFoot": "LeftLowerLeg",
        "RightUpperLeg": "Hips",
        "RightLowerLeg": "RightUpperLeg",
        "RightFoot": "RightLowerLeg",
        "Jaw": "Root",
        "MouthCornerLeft": "Root",
        "MouthCornerRight": "Root",
    }
    indices: dict[str, int] = {}
    for name, parent in parents.items():
        position = np.array(layout[name], dtype=np.float32)
        local = position if parent is None else position-np.array(layout[parent], dtype=np.float32)
        indices[name] = len(gltf.nodes)
        gltf.nodes.append(Node(name=name, translation=local.tolist(), children=[]))
        if parent is not None:
            gltf.nodes[indices[parent]].children.append(indices[name])
    mesh_node.children = list(mesh_node.children or [])+[indices["Root"]]
    return indices


def append_animation(
    gltf: GLTF2,
    binary: bytearray,
    name: str,
    duration: float,
    tracks: dict[str, list[tuple[float, float, float]]],
    bones: dict[str, int],
) -> None:
    """Write looping limb rotations and localized mouth expression channels."""
    frames = max(3, int(round(duration*20))+1)
    times = np.linspace(0.0, duration, frames, dtype=np.float32)
    time_accessor = append_accessor(gltf, binary, times, 5126, "SCALAR", bounds=True)
    animation = Animation(name=name, channels=[], samplers=[])
    # Every clip resets every limb, so crossfading cannot leave the previous
    # gesture on a bone that the next clip does not otherwise animate.
    tracks = {bone: tracks.get(bone, [(0.0, 0.0, 0.0)]*frames)
              for bone in list(ANCHORS)[4:]}
    for bone, eulers in tracks.items():
        if len(eulers) != frames:
            raise ValueError(f"{name}/{bone} has {len(eulers)} frames; expected {frames}.")
        rotations = np.array([quat(*angles) for angles in eulers], dtype=np.float32)
        # Keep neighbouring keys in the same quaternion hemisphere.
        for index in range(1, len(rotations)):
            if float(np.dot(rotations[index-1], rotations[index])) < 0:
                rotations[index] *= -1
        output = append_accessor(gltf, binary, rotations, 5126, "VEC4")
        animation.channels.append(AnimationChannel(
            sampler=len(animation.samplers),
            target=AnimationChannelTarget(node=bones[bone], path="rotation"),
        ))
        animation.samplers.append(AnimationSampler(
            input=time_accessor, output=output, interpolation="LINEAR",
        ))
    face_keys=[expression(name, index/(frames-1)) for index in range(frames)]
    for column,(bone,path) in enumerate((('Jaw','rotation'),('MouthCornerLeft','translation'),('MouthCornerRight','translation'))):
        if path=='rotation':
            values=np.array([quat(*key[column]) for key in face_keys],dtype=np.float32)
            kind='VEC4'
        else:
            values=np.array([np.array(FACE_ANCHORS[bone])+key[column] for key in face_keys],dtype=np.float32)
            kind='VEC3'
        output=append_accessor(gltf,binary,values,5126,kind)
        animation.channels.append(AnimationChannel(sampler=len(animation.samplers),
            target=AnimationChannelTarget(node=bones[bone],path=path)))
        animation.samplers.append(AnimationSampler(input=time_accessor,output=output,interpolation='LINEAR'))
    animation.extras = {"loop": True, "localizedMouth": True, "durationSeconds": duration}
    gltf.animations.append(animation)


def frames(duration: float, fn) -> list[tuple[float, float, float]]:
    count = max(3, int(round(duration*20))+1)
    return [fn(index/(count-1)) for index in range(count)]


def build_story_animations(gltf: GLTF2, binary: bytearray, bones: dict[str, int]) -> None:
    """Create app motion clips plus explicit Smile and Laugh expressions."""
    sin = math.sin
    tau = math.tau
    still = lambda duration: frames(duration, lambda _u: (0.0, 0.0, 0.0))

    # Root, torso, skull and hat have no animation channels.
    # The supplied mesh is fused along the inner arms, not authored in a
    # separated A-pose. Preserve its topology and use restrained gestures;
    # an overhead wave needs a separate, explicitly retopologized asset.
    append_animation(gltf, binary, "Idle", 4.0, {}, bones)
    append_animation(gltf, binary, "Talk", 2.0, {
        "LeftUpperArm": frames(2.0, lambda u: (-.08+.04*sin(tau*2*u), 0, .12+.045*sin(tau*2*u))),
        "LeftForeArm": frames(2.0, lambda u: (-.09-.04*sin(tau*2*u), 0, .06)),
        "LeftHand": frames(2.0, lambda u: (0, .12*sin(tau*2*u), .05*sin(tau*2*u))),
        "RightUpperArm": still(2.0),
        "RightForeArm": still(2.0),
    }, bones)
    append_animation(gltf, binary, "Wave", 2.4, {
        "LeftUpperArm": frames(2.4, lambda u: (-.12, 0, .22)),
        "LeftForeArm": frames(2.4, lambda u: (-.08, 0, .12+.12*sin(tau*2*u))),
        "LeftHand": frames(2.4, lambda u: (0, .18*sin(tau*2*u), .18*sin(tau*2*u))),
    }, bones)
    append_animation(gltf, binary, "Happy", 2.0, {
        "LeftUpperArm": frames(2.0, lambda u: (-.08, 0, .20+.045*sin(tau*2*u))),
        "RightUpperArm": frames(2.0, lambda u: (-.08, 0, -.20-.045*sin(tau*2*u))),
        "LeftForeArm": frames(2.0, lambda u: (-.05, 0, .06)),
        "RightForeArm": frames(2.0, lambda u: (-.05, 0, -.06)),
        "LeftUpperLeg": frames(2.0, lambda u: (.06*sin(tau*2*u), 0, 0)),
        "RightUpperLeg": frames(2.0, lambda u: (-.06*sin(tau*2*u), 0, 0)),
    }, bones)
    append_animation(gltf, binary, "Sad", 4.0, {
        "LeftUpperArm": frames(4.0, lambda _u: (.07, 0, -.035)),
        "RightUpperArm": frames(4.0, lambda _u: (.07, 0, .035)),
        "LeftForeArm": frames(4.0, lambda _u: (.04, 0, 0)),
        "RightForeArm": frames(4.0, lambda _u: (.04, 0, 0)),
    }, bones)
    append_animation(gltf, binary, "Thinking", 4.0, {
        "LeftUpperArm": frames(4.0, lambda _u: (-.18, 0, .04)),
        "LeftForeArm": frames(4.0, lambda _u: (-.24, .04, .02)),
        "LeftHand": frames(4.0, lambda u: (0, .10+.03*sin(tau*u), .06)),
        "RightUpperArm": frames(4.0, lambda _u: (-.04, 0, -.02)),
    }, bones)
    append_animation(gltf, binary, "Victory", 2.4, {
        "LeftUpperArm": frames(2.4, lambda u: (-.08, 0, .28+.03*sin(tau*2*u))),
        "RightUpperArm": frames(2.4, lambda u: (-.08, 0, -.28-.03*sin(tau*2*u))),
        "LeftForeArm": frames(2.4, lambda _u: (.03, 0, .08)),
        "RightForeArm": frames(2.4, lambda _u: (.03, 0, -.08)),
    }, bones)
    append_animation(gltf, binary, "Walk", 1.2, {
        "LeftUpperLeg": frames(1.2, lambda u: (.34*sin(tau*u), 0, 0)),
        "RightUpperLeg": frames(1.2, lambda u: (-.34*sin(tau*u), 0, 0)),
        "LeftLowerLeg": frames(1.2, lambda u: (.30*max(0, -sin(tau*u)), 0, 0)),
        "RightLowerLeg": frames(1.2, lambda u: (.30*max(0, sin(tau*u)), 0, 0)),
        "LeftFoot": frames(1.2, lambda u: (-.16*sin(tau*u), 0, 0)),
        "RightFoot": frames(1.2, lambda u: (.16*sin(tau*u), 0, 0)),
        "LeftUpperArm": frames(1.2, lambda u: (-.22*sin(tau*u), 0, -.08)),
        "RightUpperArm": frames(1.2, lambda u: (.22*sin(tau*u), 0, .08)),
        "LeftForeArm": frames(1.2, lambda u: (-.10-.05*sin(tau*u), 0, 0)),
        "RightForeArm": frames(1.2, lambda u: (-.10+.05*sin(tau*u), 0, 0)),
    }, bones)
    append_animation(gltf,binary,'Smile',4.0,{},bones)
    append_animation(gltf,binary,'Laugh',2.0,{
        'LeftUpperArm':frames(2.0,lambda u:(-.06,0,.14+.025*sin(tau*2*u))),
        'RightUpperArm':frames(2.0,lambda u:(-.06,0,-.14-.025*sin(tau*2*u))),
    },bones)


def rig(source: Path, destination: Path, inspect_only: bool = False) -> None:
    if not inspect_only and hashlib.sha256(source.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise ValueError('The authored rig requires the exact supplied port_frontal source. '
                         'A different mesh needs new anatomical anchors and QA.')
    if not inspect_only and source.resolve() == destination.resolve():
        raise ValueError('Export to a different path; the source must stay untouched.')
    gltf = GLTF2().load_binary(str(source))
    if len(gltf.nodes or []) != 1 or len(gltf.meshes or []) != 1:
        raise ValueError("This rigging tool expects the supplied one-node, one-mesh source GLB.")
    primitive = gltf.meshes[0].primitives[0]
    if primitive.attributes.POSITION is None or primitive.indices is None:
        raise ValueError("The source primitive needs POSITION and indices.")
    positions_raw = read_accessor(gltf, primitive.attributes.POSITION).astype(np.float32)
    normals = read_accessor(gltf, primitive.attributes.NORMAL).astype(np.float32)
    uvs = read_accessor(gltf, primitive.attributes.TEXCOORD_0).astype(np.float32)
    indices = read_accessor(gltf, primitive.indices).reshape(-1).astype(np.uint32)
    source_node = gltf.nodes[0]
    scale = np.array(source_node.scale or [1, 1, 1], dtype=np.float64)
    translation = np.array(source_node.translation or [0, 0, 0], dtype=np.float64)
    # The source uses a uniform node scale as its KHR_mesh_quantization decode.
    # Baking that transform into float positions produces the same visual mesh
    # in renderers that do not implement the optional extension.
    positions = (positions_raw*scale+translation).astype(np.float32)
    if inspect_only:
        print_inspection(positions, indices)
        return

    binary = bytearray(gltf.binary_blob())
    joints, weights, weight_report = solve_weights(positions, indices)
    face=build_face(positions,normals,uvs,indices,joints,weights)
    positions,normals,uvs=(face[key] for key in ('positions','normals','uvs'))
    joints,weights=face['joints'],face['weights']
    primitive.indices=append_accessor(gltf,binary,face['indices'].reshape(-1),5123,'SCALAR',target=34963)
    position_accessor = append_accessor(gltf, binary, positions, 5126, "VEC3", target=34962, bounds=True)
    normal_accessor = append_accessor(gltf, binary, normals, 5126, "VEC3", target=34962)
    uv_accessor = append_accessor(gltf, binary, uvs, 5126, "VEC2", target=34962)
    # Keep the source's tangent-free normal mapping. Introducing approximate
    # tangents here would change the appearance of the unchanged normal map.
    joints_accessor = append_accessor(gltf, binary, joints, 5123, "VEC4", target=34962)
    weights_accessor = append_accessor(gltf, binary, weights, 5126, "VEC4", target=34962)
    primitive.attributes.POSITION = position_accessor
    primitive.attributes.NORMAL = normal_accessor
    primitive.attributes.TEXCOORD_0 = uv_accessor
    primitive.attributes.JOINTS_0 = joints_accessor
    primitive.attributes.WEIGHTS_0 = weights_accessor
    # Semantic protection for eyes/lenses; per-fragment green chroma then
    # isolates skin from the original cream, metal, hat and badge texels.
    eye_distance=((np.abs(positions[:,0])-.106)/.047)**2+((positions[:,1]-.606)/.057)**2
    eye_protection=(1-ease(.85,1.18,eye_distance))*ease(.160,.205,positions[:,2])
    skin_region=(1-eye_protection).astype(np.float32)
    setattr(primitive.attributes,'_GLOW_SKIN_REGION',
        append_accessor(gltf,binary,skin_region,5126,'SCALAR',target=34962))

    source_node.name = "GlowCharacter"
    source_node.translation = None
    source_node.rotation = None
    source_node.scale = None
    layout = {**ANCHORS,**FACE_ANCHORS}
    bones = make_skeleton(gltf, layout)
    inverse_binds = []
    # All bind-pose bones have identity rotation.  Their global translation is
    # therefore the only inverse-bind term required by the limb-only rig.
    for name in bones:
        x, y, z = layout[name]
        inverse_binds.append((1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -x, -y, -z, 1))
    inverse_accessor = append_accessor(
        gltf, binary, np.array(inverse_binds, dtype=np.float32), 5126, "MAT4",
    )
    gltf.skins = list(gltf.skins or [])+[Skin(
        name="PortFrontalRig",
        skeleton=bones["Root"],
        joints=[bones[name] for name in bones],
        inverseBindMatrices=inverse_accessor,
    )]
    source_node.skin = len(gltf.skins)-1
    for part in face['interior']:
        attrs=Attributes(
            POSITION=append_accessor(gltf,binary,part['positions'],5126,'VEC3',target=34962,bounds=True),
            NORMAL=append_accessor(gltf,binary,part['normals'],5126,'VEC3',target=34962),
            JOINTS_0=append_accessor(gltf,binary,part['joints'],5123,'VEC4',target=34962),
            WEIGHTS_0=append_accessor(gltf,binary,part['weights'],5126,'VEC4',target=34962))
        material=len(gltf.materials)
        gltf.materials.append(Material(name=part['name'],doubleSided=True,
            pbrMetallicRoughness=PbrMetallicRoughness(baseColorFactor=part['color'],metallicFactor=0.,roughnessFactor=.85)))
        gltf.meshes[0].primitives.append(Primitive(attributes=attrs,material=material,
            indices=append_accessor(gltf,binary,part['indices'].reshape(-1),5123,'SCALAR',target=34963)))
    gltf.animations = []
    build_story_animations(gltf, binary, bones)
    prune_quantized_source_attributes(gltf)

    extensions_used = [name for name in (gltf.extensionsUsed or []) if name != "KHR_mesh_quantization"]
    extensions_required = [name for name in (gltf.extensionsRequired or []) if name != "KHR_mesh_quantization"]
    # pygltflib's GLB writer expects iterable extension lists even when the
    # source mesh no longer requires its quantization extension.
    gltf.extensionsUsed = extensions_used
    gltf.extensionsRequired = extensions_required
    gltf.buffers[0].byteLength = len(binary)
    gltf.set_binary_blob(bytes(binary))
    gltf.extras = {
        "character": "Glow supplied port_frontal mascot",
        "rig": "limbs-and-local-mouth",
        "source": source.name,
        "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "rigVersion": 3,
        "skinPalette": "localized-green-chroma-v1",
        "preserved": ["source-rest-surface", "source-textures", "source-material", "source-UVs", "hat", "glasses", "nose", "torso"],
        "animated": ["arms", "legs", "lips", "jaw"],
        "mouth": {key:face[key] for key in ('sourceVertexCount','surfaceVertexSources','addedTriangleSource','lipUpperIndices','lipLowerIndices','lipPathPositions','faceVertices')},
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    gltf.save_binary(str(destination))
    print(json.dumps({
        "output": str(destination),
        "vertices": int(len(positions)),
        "sourceTriangles": int(len(indices)//3),
        "surfaceTriangles": int(len(face['indices'])),
        "interiorTriangles": int(sum(len(part['indices']) for part in face['interior'])),
        "bones": len(bones),
        "animations": [animation.name for animation in gltf.animations],
        "animatedVertices": int(np.any((joints != 0) & (weights > 0), axis=1).sum()),
        "weights": weight_report,
        "bytes": destination.stat().st_size,
    }, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path, nargs="?")
    parser.add_argument("--inspect", action="store_true")
    args = parser.parse_args()
    if not args.inspect and args.destination is None:
        parser.error("destination is required unless --inspect is used")
    rig(args.source, args.destination or Path("unused.glb"), args.inspect)


if __name__ == "__main__":
    main()
