"""Assert that only Glasses changed and its replacement is closed and rigid."""
import argparse
import json
import numpy as np
from validate_deformation import Rig


def check(source, destination):
    before,after=Rig(source),Rig(destination)
    bg,ag=before.doc,after.doc
    frame=before.nodes[before.names['Glasses']]['mesh']
    for key in ('nodes','skins','animations','materials','textures','images','samplers','scenes'):
        assert bg.get(key)==ag.get(key),f'{key} changed'
    assert len(bg['meshes'])==len(ag['meshes'])
    for i,mesh in enumerate(bg['meshes']):
        if i!=frame:assert ag['meshes'][i]==mesh,f'Unrelated mesh {i} changed'
    assert ag['accessors'][:len(bg['accessors'])]==bg['accessors']
    assert ag['bufferViews'][:len(bg['bufferViews'])]==bg['bufferViews']
    assert after.binary[:len(before.binary)]==before.binary,'Existing geometry/texture/morph bytes changed'
    p=next(p for p in after.primitives if p['name']=='Glasses')
    primitive=ag['meshes'][frame]['primitives'][0]
    assert primitive['material']==ag['extras']['frameRefinement']['originalMaterial']
    n=after.accessor(primitive['attributes']['NORMAL'])
    assert np.isfinite(p['vertices']).all() and np.isfinite(n).all()
    assert abs(np.linalg.norm(n,axis=1)-1).max()<1e-5
    assert (p['weights'][:,0]==1).all() and (p['weights'][:,1:]==0).all()
    assert np.all(p['joint_nodes'][p['joints'][:,0]]==after.names['Head'])
    v=p['vertices'];f=p['faces']
    if ag['extras']['frameRefinement']['version'] >= 2:
        # Tube rings are first in the primitive. Check their actual centers,
        # not just metadata, against the fixed white-eye silhouette.
        for index,side in enumerate((1,-1)):
            centers=v[index*3840:(index+1)*3840].reshape(192,20,3).mean(1)
            axes=np.ptp(centers[:,:2],axis=0)/2
            assert np.allclose(axes,[.0615,.0655],atol=1e-6)
            assert axes[1]/axes[0]<1.07,'Rim is too elongated'
            assert abs(centers[:,1].min()+.0064-(.608-.065))<.006
            assert np.allclose(centers[:,:2].mean(0),[side*.125,.608],atol=1e-6)
    geometric=np.cross(v[f[:,1]]-v[f[:,0]],v[f[:,2]]-v[f[:,0]])
    assert (np.linalg.norm(geometric,axis=1)>1e-10).all(),'Degenerate frame faces'
    assert ((geometric*n[f].mean(1)).sum(1)>0).all(),'Inverted frame faces'
    _,inv=np.unique(v,axis=0,return_inverse=True)
    wf=inv[f];edges=np.concatenate([wf[:,[0,1]],wf[:,[1,2]],wf[:,[2,0]]])
    _,counts=np.unique(np.sort(edges,axis=1),axis=0,return_counts=True)
    assert (counts==2).all(),'Frame has open or nonmanifold tube edges'
    drift=0;poses=0
    for clip,channels in after.clips.items():
        duration=max(float(c[2][-1]) for c in channels)
        for time in np.linspace(0,duration,9):
            world=after.world(after.pose(clip,time))
            posed=Rig.deform(p,world)
            m=world[after.names['Head']]@np.linalg.inv(after.rest_world[after.names['Head']])
            expected=v@m[:3,:3].T+m[:3,3]
            drift=max(drift,float(np.linalg.norm(expected-posed,axis=1).max()));poses+=1
    assert drift<1e-6
    return dict(onlyGlassesChanged=True,originalMaterialRestored=True,existingBinaryBytesPreserved=len(before.binary),closedTubeEdges=True,vertices=len(v),triangles=len(f),poses=poses,maxHeadAttachmentDrift=drift)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('before');parser.add_argument('after');parser.add_argument('--output')
    args=parser.parse_args();report=json.dumps(check(args.before,args.after),indent=2)
    if args.output:
        from pathlib import Path
        Path(args.output).write_text(report+'\n',encoding='utf-8')
    print(report)
