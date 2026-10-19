"""Turn the waving palm toward the viewer without changing other clips."""
import argparse
import json
import struct
from pathlib import Path
import numpy as np


def read(path):
    raw=Path(path).read_bytes();size=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+size]),bytearray(raw[28+size:])


def accessor(g,blob,i):
    a=g['accessors'][i];v=g['bufferViews'][a['bufferView']]
    return np.frombuffer(blob,dtype='<f4',count=a['count']*(4 if a['type']=='VEC4' else 1),offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],-1).copy()


def multiply(a,b):
    xyz=a[:,:3]*b[3]+b[:3]*a[:,3:]+np.cross(a[:,:3],b[:3])
    w=a[:,3]*b[3]-a[:,:3]@b[:3]
    q=np.c_[xyz,w];return q/np.linalg.norm(q,axis=1,keepdims=True)


def refine(source,dest,roll):
    g,blob=read(source);names={n.get('name'):i for i,n in enumerate(g['nodes'])}
    wave=next(a for a in g['animations'] if a['name']=='Wave')
    # Distribute the roll over forearm and wrist to avoid pinching the cuff.
    for name,child,amount in [('RightForeArm','RightHand',.72),('RightHand','RightHandEnd',.28)]:
        channel=next(c for c in wave['channels'] if c['target']==dict(node=names[name],path='rotation'))
        sampler=wave['samplers'][channel['sampler']]
        q=accessor(g,blob,sampler['output'])
        axis=np.array(g['nodes'][names[child]]['translation']);axis/=np.linalg.norm(axis)
        half=np.deg2rad(roll*amount)/2
        result=multiply(q,np.r_[axis*np.sin(half),np.cos(half)]).astype('<f4')
        blob.extend(b'\0'*(-len(blob)%4));vi=len(g['bufferViews'])
        g['bufferViews'].append(dict(buffer=0,byteOffset=len(blob),byteLength=result.nbytes));blob.extend(result.tobytes())
        ai=len(g['accessors']);g['accessors'].append(dict(bufferView=vi,componentType=5126,count=len(q),type='VEC4'))
        sampler['output']=ai
    g.setdefault('extras',{})['wavePalmRefinement']=dict(version=1,rollDegrees=roll,forearmShare=.72,wristShare=.28)
    g['buffers'][0]['byteLength']=len(blob);js=json.dumps(g,separators=(',',':')).encode();js+=b' '*(-len(js)%4);blob+=b'\0'*(-len(blob)%4)
    Path(dest).write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob)
    print(g['extras']['wavePalmRefinement'])


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('source');p.add_argument('destination');p.add_argument('--roll',type=float,default=80);a=p.parse_args()
    assert Path(a.source).resolve()!=Path(a.destination).resolve()
    refine(a.source,a.destination,a.roll)
