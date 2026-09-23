"""Render connected mesh-component maps for rigging QA.

This is a local inspection tool for the supplied static port_frontal asset.
It does not modify the model. Component rank labels match the output of
``rig_port_frontal.py --inspect`` and help keep hats/faces out of limb weights.
"""
from __future__ import annotations

import argparse
import colorsys
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from pygltflib import GLTF2

sys.path.insert(0, str(Path(__file__).parent))
from rig_port_frontal import components, read_accessor  # noqa: E402


def color(rank: int) -> tuple[int, int, int]:
    red, green, blue = colorsys.hsv_to_rgb((rank*.61803398875) % 1, .72, .94)
    return round(red*255), round(green*255), round(blue*255)


def projected(value: float, low: float, high: float, length: int, flip=False) -> int:
    ratio = (value-low)/(high-low)
    if flip:
        ratio = 1-ratio
    return max(0, min(length-1, round(ratio*(length-1))))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    gltf = GLTF2().load_binary(str(args.source))
    primitive = gltf.meshes[0].primitives[0]
    positions = read_accessor(gltf, primitive.attributes.POSITION).astype(np.float32)
    node = gltf.nodes[0]
    positions = positions*np.array(node.scale or [1, 1, 1])+np.array(node.translation or [0, 0, 0])
    indices = read_accessor(gltf, primitive.indices).reshape(-1).astype(np.uint32)
    labels, order = components(indices, len(positions))
    rank = {label: index for index, label in enumerate(order)}
    width, height, gutter = 700, 940, 36
    image = Image.new("RGB", (width*2+gutter, height), (245, 248, 246))
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()
    low, high = positions.min(axis=0), positions.max(axis=0)

    # Painter's algorithm: from rear to front in the first panel, then from
    # left to right for the side panel. A sparse sample keeps labels legible.
    for panel, horizontal, depth in ((0, 0, 2), (1, 2, 0)):
        order_points = np.argsort(positions[:, depth])
        for index in order_points[::2]:
            x = panel*(width+gutter)+projected(positions[index, horizontal], low[horizontal], high[horizontal], width)
            y = projected(positions[index, 1], low[1], high[1], height, flip=True)
            draw.point((x, y), fill=color(rank[labels[index]]))
        title = "FRONT (component rank)" if panel == 0 else "SIDE (component rank)"
        draw.text((panel*(width+gutter)+12, 12), title, fill=(20, 40, 32), font=font)
        for label in order:
            members = positions[labels == label]
            component_rank = rank[label]
            # Very small components get no label, but their colour still
            # renders; large pieces carry the anatomy labels needed for QA.
            if len(members) < 100:
                continue
            cx = panel*(width+gutter)+projected(float(members[:, horizontal].mean()), low[horizontal], high[horizontal], width)
            cy = projected(float(members[:, 1].mean()), low[1], high[1], height, flip=True)
            text = str(component_rank)
            box = draw.textbbox((cx, cy), text, font=font)
            draw.rectangle((box[0]-2, box[1]-1, box[2]+2, box[3]+1), fill=(10, 24, 18))
            draw.text((cx, cy), text, fill=(255, 255, 255), font=font)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    print(args.output)


if __name__ == "__main__":
    main()
