"""Reduce the supplied blue dinosaur GLB to a mobile budget.

Run: python tools/character/dino/decimate_dino.py SOURCE.glb OUT.glb [--faces 80000]

The source is a 2M-triangle scan-density mesh with a many-island texture
atlas. The surface is welded by position and simplified; every reduced
triangle then takes its UVs from one source texture island (the island
under its centroid), so no triangle samples across an atlas seam. The
source images and material are reused unchanged.
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

import fast_simplification
import numpy as np
from pygltflib import GLTF2
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components
from scipy.spatial import cKDTree

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rig_port_frontal import read_accessor  # noqa: E402


def islands(vertex_count, triangles):
    """Connected components of the unwelded mesh: one per texture island."""
    edges = np.concatenate([triangles[:, [0, 1]], triangles[:, [1, 2]]])
    graph = coo_matrix((np.ones(len(edges)), (edges[:, 0], edges[:, 1])), shape=(vertex_count,)*2)
    return connected_components(graph, directed=False)[1]


def reduce(positions, normals, uvs, triangles, faces):
    welded, inverse = np.unique(positions, axis=0, return_inverse=True)
    inverse = inverse.ravel()
    welded_tris = inverse[triangles]
    keep = ((welded_tris[:, 0] != welded_tris[:, 1]) & (welded_tris[:, 1] != welded_tris[:, 2])
            & (welded_tris[:, 0] != welded_tris[:, 2]))
    points, reduced = fast_simplification.simplify(welded.astype(np.float64), welded_tris[keep], target_count=faces)
    chart = islands(len(positions), triangles)
    tree = cKDTree(positions)
    centroid = points[reduced].mean(axis=1)
    owner = chart[tree.query(centroid)[1]]
    # Each corner takes the nearest source vertex of its triangle's island.
    corners = points[reduced.reshape(-1)]
    corner_chart = np.repeat(owner, 3)
    _, candidates = tree.query(corners, k=24)
    match = chart[candidates] == corner_chart[:, None]
    first = np.where(match.any(axis=1), match.argmax(axis=1), 0)
    source = candidates[np.arange(len(corners)), first]
    for i in np.flatnonzero(~match.any(axis=1)):
        members = np.flatnonzero(chart == corner_chart[i])
        source[i] = members[np.argmin(np.linalg.norm(positions[members]-corners[i], axis=1))]
    key = np.stack([reduced.reshape(-1), corner_chart], axis=1)
    unique_key, vertex_of = np.unique(key, axis=0, return_inverse=True)
    vertex_of = vertex_of.ravel()
    first_corner = np.zeros(len(unique_key), np.int64)
    first_corner[vertex_of[::-1]] = np.arange(len(vertex_of))[::-1]
    out_positions = points[unique_key[:, 0]].astype(np.float32)
    out_uvs = uvs[source[first_corner]].astype(np.float32)
    out_normals = normals[source[first_corner]].astype(np.float32)
    return out_positions, out_normals, out_uvs, vertex_of.reshape(-1, 3).astype(np.uint32)


def write_glb(source, path, positions, normals, uvs, triangles):
    """A fresh single-mesh GLB that embeds only the reduced geometry and the source images."""
    blob = bytearray()
    views, accessors = [], []

    def add(data, target=None):
        while len(blob) % 4:
            blob.append(0)
        views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(data), **({"target": target} if target else {})})
        blob.extend(data)
        return len(views)-1

    def accessor(values, component, kind, target):
        view = add(np.ascontiguousarray(values).tobytes(), target)
        entry = {"bufferView": view, "componentType": component, "count": len(values), "type": kind}
        if kind == "VEC3" and target == 34962:
            entry["min"] = values.min(axis=0).tolist()
            entry["max"] = values.max(axis=0).tolist()
        accessors.append(entry)
        return len(accessors)-1

    index_type = (5125, np.uint32) if len(positions) > 65535 else (5123, np.uint16)
    attributes = {"POSITION": accessor(positions, 5126, "VEC3", 34962),
                  "NORMAL": accessor(normals, 5126, "VEC3", 34962),
                  "TEXCOORD_0": accessor(uvs, 5126, "VEC2", 34962)}
    indices = accessor(triangles.reshape(-1).astype(index_type[1]), index_type[0], "SCALAR", 34963)
    source_blob = source.binary_blob()
    images = []
    for image in source.images:
        view = source.bufferViews[image.bufferView]
        images.append({"bufferView": add(source_blob[view.byteOffset:view.byteOffset+view.byteLength]),
                       "mimeType": image.mimeType})
    while len(blob) % 4:
        blob.append(0)
    doc = source.to_dict()
    gltf = {
        "asset": {"version": "2.0", "generator": "glow decimate_dino"},
        "scene": 0, "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "Dinosaur", "mesh": 0}],
        "meshes": [{"name": "Dinosaur", "primitives": [{"attributes": attributes, "indices": indices, "material": 0}]}],
        "materials": doc["materials"], "textures": doc["textures"], "images": images,
        **({"samplers": doc["samplers"]} if doc.get("samplers") else {}),
        "buffers": [{"byteLength": len(blob)}], "bufferViews": views, "accessors": accessors,
    }
    import json
    text = json.dumps(gltf, separators=(",", ":")).encode()
    text += b" "*((4-len(text) % 4) % 4)
    body = struct.pack("<I4s", len(text), b"JSON")+text+struct.pack("<I4s", len(blob), b"BIN\0")+bytes(blob)
    Path(path).write_bytes(struct.pack("<4sII", b"glTF", 2, 12+len(body))+body)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("output")
    parser.add_argument("--faces", type=int, default=80000)
    args = parser.parse_args()
    gltf = GLTF2().load_binary(args.source)
    primitive = gltf.meshes[0].primitives[0]
    offset = np.array(gltf.nodes[0].translation or [0, 0, 0], np.float32)
    positions = read_accessor(gltf, primitive.attributes.POSITION).astype(np.float32)+offset
    normals = read_accessor(gltf, primitive.attributes.NORMAL).astype(np.float32)
    uvs = read_accessor(gltf, primitive.attributes.TEXCOORD_0).astype(np.float32)
    triangles = read_accessor(gltf, primitive.indices).reshape(-1, 3).astype(np.int64)
    result = reduce(positions, normals, uvs, triangles, args.faces)
    write_glb(gltf, args.output, *result)
    print(f"{len(triangles)} -> {len(result[3])} triangles, {len(result[0])} vertices, "
          f"{Path(args.output).stat().st_size/1e6:.1f} MB")


if __name__ == "__main__":
    main()
