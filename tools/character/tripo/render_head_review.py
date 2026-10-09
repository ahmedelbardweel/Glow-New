"""Offline textured GLB close-up for reviewing the lower head silhouette."""
import argparse
import io
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from validate_deformation import Rig


def render(rig, motion, angle, size=(640, 480)):
    world = rig.world(rig.pose(None if motion == 'bind' else motion, 0))
    a = np.radians(angle)
    camera = np.array([[np.cos(a), 0, -np.sin(a)], [0, 1, 0],
                       [np.sin(a), 0, np.cos(a)]])
    w, h = size
    left, right, bottom, top = -.37, .37, .34, .895
    canvas = np.full((h, w, 3), 243., dtype=float)
    depth = np.full((h, w), -np.inf)
    light = np.array([-.3, .4, .85]); light /= np.linalg.norm(light)
    for part in rig.primitives:
        node = rig.nodes[rig.names[part['name']]]
        primitive = rig.doc['meshes'][node['mesh']]['primitives'][0]
        uv = rig.accessor(primitive['attributes']['TEXCOORD_0'])
        normal = rig.accessor(primitive['attributes']['NORMAL'])
        matrices = world[part['joint_nodes']] @ part['inverse']
        norm = np.zeros_like(normal)
        for k in range(4):
            norm += part['weights'][:, k, None] * np.einsum('nij,nj->ni', matrices[part['joints'][:, k], :3, :3], normal)
        norm = norm @ camera.T
        norm /= np.maximum(np.linalg.norm(norm, axis=1, keepdims=True), 1e-12)
        image = rig.doc['images'][0]
        bv = rig.doc['bufferViews'][image['bufferView']]
        atlas = np.array(Image.open(io.BytesIO(rig.binary[bv.get('byteOffset',0):bv.get('byteOffset',0)+bv['byteLength']])).convert('RGB'))
        v = Rig.deform(part, world) @ camera.T
        f = part['faces']; p = v[f]
        sx = (p[:,:,0] - left) / (right-left) * w
        sy = (top-p[:,:,1]) / (top-bottom) * h
        ns = norm[f]; uvs = uv[f]
        for i in range(len(f)):
            xs, ys, zs = sx[i], sy[i], p[i,:,2]
            x0, x1 = max(0,int(np.floor(xs.min()))), min(w,int(np.ceil(xs.max()))+1)
            y0, y1 = max(0,int(np.floor(ys.min()))), min(h,int(np.ceil(ys.max()))+1)
            if x0>=x1 or y0>=y1: continue
            denom = (ys[1]-ys[2])*(xs[0]-xs[2])+(xs[2]-xs[1])*(ys[0]-ys[2])
            if abs(denom)<1e-10: continue
            xx, yy = np.meshgrid(np.arange(x0,x1)+.5,np.arange(y0,y1)+.5)
            aa=((ys[1]-ys[2])*(xx-xs[2])+(xs[2]-xs[1])*(yy-ys[2]))/denom
            bb=((ys[2]-ys[0])*(xx-xs[2])+(xs[0]-xs[2])*(yy-ys[2]))/denom
            cc=1-aa-bb
            z=aa*zs[0]+bb*zs[1]+cc*zs[2]
            sub=depth[y0:y1,x0:x1]
            hit=(aa>=0)&(bb>=0)&(cc>=0)&(z>sub)
            if not hit.any(): continue
            bary=np.stack([aa[hit],bb[hit],cc[hit]],1)
            tex=bary@uvs[i]
            tx=np.clip((tex[:,0]*(atlas.shape[1]-1)).astype(int),0,atlas.shape[1]-1)
            ty=np.clip((tex[:,1]*(atlas.shape[0]-1)).astype(int),0,atlas.shape[0]-1)
            n=bary@ns[i]; n/=np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-9)
            shade=.62+.38*np.clip(n@light,0,1)
            canvas[y0:y1,x0:x1][hit]=atlas[ty,tx]*shade[:,None]
            sub[hit]=z[hit]
    return Image.fromarray(np.clip(canvas,0,255).astype('uint8'))


def main():
    p=argparse.ArgumentParser();p.add_argument('input');p.add_argument('output');p.add_argument('--motion',default='Idle');p.add_argument('--angle',type=float,default=0)
    a=p.parse_args(); result=render(Rig(a.input),a.motion,a.angle);result.save(a.output);print('Saved',a.output)


if __name__=='__main__': main()
