"""Recolor the dinosaur's blue skin to Glow's green.

Run: python tools/character/dino/recolor_dino.py IN.glb GLOW.glb OUT.glb

Glow's skin green is measured from its own base color atlas; every blue
texel of the dinosaur maps onto that green, keeping its relative saturation
and brightness so painted shading and the darker brows survive.
"""
from __future__ import annotations

import io
import sys

import numpy as np
from PIL import Image
from pygltflib import GLTF2, BufferView


def image_of(gltf, texture_index):
    image = gltf.images[gltf.textures[texture_index].source]
    view = gltf.bufferViews[image.bufferView]
    data = gltf.binary_blob()[view.byteOffset:view.byteOffset+view.byteLength]
    return image, Image.open(io.BytesIO(data)).convert("RGB")


def hsv(img):
    return np.asarray(img.convert("HSV"), np.float32)/255


def main(source, glow_path, output):
    glow = GLTF2().load_binary(glow_path)
    _, glow_img = image_of(glow, glow.materials[0].pbrMetallicRoughness.baseColorTexture.index)
    rgb = np.asarray(glow_img, np.int32)
    green = (rgb[..., 1] > rgb[..., 0]+20) & (rgb[..., 1] > rgb[..., 2]+10)
    target = np.median(hsv(glow_img)[green], axis=0)

    gltf = GLTF2().load_binary(source)
    image, img = image_of(gltf, gltf.materials[0].pbrMetallicRoughness.baseColorTexture.index)
    h, s, v = np.moveaxis(hsv(img), -1, 0)
    blue = (h > 170/360) & (h < 245/360) & (s > .18)
    ref_s, ref_v = np.median(s[blue]), np.median(v[blue])
    out = np.stack([h, s, v], axis=-1)
    out[blue, 0] = target[0]
    out[blue, 1] = np.clip(s[blue]*target[1]/ref_s, 0, 1)
    out[blue, 2] = np.clip(v[blue]*target[2]/ref_v, 0, 1)
    recolored = Image.fromarray((out*255).astype(np.uint8), "HSV").convert("RGB")
    buffer = io.BytesIO()
    recolored.save(buffer, "JPEG", quality=92)

    blob = bytearray(gltf.binary_blob())
    while len(blob) % 4:
        blob.append(0)
    gltf.bufferViews.append(BufferView(buffer=0, byteOffset=len(blob), byteLength=buffer.tell()))
    blob.extend(buffer.getvalue())
    image.bufferView = len(gltf.bufferViews)-1
    gltf.buffers[0].byteLength = len(blob)
    gltf.set_binary_blob(bytes(blob))
    gltf.save_binary(output)
    print(f"target hsv {np.round(target, 3)}, recolored {blue.mean()*100:.1f}% of texels")


if __name__ == "__main__":
    main(*sys.argv[1:4])
