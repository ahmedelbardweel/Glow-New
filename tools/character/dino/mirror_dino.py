"""Make the dinosaur symmetric from its +x half.

The sculpt's +x arm is raised clear of the body while the -x arm is fused to
the flank along its length. Mirroring the +x half gives two free arms. The
lightning badge sits on the +x belly only, so its mirrored copy is flattened
into the belly and textured from the discarded -x belly.

Run from tools/character:
    python dino/mirror_dino.py dino/dino_green.glb dino/dino_mirror.glb
"""
from __future__ import annotations

import colorsys
import io
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from pygltflib import GLTF2
from scipy.sparse import coo_matrix
from scipy.spatial import cKDTree

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rig_port_frontal import read_accessor  # noqa: E402
from decimate_dino import write_glb  # noqa: E402

PLANE_X = -.062


def base_color(gltf):
    index = gltf.textures[gltf.materials[0].pbrMetallicRoughness.baseColorTexture.index].source
    view = gltf.bufferViews[gltf.images[index].bufferView]
    data = gltf.binary_blob()[view.byteOffset:view.byteOffset+view.byteLength]
    return np.asarray(Image.open(io.BytesIO(data)).convert('RGB'), np.float32)/255


def adjacency(count, faces):
    e = np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    a = coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), shape=(count, count)).tocsr()
    a.data[:] = 1
    return a


def vertex_normals(points, faces):
    n = np.zeros_like(points)
    face = np.cross(points[faces[:, 1]]-points[faces[:, 0]], points[faces[:, 2]]-points[faces[:, 0]])
    for k in range(3):
        np.add.at(n, faces[:, k], face)
    return n/np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def main(source, output):
    gltf = GLTF2().load_binary(source)
    prim = gltf.meshes[0].primitives[0]
    P = read_accessor(gltf, prim.attributes.POSITION).astype(np.float64)
    N = read_accessor(gltf, prim.attributes.NORMAL).astype(np.float64)
    U = read_accessor(gltf, prim.attributes.TEXCOORD_0).astype(np.float64)
    T = read_accessor(gltf, prim.indices).reshape(-1, 3).astype(np.int64)
    _, weld = np.unique(np.round(P/2e-5).astype(np.int64), axis=0, return_inverse=True)
    weld = weld.reshape(-1)

    keep = P[T].mean(axis=1)[:, 0] >= PLANE_X
    half = T[keep]
    # Cut boundary: welded edges used by exactly one kept triangle.
    w = weld[half]
    edges = np.sort(np.concatenate([w[:, [0, 1]], w[:, [1, 2]], w[:, [2, 0]]]), axis=1)
    uniq, counts = np.unique(edges, axis=0, return_counts=True)
    open_ids = np.unique(uniq[counts == 1])
    seam = np.isin(weld, open_ids) & (np.abs(P[:, 0]-PLANE_X) < .02)
    used = np.unique(half)
    remap = -np.ones(len(P), np.int64)
    remap[used] = np.arange(len(used))
    p, n, u, seam = P[used].copy(), N[used].copy(), U[used], seam[used]
    p[seam, 0] = PLANE_X
    n[seam, 0] = 0
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    f = remap[half]

    q = p.copy()
    q[:, 0] = 2*PLANE_X-p[:, 0]
    m = n*np.array([-1, 1, 1])
    uq = u.copy()

    # Badge texels are saturated orange; the belly is pale cream.
    tex = base_color(gltf)
    h, wd = tex.shape[:2]
    rgb = tex[np.clip(((u[:, 1] % 1)*h).astype(int), 0, h-1), np.clip(((u[:, 0] % 1)*wd).astype(int), 0, wd-1)]
    hsv = np.array([colorsys.rgb_to_hsv(*c) for c in rgb])
    badge = ((hsv[:, 0] > .04) & (hsv[:, 0] < .16) & (hsv[:, 1] > .45) & (hsv[:, 2] > .45)
             & (p[:, 2] > .1) & (p[:, 1] > .26) & (p[:, 1] < .52))
    _, wl = np.unique(np.round(q/2e-5).astype(np.int64), axis=0, return_inverse=True)
    wl = wl.reshape(-1)
    count = wl.max()+1
    graph = adjacency(count, wl[f])
    free = np.zeros(count, bool)
    free[wl[badge]] = True
    for _ in range(2):
        free |= (graph @ free.astype(float)) > 0
    pos = np.zeros((count, 3))
    pos[wl] = q
    deg = np.asarray(graph.sum(1)).ravel()
    for _ in range(400):
        pos[free] = (graph @ pos)[free]/deg[free, None]
    moved = free[wl]
    q[moved] = pos[wl][moved]
    # Mirroring flips handedness, so the kept winding faces inward here.
    m[moved] = -vertex_normals(pos, wl[f])[wl][moved]
    # The patch gets its own vertex copies sampling one belly texel, so no
    # triangle interpolates across the badge's atlas island.
    patch = moved[f].any(axis=1)
    ring = np.unique(f[patch])
    ring_outside = ring[~moved[ring]]
    centre = q[moved].mean(axis=0)
    cream = uq[ring_outside[np.argmin(np.linalg.norm(q[ring_outside]-centre, axis=1))]]
    copy = -np.ones(len(q), np.int64)
    copy[ring] = len(q)+np.arange(len(ring))
    q = np.concatenate([q, q[ring]])
    m = np.concatenate([m, m[ring]])
    uq = np.concatenate([uq, np.repeat(cream[None], len(ring), 0)])
    mirrored_faces = f.copy()
    mirrored_faces[patch] = copy[f[patch]]
    print('badge vertices', int(badge.sum()), 'flattened', int(moved.sum()), 'seam', int(seam.sum()))

    positions = np.concatenate([p, q]).astype(np.float32)
    normals = np.concatenate([n, m]).astype(np.float32)
    uvs = np.concatenate([u, uq]).astype(np.float32)
    faces = np.concatenate([f, mirrored_faces[:, [0, 2, 1]]+len(p)]).astype(np.uint32)
    write_glb(gltf, output, positions, normals, uvs, faces)
    print(len(faces), 'triangles', len(positions), 'vertices', f'{Path(output).stat().st_size/1e6:.1f} MB')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
