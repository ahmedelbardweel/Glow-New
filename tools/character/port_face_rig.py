"""Local mouth articulation on the supplied surface, with an unchanged rest pose.

The existing lip crease is refined with barycentric surface samples. Original
vertices and textured surface are retained. Lower-lip copies coincide with the
upper lip in rest. A recessed oral lining and tongue sit behind the closed
surface, becoming visible only when the jaw opens.
"""
from __future__ import annotations
import numpy as np
from port_rig_weights import ease
from port_lip_surface import split_lips

FACE_ANCHORS = {
    'Jaw': (0., .485, .150),
    'MouthCornerLeft': (.110, .505, .225),
    'MouthCornerRight': (-.110, .505, .225),
}
FACE_JOINTS = (16, 17, 18)




def corner_fields(p):
    values=[]
    for side in (1,-1):
        r=((p[:,0]-side*.104)/.063)**2+((p[:,1]-.500)/.048)**2+((p[:,2]-.229)/.065)**2
        values.append(.85*np.maximum(0,1-r)**2*(1-ease(.522,.538,p[:,1])))
    return np.array(values).T


def pack(full):
    full[full<1e-7]=0
    full/=full.sum(axis=1,keepdims=True)
    ids=np.argsort(-full,axis=1,kind='stable')[:,:4]
    weights=np.take_along_axis(full,ids,axis=1).astype(np.float32)
    ids[weights==0]=0
    return ids.astype(np.uint16),weights


def dense(joints,weights):
    result=np.zeros((len(joints),19))
    for slot in range(4):
        np.add.at(result,(np.arange(len(joints)),joints[:,slot]),weights[:,slot])
    return result


def normals(p,triangles):
    n=np.zeros_like(p)
    face=np.cross(p[triangles[:,1]]-p[triangles[:,0]],p[triangles[:,2]]-p[triangles[:,0]])
    for i in range(3):
        np.add.at(n,triangles[:,i],face)
    length=np.linalg.norm(n,axis=1,keepdims=True)
    n[length[:,0]<1e-10]=(0,0,1)
    return (n/np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-10)).astype(np.float32)


def build_face(p,n,uv,triangles,joints,weights):
    triangles=triangles.reshape(-1,3).astype(int)
    source_count=len(p)
    surface=split_lips(p,n,uv,triangles)
    p,n,uv=(surface[key] for key in ('positions','normals','uvs'))
    remapped=surface['indices']
    extra=np.zeros((len(p)-source_count,19));extra[:,0]=1
    full=np.concatenate((dense(joints,weights),extra))
    x,y,z=p.T
    curve_points=np.array(surface['lipPathPositions'])
    order=np.argsort(curve_points[:,0])
    seam_y=np.interp(x,curve_points[order,0],curve_points[order,1])
    lower=(y<seam_y)&(np.abs(x)<.110)&(z>.193)
    lower[surface['upperCopies']]=False
    lower[surface['lowerCopies']]=True
    jaw=(ease(.433,.478,y)*(1-ease(.077,.110,np.abs(x)))
         *ease(.193,.220,z)*lower)
    corner=corner_fields(p)
    face_amount=corner.sum(axis=1)+jaw*(1-corner.sum(axis=1))
    active=face_amount>0
    if np.any(full[active,1:16]>1e-8):
        raise ValueError('Face weights overlap limb weights')
    full[active]=0
    full[active,17:19]=corner[active]
    full[active,16]=jaw[active]*(1-corner[active].sum(axis=1))
    full[active,0]=1-full[active,16:].sum(axis=1)
    out_joints,out_weights=pack(full)
    upper=full[surface['upper']]
    bottom=full[surface['lower']]
    path=surface['upper']
    oral_positions=[];oral_weights=[];oral_triangles=[]
    count=len(path); rows=9
    for row,t in enumerate(np.linspace(0,1,rows)):
        arch=np.sin(np.linspace(0,np.pi,count))
        recessed=curve_points.copy()
        recessed[:,1]-=.004*np.sin(np.pi*t)*arch
        recessed[:,2]-=.042*np.sin(np.pi*t)*arch
        oral_positions.extend(recessed)
        oral_weights.extend((1-t)*upper+t*bottom)
        if row:
            for col in range(count-1):
                a=(row-1)*count+col;b=a+1;c=row*count+col;d=c+1
                oral_triangles.extend(((a,b,c),(b,d,c)))
    op=np.array(oral_positions,dtype=np.float32);ot=np.array(oral_triangles,dtype=np.uint16)
    oj,ow=pack(np.array(oral_weights))
    lining=dict(positions=op,normals=normals(op,ot),indices=ot,joints=oj,weights=ow,name='OralLining',color=[.075,.010,.017,1.])
    tp=[];tt=[]; rings=12;segments=32
    for j in range(rings+1):
        latitude=np.pi*j/rings
        for i in range(segments+1):
            angle=2*np.pi*i/segments
            tp.append((.051*np.sin(latitude)*np.cos(angle),
                       .489+.0055*np.cos(latitude),
                       .242+.014*np.sin(latitude)*np.sin(angle)))
            if j and i:
                d=j*(segments+1)+i;c=d-1;b=d-segments-1;a=b-1
                tt.extend(((a,b,c),(b,d,c)))
    tp=np.array(tp,dtype=np.float32);tt=np.array(tt,dtype=np.uint16)
    tj=np.zeros((len(tp),4),np.uint16);tj[:,0]=16
    tw=np.zeros((len(tp),4),np.float32);tw[:,0]=1
    tongue=dict(positions=tp,normals=normals(tp,tt),indices=tt,joints=tj,weights=tw,name='Tongue',color=[.48,.105,.135,1.])
    return dict(positions=p,normals=n,uvs=uv,indices=remapped.astype(np.uint16),
                joints=out_joints,weights=out_weights,interior=[lining,tongue],
                sourceVertexCount=source_count,
                surfaceVertexSources=surface['surfaceVertexSources'],
                addedTriangleSource=surface['addedTriangleSource'],
                lipUpperIndices=surface['upper'].tolist(),
                lipLowerIndices=surface['lower'].tolist(),
                lipPathPositions=curve_points.tolist(),
                faceVertices=int(active.sum()))


def expression(name,u):
    """Jaw rotation, left corner displacement, right corner displacement."""
    pulse=.5-.5*np.cos(2*np.pi*2*u)
    smile=0.;sad=0.;opening=0.
    if name in ('Smile','Wave','Victory'):
        smile={'Smile':.85,'Wave':.45,'Victory':.75}[name]
    elif name in ('Happy','Laugh'):
        smile=.90
        opening=(.11+.11*pulse) if name=='Happy' else (.13+.13*pulse)
    elif name=='Sad':
        sad=1.
    elif name=='Talk':
        opening=.025+.16*(np.sin(np.pi*4*u)**2)*(.75+.25*np.cos(2*np.pi*u))
    vertical=.014*smile-.019*sad
    width=.006*smile-.002*sad
    left=(width,vertical,0.);right=(-width,vertical,0.)
    return (float(opening),0.,0.),left,right
