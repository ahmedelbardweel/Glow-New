"""Add professional mouth (cavity + tongue) and Jaw bone to glow_mascot.glb.

Creates a complete mouth system:
1. Adds a Jaw bone to the skeleton (child of Chest/Neck/Head if available).
2. Creates mouth cavity geometry (dark red, hugging the face, pushed deep inside).
3. Creates tongue geometry (pink, inside the cavity).
4. Skins both cavity and tongue to the Jaw bone.
5. Re-skins a very thin lower-lip region with minimal weight to avoid face collapse.
6. Adds subtle Jaw rotation keyframes to Talk, Happy, Laugh, Smile animations.
7. Checks if Jaw already exists to avoid corruption.
8. Creates a backup of the original GLB.

Run from project root:
    python tools/character/add_jaw_bone_fixed.py
"""
from __future__ import annotations
import math, shutil, sys
from pathlib import Path
import numpy as np
from pygltflib import (
    GLTF2, Node, AnimationChannel, AnimationChannelTarget, AnimationSampler,
    Accessor, BufferView, Primitive, Attributes, Material, PbrMetallicRoughness,
)

# ── constants ──────────────────────────────────────────────────────────────

BODY_X = -0.062
MOUTH_HALF = 0.103
MOUTH_Y0 = 0.580
JAW_POS = np.array([BODY_X, 0.575, 0.190], dtype=np.float64)

CAVITY_RADII = (0.084, 0.028, 0.008)
CAVITY_CENTER = (BODY_X, 0.562, 0.280)  # Pushed deeper

TONGUE_RADII = (0.040, 0.010, 0.010)
TONGUE_CENTER = (BODY_X, 0.552, 0.288)  # Pushed deeper


# ── helpers ────────────────────────────────────────────────────────────────

def read_acc(gltf: GLTF2, idx: int) -> np.ndarray:
    a = gltf.accessors[idx]
    bv = gltf.bufferViews[a.bufferView]
    blob = gltf.binary_blob()
    dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32}[a.componentType]
    comp = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a.type]
    data = np.frombuffer(blob, dtype=dtype, count=a.count * comp,
                         offset=bv.byteOffset + (a.byteOffset or 0)).copy()
    return data.reshape(a.count, comp) if comp > 1 else data


def append_accessor(gltf, binary, data, comp_type, acc_type, *,
                    target=None, bounds=False):
    raw = data.tobytes()
    while len(binary) % 4:
        binary.append(0)
    offset = len(binary)
    binary.extend(raw)
    bv = BufferView(buffer=0, byteOffset=offset, byteLength=len(raw))
    if target:
        bv.target = target
    gltf.bufferViews.append(bv)
    bv_idx = len(gltf.bufferViews) - 1
    acc = Accessor(bufferView=bv_idx, componentType=comp_type,
                   count=len(data), type=acc_type)
    if bounds and data.ndim == 2:
        acc.max = [float(v) for v in data.max(axis=0)]
        acc.min = [float(v) for v in data.min(axis=0)]
    gltf.accessors.append(acc)
    return len(gltf.accessors) - 1


def make_sphere(radii, center, curvature, n_seg=16, n_ring=12):
    rx, ry, rz = radii
    cx, cy, cz = center
    verts, norms, faces = [], [], []
    for j in range(n_ring + 1):
        phi = math.pi * j / n_ring
        for i in range(n_seg + 1):
            theta = 2 * math.pi * i / n_seg
            x = math.sin(phi) * math.cos(theta)
            y = math.sin(phi) * math.sin(theta)
            z = math.cos(phi)
            px = cx + rx * x
            py = cy + ry * y
            pz = cz + rz * z
            pz -= curvature * (px - cx) ** 2 / (rx * rx) * rz
            verts.append([px, py, pz])
            norms.append([x, y, z])
    verts = np.array(verts, np.float32)
    norms_arr = np.array(norms, np.float32)
    lengths = np.linalg.norm(norms_arr, axis=1, keepdims=True)
    norms_arr = np.where(lengths > 1e-6, norms_arr / lengths, norms_arr)
    for j in range(n_ring):
        for i in range(n_seg):
            a = j * (n_seg + 1) + i
            b = a + 1
            c = a + n_seg + 1
            d = c + 1
            faces.append([a, c, b])
            faces.append([b, c, d])
    return verts, norms_arr, np.array(faces, np.uint32)


# ── main ───────────────────────────────────────────────────────────────────

def main():
    src = Path(__file__).resolve().parents[2] / 'assets' / '3d' / 'glow_mascot.glb'
    
    # ── 0. Backup and load ───────────────────────────────────────────────
    backup = src.with_name('glow_mascot_before_jaw.glb')
    shutil.copy2(src, backup)
    print(f"Backed up to {backup.name}")
    
    gltf = GLTF2().load_binary(str(src))
    binary = bytearray(gltf.binary_blob())

    skin = gltf.skins[0]
    joint_names = [gltf.nodes[j].name for j in skin.joints]
    
    if 'Jaw' in joint_names:
        print("ERROR: 'Jaw' bone already exists! Aborting to prevent corruption.")
        sys.exit(1)

    # ── 1. Add Jaw node ──────────────────────────────────────────────────
    # Find best parent: Head > Neck > Chest > Spine > Root
    parent_candidates = ['Head', 'Neck', 'Chest', 'Spine', 'Root']
    parent_name = next((p for p in parent_candidates if p in joint_names), 'Root')
    parent_bone_idx = joint_names.index(parent_name)
    parent_node_idx = skin.joints[parent_bone_idx]
    
    # Get absolute world position of parent from IBM (Inverse Bind Matrix)
    ibm_data = read_acc(gltf, skin.inverseBindMatrices)
    parent_ibm = ibm_data[parent_bone_idx].reshape(4, 4)
    # IBM translates world to local, so world pos is -IBM translation
    parent_world_pos = -parent_ibm[3, :3]
    
    jaw_local = JAW_POS - parent_world_pos
    jaw_node_idx = len(gltf.nodes)
    gltf.nodes.append(Node(name='Jaw', translation=jaw_local.tolist(), children=[]))
    gltf.nodes[parent_node_idx].children = list(
        gltf.nodes[parent_node_idx].children or []) + [jaw_node_idx]

    skin.joints.append(jaw_node_idx)
    jaw_bone_idx = len(skin.joints) - 1

    # Extend inverseBindMatrices
    jaw_ibm = np.eye(4, dtype=np.float32)
    jaw_ibm[3, :3] = -JAW_POS
    ibm_all = np.vstack([ibm_data, jaw_ibm.T.reshape(1, 16)])
    skin.inverseBindMatrices = append_accessor(
        gltf, binary, ibm_all.astype(np.float32), 5126, 'MAT4')

    print(f"Added Jaw bone at index {jaw_bone_idx} (child of {parent_name})")

    # ── 2. Create mouth cavity and tongue geometry ───────────────────────
    def add_mouth_primitive(pos, norm, tri, color, bone_idx):
        mat_idx = len(gltf.materials)
        gltf.materials.append(Material(
            pbrMetallicRoughness=PbrMetallicRoughness(
                baseColorFactor=color, metallicFactor=0.0, roughnessFactor=0.6)
        ))
        n = len(pos)
        joints = np.zeros((n, 4), np.uint16)
        weights = np.zeros((n, 4), np.float32)
        joints[:, 0] = bone_idx
        weights[:, 0] = 1.0
        uvs = np.zeros((n, 2), np.float32)

        prim = Primitive(
            mode=4,
            material=mat_idx,
            indices=append_accessor(gltf, binary,
                                    tri.reshape(-1).astype(np.uint32),
                                    5125, 'SCALAR', target=34963),
            attributes=Attributes(
                POSITION=append_accessor(gltf, binary, pos.astype(np.float32),
                                         5126, 'VEC3', target=34962, bounds=True),
                NORMAL=append_accessor(gltf, binary, norm.astype(np.float32),
                                       5126, 'VEC3', target=34962),
                TEXCOORD_0=append_accessor(gltf, binary, uvs.astype(np.float32),
                                           5126, 'VEC2', target=34962),
                JOINTS_0=append_accessor(gltf, binary, joints,
                                         5123, 'VEC4', target=34962),
                WEIGHTS_0=append_accessor(gltf, binary, weights,
                                          5126, 'VEC4', target=34962),
            )
        )
        gltf.meshes[0].primitives.append(prim)
        return len(gltf.meshes[0].primitives) - 1

    c_pos, c_norm, c_tri = make_sphere(CAVITY_RADII, CAVITY_CENTER, -0.3)
    pi_cavity = add_mouth_primitive(c_pos, c_norm, c_tri, [0.16, 0.02, 0.04, 1.0], jaw_bone_idx)
    
    t_pos, t_norm, t_tri = make_sphere(TONGUE_RADII, TONGUE_CENTER, 0.1)
    pi_tongue = add_mouth_primitive(t_pos, t_norm, t_tri, [0.77, 0.27, 0.34, 1.0], jaw_bone_idx)

    # ── 3. Blend lower-lip of main body ──────────────────────────────────
    prim0 = gltf.meshes[0].primitives[0]
    pos0 = read_acc(gltf, prim0.attributes.POSITION)
    j0 = read_acc(gltf, prim0.attributes.JOINTS_0).astype(np.uint16)
    w0 = read_acc(gltf, prim0.attributes.WEIGHTS_0).astype(np.float32)

    x, y, z = pos0[:, 0], pos0[:, 1], pos0[:, 2]

    # Extremely conservative blending: very thin band, very low max weight
    u = (x - BODY_X) / MOUTH_HALF
    lip_field = y - (MOUTH_Y0 + 0.039 * u * u)
    in_mouth_x = np.abs(x - BODY_X) < (MOUTH_HALF + 0.02)
    in_front = z > 0.255

    jaw_weight = np.zeros(len(pos0), np.float32)
    thin_band = (lip_field < 0) & (lip_field > -0.005) & in_mouth_x & in_front & (y > 0.56)
    band_depth = np.clip(-lip_field, 0, 0.005) / 0.005
    jaw_raw = (1.0 - band_depth) * 0.045
    jaw_weight[thin_band] = jaw_raw[thin_band]

    affected = jaw_weight > 0.001
    print(f"Body verts with jaw weight: {int(affected.sum())} / {len(pos0)}")

    for vi in np.flatnonzero(affected):
        jw = jaw_weight[vi]
        w0[vi] *= (1.0 - jw)
        min_slot = int(np.argmin(w0[vi]))
        j0[vi, min_slot] = jaw_bone_idx
        w0[vi, min_slot] = jw
        total = w0[vi].sum()
        if total > 0:
            w0[vi] /= total

    prim0.attributes.JOINTS_0 = append_accessor(
        gltf, binary, j0, 5123, 'VEC4', target=34962)
    prim0.attributes.WEIGHTS_0 = append_accessor(
        gltf, binary, w0, 5126, 'VEC4', target=34962)

    # ── 4. Add Jaw animation tracks ──────────────────────────────────────
    sin, tau = math.sin, math.tau

    # Gentler angles to prevent mesh tearing
    jaw_anims = {
        'Talk': (2.0, lambda u: 0.01 + 0.035 * abs(sin(tau * 3 * u))
                 * (0.7 + 0.3 * sin(tau * 7 * u))),
        'Happy': (2.0, lambda u: 0.005 + 0.015 * sin(tau * 2 * u) ** 2),
        'Laugh': (2.0, lambda u: 0.01 + 0.03 * abs(sin(tau * 3.5 * u))),
        'Smile': (4.0, lambda u: 0.005 + 0.002 * sin(tau * u)),
    }

    for anim in gltf.animations:
        if anim.name not in jaw_anims:
            continue
        duration, fn = jaw_anims[anim.name]
        fps = 20
        count = max(3, int(round(duration * fps)) + 1)
        times = np.linspace(0, duration, count, dtype=np.float32)

        quats = np.zeros((count, 4), np.float32)
        for i in range(count):
            u_val = i / (count - 1)
            angle = fn(u_val)
            quats[i] = [math.sin(angle / 2), 0, 0, math.cos(angle / 2)]

        t_acc = append_accessor(gltf, binary, times, 5126, 'SCALAR', bounds=True)
        q_acc = append_accessor(gltf, binary, quats, 5126, 'VEC4')

        anim.channels.append(AnimationChannel(
            sampler=len(anim.samplers),
            target=AnimationChannelTarget(node=jaw_node_idx, path='rotation')))
        anim.samplers.append(AnimationSampler(
            input=t_acc, output=q_acc, interpolation='LINEAR'))

    # ── 5. Save ──────────────────────────────────────────────────────────
    gltf.buffers[0].byteLength = len(binary)
    gltf.set_binary_blob(bytes(binary))
    gltf.save_binary(str(src))
    print(f"Saved {src.name} successfully.")


if __name__ == '__main__':
    main()
