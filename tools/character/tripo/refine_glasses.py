"""Rebuild only the removable frame, using the original spectacle material.

Fit smooth tube centerlines to the original sculpted frame. The eye update
and every other mesh, material, texture, animation and node remain untouched.
"""
import argparse
import io
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image
try:
    from scipy.interpolate import CubicSpline
except ImportError:
    from frame_math import CubicSpline
from frame_math import sample
from validate_deformation import Rig


def tube(path, radius, closed, reference=(0, 0, 1), sides=20):
    tangent=(np.roll(path,-1,axis=0)-np.roll(path,1,axis=0)) if closed else np.gradient(path,axis=0)
    tangent/=np.linalg.norm(tangent,axis=1,keepdims=True)
    a=np.cross(tangent,reference);a/=np.linalg.norm(a,axis=1,keepdims=True)
    b=np.cross(tangent,a)
    angle=np.arange(sides)*2*np.pi/sides
    normal=a[:,None,:]*np.cos(angle)[None,:,None]+b[:,None,:]*np.sin(angle)[None,:,None]
    p=(path[:,None,:]+radius*normal).reshape(-1,3);n=normal.reshape(-1,3)
    faces=[]
    for row in range(len(path) if closed else len(path)-1):
        next_row=(row+1)%len(path)
        for col in range(sides):
            u=row*sides+col;v=row*sides+(col+1)%sides
            w=next_row*sides+col;x=next_row*sides+(col+1)%sides
            faces.extend([[u,w,v],[v,w,x]])
    if not closed:
        # Duplicate cap rims so their axial normals do not flatten the tube.
        for row,axis in [(0,-tangent[0]),(len(path)-1,tangent[-1])]:
            start=len(p)
            p=np.concatenate([p,path[row:row+1],p[row*sides:(row+1)*sides]])
            n=np.concatenate([n,np.tile(axis,(sides+1,1))])
            for col in range(sides):faces.append([start,start+1+col,start+1+(col+1)%sides])
    f=np.array(faces)
    geometric=np.cross(p[f[:,1]]-p[f[:,0]],p[f[:,2]]-p[f[:,0]])
    flip=(geometric*n[f].mean(1)).sum(1)<0;f[flip]=f[flip][:,[0,2,1]]
    return p,n,f


def refine(source, original, destination):
    rig,old=Rig(source),Rig(original)
    g=rig.doc;blob=bytearray(rig.binary)
    node=g['nodes'][rig.names['Glasses']]
    original_primitive=old.doc['meshes'][old.nodes[old.names['Glasses']]['mesh']]['primitives'][0]
    p=old.accessor(original_primitive['attributes']['POSITION'])
    uv=old.accessor(original_primitive['attributes']['TEXCOORD_0'])
    original_material=original_primitive['material']
    assert g['materials'][original_material]==old.doc['materials'][original_material]
    bv=old.doc['bufferViews'][old.doc['images'][0]['bufferView']]
    atlas=np.array(Image.open(io.BytesIO(old.binary[bv['byteOffset']:bv['byteOffset']+bv['byteLength']])).convert('RGB'))/255.
    color=sample(atlas,uv)
    dark=(color[:,1]<color[:,0]*1.15)&(color.max(1)<.40)
    # Select a representative original frame texel, preserving its original
    # atlas/PBR material instead of applying the eye revision's black tint.
    source_normal=old.accessor(original_primitive['attributes']['NORMAL'])
    frame_radius=((np.abs(p[:,0])-.125)/.064)**2+((p[:,1]-.608)/.076)**2
    frame_samples=dark&(p[:,2]>.18)&(source_normal[:,2]>.55)&(frame_radius>.60)&(frame_radius<1.5)
    median=np.median(color[frame_samples],axis=0)
    ids=np.flatnonzero(frame_samples)
    texel=ids[np.argmin(np.linalg.norm(color[ids]-median,axis=1))]
    frame_uv=uv[texel]

    # Mirror samples from both rims, then use a low-order periodic fit for a
    # smooth, equal pair that retains the source's oval shape and face wrap.
    side=np.where(p[:,0]>=0,1,-1)
    dx=(p[:,0]*side-.125)/.064;dy=(p[:,1]-.608)/.076
    rad=np.hypot(dx,dy);theta=np.arctan2(dy,dx)
    gate=dark&(rad>.70)&(rad<1.27)&(p[:,2]>.165)
    ts=[];values=[]
    for angle in np.linspace(-np.pi,np.pi,48,endpoint=False):
        near=gate&(abs(np.angle(np.exp(1j*(theta-angle))))<.10)
        if near.sum()>=3:
            ts.append(angle);values.append([np.median(rad[near]),np.median(p[near,2])])
    ts=np.array(ts);values=np.array(values)
    def basis(t):
        return np.column_stack([np.ones_like(t),np.cos(t),np.sin(t),np.cos(2*t),np.sin(2*t)])
    coeff=np.linalg.lstsq(basis(ts),values,rcond=None)[0]
    def rim(t,side):
        fit=basis(np.asarray(t))@coeff
        # Match the actual white-eye silhouette, not the old sculpted rim.
        # A small overlap hides the bottom gap; the reduced vertical radius
        # makes the outline rounder while retaining room for the eyelids.
        return np.c_[side*(.125+.0615*np.cos(t)),.608+.0655*np.sin(t),fit[:,1]+.001]
    angles=np.arange(192)*2*np.pi/192
    pieces=[tube(rim(angles,side),.0064,True) for side in (1,-1)]

    # The bridge meets both complete rings; a round cross-section eliminates
    # the open, jagged triangles left by separating the original fused eyes.
    right,left=rim(np.array([np.pi]),1)[0],rim(np.array([np.pi]),-1)[0]
    control=np.array([left,left+[.035,.035,.010],right+[-.035,.035,.010],right])
    t=np.linspace(0,1,64)[:,None]
    bridge=(1-t)**3*control[0]+3*(1-t)**2*t*control[1]+3*(1-t)*t*t*control[2]+t**3*control[3]
    pieces.append(tube(bridge,.0062,False,reference=(0,1,0)))

    # Preserve the original side arms and curved rear strap, fitted to their
    # actual radius/height rather than an arbitrary circle through the head.
    ta=np.abs(np.arctan2(p[:,0],p[:,2]+.015));ra=np.hypot(p[:,0],p[:,2]+.015)
    knots=np.linspace(.87,np.pi,22);samples=[]
    for angle in knots:
        near=dark&(abs(ta-angle)<.085)&(p[:,2]<.17)
        assert near.any(), f'Missing frame arm samples at {angle}'
        samples.append([np.median(ra[near]),np.median(p[near,1])])
    # A low-order symmetric curve suppresses bumps from the old triangulated
    # arms; interpolation through every noisy source sample reproduces waves.
    coefficients=np.polynomial.polynomial.polyfit(np.cos(knots),np.array(samples),3)
    a=np.linspace(.87,2*np.pi-.87,140)
    r,y=np.polynomial.polynomial.polyval(np.cos(a),coefficients)
    band=np.c_[(r+.001)*np.sin(a),y,(r+.001)*np.cos(a)-.015]
    path=np.concatenate([rim(np.array([.28]),1),band,rim(np.array([.28]),-1)])
    distance=np.r_[0,np.cumsum(np.linalg.norm(np.diff(path,axis=0),axis=1))]
    path=CubicSpline(distance,path)(np.linspace(0,distance[-1],280))
    pieces.append(tube(path,.0065,False,reference=(0,1,0)))

    positions=[];normals=[];faces=[];offset=0
    for v,n,f in pieces:
        positions.append(v);normals.append(n);faces.append(f+offset);offset+=len(v)
    v=np.concatenate(positions);n=np.concatenate(normals);f=np.concatenate(faces)
    def accessor(values,kind,dtype='<f4',component=5126,target=34962):
        data=np.asarray(values,dtype=dtype);blob.extend(b'\0'*(-len(blob)%4))
        view=len(g['bufferViews']);g['bufferViews'].append(dict(buffer=0,byteOffset=len(blob),byteLength=data.nbytes,target=target));blob.extend(data.tobytes())
        entry=dict(bufferView=view,componentType=component,count=len(data),type=kind)
        if kind=='VEC3':entry.update(min=data.min(0).tolist(),max=data.max(0).tolist())
        index=len(g['accessors']);g['accessors'].append(entry);return index
    joints=np.zeros((len(v),4),dtype='uint16');joints[:,0]=g['skins'][node['skin']]['joints'].index(rig.names['Head'])
    weights=np.zeros((len(v),4));weights[:,0]=1
    primitive=dict(attributes=dict(POSITION=accessor(v,'VEC3'),NORMAL=accessor(n,'VEC3'),TEXCOORD_0=accessor(np.tile(frame_uv,(len(v),1)),'VEC2'),JOINTS_0=accessor(joints,'VEC4','<u2',5123),WEIGHTS_0=accessor(weights,'VEC4')),indices=accessor(f.reshape(-1),'SCALAR','<u4',5125,34963),material=original_material)
    g['meshes'][node['mesh']]['primitives']=[primitive]
    g.setdefault('extras',{})['frameRefinement']=dict(version=2,vertices=len(v),triangles=len(f),originalMaterial=original_material,originalColor=sample(atlas,frame_uv[None])[0].tolist(),rimRadius=.0064,rimAxes=[.0615,.0655],onlyFrameChanged=True)
    g['buffers'][0]['byteLength']=len(blob)
    js=json.dumps(g,separators=(',',':')).encode();js+=b' '*(-len(js)%4);blob+=b'\0'*(-len(blob)%4)
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob)
    print(json.dumps(g['extras']['frameRefinement'],indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('input',type=Path);parser.add_argument('original',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();assert args.input.resolve()!=args.output.resolve()
    refine(args.input,args.original,args.output)
