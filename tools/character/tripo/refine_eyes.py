"""Separate the fused spectacles, restore their skin backing and add live eyes.

Input is skullCompletion v2, before eyeRefinement. Body, scalp, hat and all
existing skeleton/clip data are preserved. Eye nodes are children of Head;
four lid morph targets use the shared mobile/Dart eye controller convention.
"""
import argparse
import copy
import io
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components

from validate_deformation import Rig
from complete_skull import sample, linear
from eye_socket_surface import socket_surface

EYES = ((.125, .608, .205), (-.125, .608, .205))
RX, RY, RZ = .0565, .065, .027
TARGETS = ['BlinkLeftHalf', 'BlinkLeftClosed', 'BlinkRightHalf', 'BlinkRightClosed']


def normals(p, f):
    n = np.zeros_like(p)
    fn = np.cross(p[f[:, 1]]-p[f[:, 0]], p[f[:, 2]]-p[f[:, 0]])
    for k in range(3):
        np.add.at(n, f[:, k], fn)
    length = np.linalg.norm(n, axis=1)
    n[length < 1e-12] = [0, 0, 1]
    return n/np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def eye_surface():
    # Polar axis faces the camera; a single shared pole avoids pinched pupils.
    points = [[0, 0, RZ]]
    uv = [[.5, .5]]
    faces = []
    cols, rows = 128, 64
    for theta in np.linspace(np.pi/rows, np.pi-np.pi/rows, rows-1):
        for phi in np.arange(cols)*2*np.pi/cols:
            x, y = RX*np.sin(theta)*np.cos(phi), RY*np.sin(theta)*np.sin(phi)
            z = RZ*np.cos(theta)
            points.append([x,y,z]); uv.append([.5+x/(RX*2),.5-y/(RY*2)])
    for j in range(cols):
        faces.append([0,1+j,1+(j+1)%cols])
    for row in range(rows-2):
        start = 1+row*cols
        for j in range(cols):
            a,b=start+j,start+(j+1)%cols;c,d=a+cols,b+cols
            faces.extend([[a,c,b],[b,c,d]])
    end = len(points); points.append([0,0,-RZ]);uv.append([.5,.5])
    for j in range(cols):
        faces.append([end, end-cols+(j+1)%cols, end-cols+j])
    p,f=np.array(points),np.array(faces)
    n=p/[RX**2,RY**2,RZ**2];n/=np.linalg.norm(n,axis=1,keepdims=True)
    geometric=np.cross(p[f[:,1]]-p[f[:,0]],p[f[:,2]]-p[f[:,0]])
    flip=(geometric*n[f].mean(1)).sum(1)<0;f[flip]=f[flip][:,[0,2,1]]
    return p,n,np.array(uv),f


def eye_texture(skin):
    size=768
    yy,xx=np.mgrid[:size,:size]
    x=((xx+.5)/size-.5)*2*RX;y=(.5-(yy+.5)/size)*2*RY
    r=np.hypot(x,y);phi=np.arctan2(y,x)
    iris=.035; pupil=.020
    color=np.zeros((size,size,3))+[.88,.91,.82]
    # Slight warm sclera; clean round limbus and a subdued green radial iris.
    st=np.clip((r-pupil)/(iris-pupil),0,1)
    fibers=(np.sin(phi*71+st*8)+.4*np.sin(phi*113-st*6))*.014
    ir=np.stack([.36+.10*(1-st)+fibers,.52+.12*(1-st)+fibers,.19+.08*(1-st)+fibers],axis=2)
    limbus=np.clip((r-(iris-.0025))/.0025,0,1)
    ir=ir*(1-limbus[:,:,None]*.44)
    mix=np.clip((iris-r)/.00065,0,1)
    color=color*(1-mix[:,:,None])+ir*mix[:,:,None]
    pm=np.clip((pupil-r)/.00055,0,1)
    pupil_color=np.zeros_like(color)+[.047,.063,.077]
    color=color*(1-pm[:,:,None])+pupil_color*pm[:,:,None]
    # Two small catchlights travel with the iris, remaining soft at preview scale.
    for cx,cy,rad,strength in [(-.008,.011,.005,.95),(.009,-.009,.0019,.5)]:
        light=np.clip((rad-np.hypot(x-cx,y-cy))/.0007,0,1)*strength
        color=color*(1-light[:,:,None])+np.array([.98,1,1])*light[:,:,None]
    # The eyeball's equator is a skin rim, keeping its rear flank covered from
    # oblique views while the upper/lower lids travel over the front surface.
    rim=np.clip((np.hypot(x/RX,y/RY)-.88)/.08,0,1)
    color=color*(1-rim[:,:,None])+skin*rim[:,:,None]
    return np.round(np.clip(color,0,1)*255).astype('uint8')


def refine(source, destination):
    rig=Rig(source);g=rig.doc;blob=bytearray(rig.binary)
    assert not g.get('extras',{}).get('eyeRefinement'), 'Use the pre-eye skull v2 model'
    body=rig.primitives[0];old=rig.primitives[2]
    src=g['meshes'][rig.nodes[rig.names['Glasses']]['mesh']]['primitives'][0]
    bv=g['bufferViews'][g['images'][0]['bufferView']]
    atlas=np.array(Image.open(io.BytesIO(rig.binary[bv['byteOffset']:bv['byteOffset']+bv['byteLength']])).convert('RGB'))/255.
    body_attrs=g['meshes'][rig.nodes[rig.names['Body']]['mesh']]['primitives'][0]['attributes']
    body_rgb=sample(atlas,rig.accessor(body_attrs['TEXCOORD_0']))
    green=(body_rgb[:,1]>body_rgb[:,0]*1.3)&(body_rgb[:,1]>body_rgb[:,2]*1.25)
    body_distance=cKDTree(old['vertices']).query(body['vertices'])[0]
    green &= body_distance > .021
    color_tree=cKDTree(body['vertices'][green])
    def skin_color(points):
        d,k=color_tree.query(points,k=48)
        weight=1/np.maximum(d,.003)**2;weight/=weight.sum(1,keepdims=True)
        return (body_rgb[green][k]*weight[:,:,None]).sum(1)

    def accessor(values, kind, dtype='<f4', component=5126, target=34962):
        data=np.asarray(values,dtype=dtype);blob.extend(b'\0'*(-len(blob)%4))
        view=len(g['bufferViews']);g['bufferViews'].append(dict(buffer=0,byteOffset=len(blob),byteLength=data.nbytes,target=target));blob.extend(data.tobytes())
        entry=dict(bufferView=view,componentType=component,count=len(data),type=kind)
        if kind=='VEC3':entry.update(min=data.min(0).tolist(),max=data.max(0).tolist())
        result=len(g['accessors']);g['accessors'].append(entry);return result

    def texture(pixels,name):
        png=io.BytesIO();Image.fromarray(pixels).save(png,format='PNG');data=png.getvalue()
        blob.extend(b'\0'*(-len(blob)%4));view=len(g['bufferViews'])
        g['bufferViews'].append(dict(buffer=0,byteOffset=len(blob),byteLength=len(data)));blob.extend(data)
        im=len(g['images']);g['images'].append(dict(name=name,mimeType='image/png',bufferView=view))
        sampler=len(g.setdefault('samplers',[]));g['samplers'].append(dict(magFilter=9729,minFilter=9987,wrapS=33071,wrapT=33071))
        tex=len(g['textures']);g['textures'].append(dict(source=im,sampler=sampler));return tex

    def material(name,color,roughness,tex=None):
        mat=dict(name=name,doubleSided=True,pbrMetallicRoughness=dict(baseColorFactor=[*color,1],roughnessFactor=roughness,metallicFactor=0))
        if tex is not None:mat['pbrMetallicRoughness']['baseColorTexture']=dict(index=tex)
        idx=len(g['materials']);g['materials'].append(mat);return idx

    white_tex=texture(np.full((2,2,3),255,dtype='uint8'),'EyeSkinNeutral')
    skin_mat=material('EyeSocketSkin',[1,1,1],.78,white_tex)
    lid_color=skin_color(np.array([[.125,.695,.18],[-.125,.695,.18],[.07,.66,.22],[-.07,.66,.22]])).mean(0)
    eye_mat=material('EyeSurface',[1,1,1],.48,texture(eye_texture(lid_color),'CleanIris'))

    def primitive(p,n,f,mat,uv=None,col=None,skinned=False):
        attrs=dict(POSITION=accessor(p,'VEC3'),NORMAL=accessor(n,'VEC3'))
        if uv is not None:attrs['TEXCOORD_0']=accessor(uv,'VEC2')
        if col is not None:
            attrs['COLOR_0']=accessor(linear(col),'VEC3')
            attrs['_GLOW_SKIN_REGION']=accessor(np.ones((len(p),1)),'SCALAR')
        if skinned:
            joints=np.zeros((len(p),4),dtype='uint16');joints[:,0]=g['skins'][0]['joints'].index(rig.names['Head'])
            weights=np.zeros((len(p),4));weights[:,0]=1
            attrs['JOINTS_0']=accessor(joints,'VEC4','<u2',5123);attrs['WEIGHTS_0']=accessor(weights,'VEC4')
        return dict(attributes=attrs,indices=accessor(f.reshape(-1),'SCALAR','<u4',5125,34963),material=mat)

    def mesh_node(name,prim,parent=None,translation=None,skinned=False,extras=None):
        mesh=len(g['meshes']);g['meshes'].append(dict(name=name,primitives=[prim]))
        node=dict(name=name,mesh=mesh)
        if skinned:node['skin']=0
        if translation is not None:node['translation']=list(translation)
        if extras is not None:node['extras']=extras
        index=len(g['nodes']);g['nodes'].append(node)
        if parent is None:g['scenes'][g.get('scene',0)]['nodes'].append(index)
        else:g['nodes'][parent].setdefault('children',[]).append(index)
        return mesh,index

    body['normals']=rig.accessor(body_attrs['NORMAL'])
    patch,ns,socket_faces,pc=socket_surface(body,old,body_rgb)
    mesh_node('EyeSocketSkin',primitive(patch,ns,socket_faces,skin_mat,np.zeros((len(patch),2)),pc,True),skinned=True)

    # Retain the original sculpted frames/arms, cutting out the fused eye discs.
    p=old['vertices'];f=old['faces'];centers=p[f].mean(1)
    radius=np.full(len(f),100.)
    for cx,cy,cz in EYES:
        radius=np.minimum(radius,((centers[:,0]-cx)/.0615)**2+((centers[:,1]-cy)/.073)**2)
    frame_uv=rig.accessor(src['attributes']['TEXCOORD_0'])
    frame_rgb=sample(atlas,frame_uv[f].mean(1))
    # The lower rim crosses inside the nominal ellipse. Classify the original
    # dark frame surface as well as position so the entire ring is retained.
    dark_frame=(frame_rgb[:,1]<frame_rgb[:,0]*1.2)&(frame_rgb.max(1)<.43)
    keep=((radius>.40)|(centers[:,2]<.17))&dark_frame
    # Discard isolated dark flecks from the old painted iris. The genuine
    # frame is a large connected surface; these islands are only 1–20 faces.
    unique,inv=np.unique(np.round(p,6),axis=0,return_inverse=True)
    selected=inv[f[keep]]
    edges=np.concatenate([selected[:,[0,1]],selected[:,[1,2]],selected[:,[2,0]]])
    graph=coo_matrix((np.ones(len(edges)),(edges[:,0],edges[:,1])),shape=(len(unique),len(unique)))
    _,labels=connected_components(graph,directed=False)
    counts=np.bincount(labels[selected[:,0]],minlength=len(unique))
    keep[keep]=counts[labels[selected[:,0]]]>=25
    # A separate accessory must not include the source whites or pupils.
    src['indices']=accessor(f[keep].reshape(-1),'SCALAR','<u4',5125,34963)
    frame_material=copy.deepcopy(g['materials'][src['material']])
    frame_material['name']='SpectacleFrame'
    frame_material['pbrMetallicRoughness']['baseColorFactor']=[.36,.44,.46,1]
    src['material']=len(g['materials']);g['materials'].append(frame_material)

    head=rig.names['Head'];head_origin=rig.rest_world[head,:3,3]
    ep,en,euv,ef=eye_surface()
    eye_prim=primitive(ep,en,ef,eye_mat,euv)
    for name,center in zip(['EyeLeft','EyeRight'],EYES):
        mesh_node(name,copy.deepcopy(eye_prim),head,np.array(center)-head_origin)

    # Fixed outer rim and curved traveling lip. The rest shape is a narrow
    # visible hood. Clearance bounds chord interpolation between morph shapes.
    shapes=[[],[],[]];indices=[];eye_ids=[];colors=[]
    cols,rows=81,10
    for eye,(cx,cy,cz) in enumerate(EYES):
        for upper in (True,False):
            start=len(eye_ids)
            for row,v in enumerate(np.linspace(0,1,rows)):
                for u in np.linspace(-.999,.999,cols):
                    arc=np.sqrt(1-u*u);x=(RX+.003)*u
                    border=(RY+.003)*arc*(1 if upper else -1)
                    for state,close in enumerate((0,.5,1)):
                        edge=((.90*(1-close)-.10*close) if upper else (-.97*(1-close)-.095*close))*(RY+.003)*arc
                        y=(1-v)*border+v*edge
                        r=(x/(RX+.003))**2+(y/(RY+.003))**2
                        z=cz+(RZ+.001)*np.sqrt(max(0,1-r))+.006*np.sin(v*np.pi/2)
                        shapes[state].append([cx+x,cy+y,z])
                    eye_ids.append(eye)
                    colors.append(1-.14*(v**16))
            for row in range(rows-1):
                for col in range(cols-1):
                    a=start+row*cols+col;b=a+1;c=a+cols;d=c+1
                    indices.extend([[a,c,b],[b,c,d]] if upper else [[a,b,c],[b,d,c]])
    poses=[np.array(p) for p in shapes];lf=np.array(indices);ids=np.array(eye_ids)
    ln=[normals(p,lf) for p in poses]
    # Lid color extends each surrounding green eye border with a subtle lip.
    lc=np.zeros_like(poses[0])
    for eye,(cx,cy,cz) in enumerate(EYES):
        lc[ids==eye]=lid_color
    lc*=np.array(colors)[:,None]
    lp=primitive(poses[0]-head_origin,ln[0],lf,skin_mat,np.zeros((len(ids),2)),lc)
    lp['targets']=[]
    for eye in range(2):
        for state in (1,2):
            delta=np.zeros_like(poses[0]);dn=delta.copy()
            delta[ids==eye]=(poses[state]-poses[0])[ids==eye]
            dn[ids==eye]=(ln[state]-ln[0])[ids==eye]
            lp['targets'].append(dict(POSITION=accessor(delta,'VEC3'),NORMAL=accessor(dn,'VEC3')))
    mi,ni=mesh_node('EyeLids',lp,head,extras={'keepOpenLids':True})
    g['meshes'][mi].update(weights=[0,0,0,0],extras={'targetNames':TARGETS})
    g.setdefault('extras',{})['eyeRefinement']=dict(version=1,eyes=[list(c) for c in EYES],radius=[RX,RY,RZ],frameIndependent=True,irisRadius=.035,pupilRadius=.020,sourceFrameFaces=int(keep.sum()),socketVertices=len(patch),lidVertices=len(ids),morphTargets=TARGETS)
    g['buffers'][0]['byteLength']=len(blob)
    js=json.dumps(g,separators=(',',':')).encode();js+=b' '*(-len(js)%4);blob+=b'\0'*(-len(blob)%4)
    out=struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob
    destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(out)
    print(json.dumps(g['extras']['eyeRefinement'],indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('input',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();assert args.input.resolve()!=args.output.resolve()
    refine(args.input,args.output)
