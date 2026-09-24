"""Local eye bones and source-textured, retractable eyelids.

The supplied surface is never resculpted. Gaze weights taper to zero inside the
spectacle rims. A separate lid mesh has open/half/closed shapes; its open shape
collapses to the existing border. UVs sample the original green forehead.
"""
from __future__ import annotations
import numpy as np
from port_rig_weights import ease
from port_face_rig import normals


EYES = ((.120, .607, .054, .054), (-.126, .607, .059, .054))
EYE_ANCHORS = {'EyeLeft': (.120,.607,.175), 'EyeRight': (-.126,.607,.175)}
TARGET_NAMES = ['BlinkLeftHalf','BlinkLeftClosed','BlinkRightHalf','BlinkRightClosed']


def eye_weights(p, joints, weights):
    joints=joints.copy();weights=weights.copy()
    for index,(cx,cy,rx,ry) in enumerate(EYES):
        r=((p[:,0]-cx)/(rx*.92))**2+((p[:,1]-cy)/(ry*.90))**2
        amount=(1-ease(.42,.94,r))*ease(.195,.217,p[:,2])
        active=amount>1e-7
        assert np.all((joints[active]==0)|(weights[active]==0)), 'Eye control overlaps existing rig'
        joints[active]=0;weights[active]=0
        joints[active,0]=19+index;weights[active,0]=amount[active]
        weights[active,1]=1-amount[active]
    joints[weights==0]=0
    return joints,weights


def sample_front_uv(p, uv, triangles, xy, *, depth=False):
    """Exact barycentric UV sampling on the original green forehead patch."""
    candidates=triangles[np.all(p[triangles,2]>.17,axis=1)]
    a,b,c=(p[candidates[:,i]] for i in range(3))
    ab=b[:,:2]-a[:,:2];ac=c[:,:2]-a[:,:2]
    den=ab[:,0]*ac[:,1]-ab[:,1]*ac[:,0]
    valid=np.abs(den)>1e-12
    candidates=candidates[valid];a=a[valid];ab=ab[valid];ac=ac[valid];den=den[valid]
    values=[]
    for point in xy:
        q=point-a[:,:2]
        v=(q[:,0]*ac[:,1]-q[:,1]*ac[:,0])/den
        w=(ab[:,0]*q[:,1]-ab[:,1]*q[:,0])/den
        inside=(v>=-1e-6)&(w>=-1e-6)&(v+w<=1.000001)
        ids=np.flatnonzero(inside)
        if not len(ids):raise ValueError(f'No forehead surface at {point}')
        bary=np.c_[1-v-w,v,w]
        z=np.sum(bary[ids]*p[candidates[ids],2],axis=1)
        index=ids[np.argmax(z)]
        values.append(float(z.max()) if depth else bary[index]@uv[candidates[index]])
    return np.array(values,dtype=np.float32)


def build_lids(p,uv,triangles):
    triangles=triangles.reshape(-1,3).astype(int)
    points=[];texture_xy=[];faces=[];eye_ids=[];colors=[];shapes=[[],[],[]]
    columns=41;rows=9
    for eye,(cx,cy,rx,ry) in enumerate(EYES):
        for upper in (True,False):
            offset=len(points)
            for row,v in enumerate((0.,.15,.3,.45,.6,.75,.90,.98,1.)):
                for col,u in enumerate(np.linspace(-.998,.998,columns)):
                    arc=np.sqrt(1-u*u)
                    x=rx*u
                    boundary=(ry if upper else -ry)*arc
                    meeting=-.007*arc
                    # Geometry at full closure meets along one shared curved seam.
                    for state,amount in enumerate((0.,.5,1.)):
                        y=(1-v*amount)*boundary+v*amount*meeting
                        # Z is sampled from the original eye surface below.
                        shapes[state].append((cx+x,cy+y,0.))
                    points.append(0)
                    eye_ids.append(eye)
                    texture_xy.append((.020,.670))
                    colors.append([.48 if row==rows-1 else 1.]*3)
                    if row and col:
                        d=offset+row*columns+col;c=d-1;b=d-columns;a=b-1
                        faces.extend(((a,c,b),(b,c,d)) if upper else ((a,b,c),(b,d,c)))
    poses=[np.array(value,dtype=np.float32) for value in shapes]
    for eye,(cx,cy,rx,ry) in enumerate(EYES):
        source=triangles[np.any((np.abs(p[triangles,0]-cx)<rx+.008)&(np.abs(p[triangles,1]-cy)<ry+.008),axis=1)]
        selected=np.array(eye_ids)==eye
        for pose in poses:
            radius=((pose[selected,0]-cx)/rx)**2+((pose[selected,1]-cy)/ry)**2
            clearance=.0018+.005*np.exp(-radius/.45)
            pose[selected,2]=sample_front_uv(p,uv,source,pose[selected,:2],depth=True)+clearance
    faces=np.array(faces,dtype=np.uint16)
    # Open shells are collapsed; use closed-shape normals
    # as their stable rest normals instead of normals of collapsed triangles.
    ns=[normals(value,faces) for value in poses]
    ns[0]=ns[2].copy()
    ids=np.array(eye_ids)
    targets=[]
    for eye in range(2):
        for state in (1,2):
            delta=np.zeros_like(poses[0]);dn=np.zeros_like(delta)
            delta[ids==eye]=(poses[state]-poses[0])[ids==eye]
            dn[ids==eye]=(ns[state]-ns[0])[ids==eye]
            targets.append(dict(positions=delta,normals=dn))
    return dict(positions=poses[0],normals=ns[0],indices=faces,colors=np.array(colors,np.float32),
                uvs=np.repeat(sample_front_uv(p,uv,triangles,np.array(texture_xy[:1])),len(points),axis=0),targets=targets)
