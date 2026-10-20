"""Smooth the completed head across its welded scalp/body boundary."""
import argparse,json,struct,io
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
from frame_math import sample

TYPES={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}
WIDTH={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
def smooth(x):
    x=np.clip(x,0,1);return x*x*(3-2*x)

def refine(source,destination):
    raw=Path(source).read_bytes();size=struct.unpack_from('<I',raw,12)[0]
    g=json.loads(raw[20:20+size]);blob=bytearray(raw[28+size:])
    def get(i):
        a=g['accessors'][i];v=g['bufferViews'][a['bufferView']]
        return np.frombuffer(blob,dtype=TYPES[a['componentType']],count=a['count']*WIDTH[a['type']],offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],-1).copy()
    def put(data,kind='VEC3'):
        data=np.asarray(data,dtype='<f4');blob.extend(b'\0'*(-len(blob)%4));vi=len(g['bufferViews'])
        g['bufferViews'].append(dict(buffer=0,byteOffset=len(blob),byteLength=data.nbytes,target=34962));blob.extend(data.tobytes());ai=len(g['accessors'])
        g['accessors'].append(dict(bufferView=vi,componentType=5126,count=len(data),type=kind,min=data.min(0).tolist(),max=data.max(0).tolist()));return ai
    prim=[];positions=[];faces=[];normals=[];offset=0
    for name in ['Body','Scalp','EyeSocketSkin']:
        node=next(n for n in g['nodes'] if n.get('name')==name);p=g['meshes'][node['mesh']]['primitives'][0];prim.append(p)
        v=get(p['attributes']['POSITION']);positions.append(v);normals.append(get(p['attributes']['NORMAL']))
        faces.append(get(p['indices']).reshape(-1,3)+offset);offset+=len(v)
    old=np.concatenate(positions);oldn=np.concatenate(normals);f=np.concatenate(faces)
    # Fit one smooth ellipsoid to both surfaces; protect nose, brows and eyes.
    # A continuous spatial field avoids pulling apart the source's open UV edges.
    shell=np.concatenate(positions[:2])
    fit=shell[(shell[:,1]>.55)&((shell[:,2]<.12)|(shell[:,1]>.74))]
    x,y,z=fit.T
    coef=np.linalg.lstsq(np.c_[x*x,z*z,y*y,y,z],np.ones(len(fit)),rcond=None)[0]
    cy=-coef[3]/(2*coef[2]);cz=-coef[4]/(2*coef[1])
    k=1+coef[2]*cy*cy+coef[1]*cz*cz
    rx,rz,ry=np.sqrt(k/coef[:3]);ry=.88-cy
    angle=np.arctan2((old[:,0])/rx,(old[:,2]-cz)/rz)
    radius=np.sqrt(np.clip(1-((old[:,1]-cy)/ry)**2,0,1))
    target=np.c_[rx*radius*np.sin(angle),old[:,1],cz+rz*radius*np.cos(angle)]
    front=smooth((old[:,2]-.03)/.15)
    lower=.43+.25*front
    weight=smooth((old[:,1]-lower)/.07)
    new=old*(1-weight[:,None])+target*weight[:,None]
    n=(target-[0,cy,cz])/[rx*rx,ry*ry,rz*rz]
    n/=np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-15)
    normal=oldn*(1-weight[:,None])+n*weight[:,None]
    normal/=np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),1e-15)
    # The removable-glasses backing wraps around the sides and rear too.
    # Deform it with the head and retain a tiny clearance at overlapping edges.
    socket_start=sum(map(len,positions[:2]))
    new[socket_start:]+=n[socket_start:]*weight[socket_start:,None]*.00008
    offset=0
    for p,original in zip(prim,positions):
        count=len(original);p['attributes']['POSITION']=put(new[offset:offset+count]);p['attributes']['NORMAL']=put(normal[offset:offset+count]);offset+=count
    def texture_image(texture):
        im=g['images'][g['textures'][texture]['source']];view=g['bufferViews'][im['bufferView']]
        return np.array(Image.open(io.BytesIO(blob[view['byteOffset']:view['byteOffset']+view['byteLength']])).convert('RGB'))/255
    bodymat=g['materials'][prim[0]['material']]
    atlas=texture_image(bodymat['pbrMetallicRoughness']['baseColorTexture']['index'])
    uv=get(prim[0]['attributes']['TEXCOORD_0']);rgb=sample(atlas,uv)
    clean=(rgb[:,1]>1.5*np.maximum(rgb[:,0],rgb[:,2]))&(positions[0][:,1]>.59)&(positions[0][:,1]<.67)
    tone=np.median(rgb[clean],axis=0)
    bp=positions[0];cw=smooth((bp[:,1]-(.42+.18*smooth((bp[:,2]-.03)/.15)))/.075)
    h,w=atlas.shape[:2];mask=np.zeros((h,w),dtype=np.float32)
    for face in faces[0][cw[faces[0]].max(1)>.001]:
        xy=uv[face]*[w,h]-.5;x,y=xy.T
        x0,x1=max(0,int(np.floor(x.min()))),min(w,int(np.ceil(x.max()))+1)
        y0,y1=max(0,int(np.floor(y.min()))),min(h,int(np.ceil(y.max()))+1)
        if x0>=x1 or y0>=y1:continue
        yy,xx=np.mgrid[y0:y1,x0:x1]
        den=(y[1]-y[2])*(x[0]-x[2])+(x[2]-x[1])*(y[0]-y[2])
        if abs(den)<1e-10:continue
        a=((y[1]-y[2])*(xx-x[2])+(x[2]-x[1])*(yy-y[2]))/den
        b=((y[2]-y[0])*(xx-x[2])+(x[0]-x[2])*(yy-y[2]))/den;c=1-a-b
        values=(a*cw[face[0]]+b*cw[face[1]]+c*cw[face[2]])*((a>=-.001)&(b>=-.001)&(c>=-.001))
        mask[y0:y1,x0:x1]=np.maximum(mask[y0:y1,x0:x1],values)
    mask=np.array(Image.fromarray(np.uint8(np.clip(mask,0,1)*255)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(.5)))/255
    atlas=atlas*(1-mask[:,:,None])+tone*mask[:,:,None]
    png=io.BytesIO();Image.fromarray(np.uint8(np.clip(atlas,0,1)*255+.5)).save(png,format='PNG')
    data=png.getvalue();blob.extend(b'\0'*(-len(blob)%4));vi=len(g['bufferViews']);g['bufferViews'].append(dict(buffer=0,byteOffset=len(blob),byteLength=len(data)));blob.extend(data)
    im=len(g['images']);g['images'].append(dict(name='SmoothHeadAtlas',mimeType='image/png',bufferView=vi))
    texture=dict(g['textures'][bodymat['pbrMetallicRoughness']['baseColorTexture']['index']]);texture['source']=im
    ti=len(g['textures']);g['textures'].append(texture)
    mat=json.loads(json.dumps(bodymat));mat['name']='GlowSmoothHeadSkin';mat['pbrMetallicRoughness']['baseColorTexture']['index']=ti
    prim[0]['material']=len(g['materials']);g['materials'].append(mat)
    def linear(c):return np.where(c<=.04045,c/12.92,((c+.055)/1.055)**2.4)
    scalpbase=texture_image(g['materials'][prim[1]['material']]['pbrMetallicRoughness']['baseColorTexture']['index'])
    reference=linear(sample(scalpbase,get(prim[1]['attributes']['TEXCOORD_0'])))
    prim[1]['attributes']['COLOR_0']=put(np.clip(linear(tone)/np.maximum(reference,1e-8),0,1))
    socket=positions[2]
    blend=smooth((socket[:,1]-(.42+.18*smooth((socket[:,2]-.03)/.15)))/.075)
    color=get(prim[2]['attributes']['COLOR_0'])
    prim[2]['attributes']['COLOR_0']=put(color*(1-blend[:,None])+linear(tone)*blend[:,None])
    # One consistent soft surface response instead of a separate glossy cap.
    material=g['materials'][prim[1]['material']]['pbrMetallicRoughness']
    material['roughnessFactor']=.78;material.pop('metallicRoughnessTexture',None)
    g.setdefault('extras',{})['headSmoothing']=dict(version=2,method='continuous fitted head surface',maxDisplacement=float(np.linalg.norm(new-old,axis=1).max()),center=[0,cy,cz],radii=[rx,ry,rz])
    g['buffers'][0]['byteLength']=len(blob);js=json.dumps(g,separators=(',',':')).encode();js+=b' '*(-len(js)%4);blob+=b'\0'*(-len(blob)%4)
    Path(destination).write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob)
    print(json.dumps(g['extras']['headSmoothing'],indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('source');p.add_argument('destination');a=p.parse_args();refine(a.source,a.destination)
