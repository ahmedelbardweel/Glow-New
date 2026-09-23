"""Local orthographic textured mesh inspection (no changes to the GLB)."""
from __future__ import annotations
import argparse
import io
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from pygltflib import GLTF2
from rig_port_frontal import read_accessor


def render(path, output, *, region=(-.22, .22, .41, .66), size=1000, grid=True):
    gltf = GLTF2().load_binary(str(path))
    prim = gltf.meshes[0].primitives[0]
    a = prim.attributes
    p = read_accessor(gltf, a.POSITION).astype(float)
    p = p*np.array(gltf.nodes[0].scale or [1, 1, 1])+np.array(gltf.nodes[0].translation or [0, 0, 0])
    n = read_accessor(gltf, a.NORMAL).astype(float)
    uv = read_accessor(gltf, a.TEXCOORD_0).astype(float)
    tri = read_accessor(gltf, prim.indices).reshape(-1, 3).astype(int)
    info = gltf.materials[prim.material].pbrMetallicRoughness.baseColorTexture
    transform = info.extensions.get('KHR_texture_transform', {})
    uv = uv*np.array(transform.get('scale', [1, 1]))+np.array(transform.get('offset', [0, 0]))
    im = gltf.images[gltf.textures[info.index].source]
    v = gltf.bufferViews[im.bufferView]
    texture = np.array(Image.open(io.BytesIO(gltf.binary_blob()[v.byteOffset:v.byteOffset+v.byteLength])).convert('RGB'))
    l, r, bottom, top = region
    width, height = size, round(size*(top-bottom)/(r-l))
    projected = np.c_[(p[:, 0]-l)/(r-l)*(width-1), (top-p[:, 1])/(top-bottom)*(height-1)]
    pixels = np.full((height, width, 3), (238, 242, 239), dtype=np.uint8)
    depth = np.full((height, width), -np.inf)
    world = np.full((height, width, 3), np.nan, dtype=np.float32)
    for ids in tri:
        points = projected[ids]
        xmin, ymin = np.floor(points.min(0)).astype(int)
        xmax, ymax = np.ceil(points.max(0)).astype(int)
        xmin, xmax = max(0, xmin), min(width-1, xmax)
        ymin, ymax = max(0, ymin), min(height-1, ymax)
        if xmin > xmax or ymin > ymax:
            continue
        p0, p1, p2 = points
        den = (p1[1]-p2[1])*(p0[0]-p2[0])+(p2[0]-p1[0])*(p0[1]-p2[1])
        if abs(den) < 1e-10:
            continue
        xx, yy = np.meshgrid(np.arange(xmin,xmax+1),np.arange(ymin,ymax+1))
        first = ((p1[1]-p2[1])*(xx-p2[0])+(p2[0]-p1[0])*(yy-p2[1]))/den
        second = ((p2[1]-p0[1])*(xx-p2[0])+(p0[0]-p2[0])*(yy-p2[1]))/den
        third = 1-first-second
        bary = np.stack([first,second,third],axis=-1)
        zz = bary @ p[ids,2]
        mask = (bary.min(-1)>=-1e-6)&(zz>depth[ymin:ymax+1,xmin:xmax+1])
        if not mask.any():
            continue
        uvs = (bary@uv[ids]) % 1
        tx = np.clip((uvs[:,:,0]*(texture.shape[1]-1)).astype(int),0,texture.shape[1]-1)
        ty = np.clip((uvs[:,:,1]*(texture.shape[0]-1)).astype(int),0,texture.shape[0]-1)
        normal = bary@n[ids]
        normal /= np.maximum(np.linalg.norm(normal,axis=-1,keepdims=True),1e-8)
        light = np.array([-.3,.6,.85]); light/=np.linalg.norm(light)
        shade = .50+.50*np.maximum(normal@light,0)
        color = np.clip(texture[ty,tx]*shade[:,:,None],0,255).astype(np.uint8)
        pixels[ymin:ymax+1,xmin:xmax+1][mask]=color[mask]
        depth[ymin:ymax+1,xmin:xmax+1][mask]=zz[mask]
        world[ymin:ymax+1,xmin:xmax+1][mask]=(bary@p[ids])[mask]
    image=Image.fromarray(pixels)
    if grid:
        draw=ImageDraw.Draw(image)
        for y in np.arange(np.ceil(bottom*100)/100,top,.02):
            py=(top-y)/(top-bottom)*(height-1)
            draw.line((0,py,width,py),fill=(50,110,165),width=1)
            draw.text((3,py+2),f'y={y:.2f}',fill='white')
        for x in np.arange(np.ceil(l*100)/100,r,.02):
            px=(x-l)/(r-l)*(width-1)
            draw.line((px,0,px,height),fill=(50,110,165),width=1)
            draw.text((px+2,2),f'{x:.2f}',fill='white')
    output.parent.mkdir(parents=True,exist_ok=True)
    image.save(output)
    np.savez_compressed(output.with_suffix('.npz'),world=world,region=region)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    render(args.source,args.output)
