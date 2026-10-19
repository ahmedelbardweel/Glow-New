"""Verify mouth-only additions and morph geometry without altering the rig."""
import json,struct,sys
from pathlib import Path
import numpy as np
from validate_deformation import Rig,DTYPES,WIDTHS

before=Rig(sys.argv[1]);raw=Path(sys.argv[2]).read_bytes()
size=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+size]);blob=raw[28+size:]
def acc(i):
    a=g['accessors'][i];v=g['bufferViews'][a['bufferView']]
    return np.frombuffer(blob,dtype=DTYPES[a['componentType']],count=a['count']*WIDTHS[a['type']],offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],-1)
assert blob[:len(before.binary)]==before.binary
for key in ('meshes','materials','images','textures','accessors','bufferViews'):
    assert g[key][:len(before.doc[key])]==before.doc[key],key
head=before.names['Head'];mouth=g['extras']['mouthRefinement']['node']
for i,node in enumerate(before.nodes):
    expected=dict(node)
    if i==head:expected['children']=node.get('children',[])+[mouth]
    assert g['nodes'][i]==expected
samples=0
prim=g['meshes'][g['nodes'][mouth]['mesh']]['primitives'][0]
base=acc(prim['attributes']['POSITION']);delta=np.array([acc(t['POSITION']) for t in prim['targets']]);f=acc(prim['indices']).reshape(-1,3)
minimum=1
for old,new in zip(before.doc['animations'],g['animations']):
    assert new['channels'][:-1]==old['channels'] and new['samplers'][:-1]==old['samplers']
    sampler=new['samplers'][-1];times=acc(sampler['input']).ravel();weights=acc(sampler['output']).reshape(-1,4)
    assert np.allclose(weights[0],weights[-1]),'Loop seam'
    for t in np.linspace(0,times[-1],61):
        w=np.array([np.interp(t,times,weights[:,i]) for i in range(4)])
        p=base+np.einsum('i,ijk->jk',w,delta)
        area=np.linalg.norm(np.cross(p[f[:,1]]-p[f[:,0]],p[f[:,2]]-p[f[:,0]]),axis=1)
        assert np.isfinite(p).all() and area.min()>1e-10
        minimum=min(minimum,float(area.min()));samples+=1
print(json.dumps(dict(existingDataPreserved=True,headAttached=True,loopSeamsClosed=True,poseSamples=samples,minDoubleTriangleArea=minimum),indent=2))
