"""Regression checks for eye isolation, gaze extremes and lid continuity."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import numpy as np
from pygltflib import GLTF2
from rig_port_frontal import read_accessor, quat
from check_port_rig import PoseEvaluator


def check_eyes(path):
    model=GLTF2().load_binary(str(path))
    evaluator=PoseEvaluator(model)
    p=evaluator.rest[:,:3]
    neutral=evaluator.pose()
    eye=((evaluator.joints>=19)&(evaluator.weights>0)).any(1)
    names={node.name:index for index,node in enumerate(model.nodes)}
    _,first,inverse=np.unique(p,axis=0,return_index=True,return_inverse=True)
    maximum=0.
    for x in (-.10,0.,.10):
        for y in (-.08,0.,.08):
            channels={(names[name],'rotation'):quat(y,x,0) for name in ('EyeLeft','EyeRight')}
            posed=evaluator.pose(rotations=channels)
            assert np.array_equal(posed[~eye],neutral[~eye]), 'Gaze moved face/glasses/body'
            assert np.max(np.abs(posed-posed[first][inverse]))<1e-7, 'Eye UV seam opened'
            maximum=max(maximum,float(np.linalg.norm(posed-p,axis=1).max()))
    assert .004<maximum<.014
    primitive=next(mesh for mesh in model.meshes if mesh.name=='EyeLids').primitives[0]
    rest=read_accessor(model,primitive.attributes.POSITION)
    triangles=read_accessor(model,primitive.indices).reshape(-1,3)
    # Fully open lids collapse to the perimeter and cover no original detail.
    area=np.linalg.norm(np.cross(rest[triangles[:,1]]-rest[triangles[:,0]],
                                  rest[triangles[:,2]]-rest[triangles[:,0]]),axis=1)
    assert area.max()==0
    targets=[read_accessor(model,target['POSITION']) for target in primitive.targets]
    assert len(targets)==4 and all(np.isfinite(target).all() for target in targets)
    for close in np.linspace(0,1,41):
        weights=[min(2*close,2-2*close),max(0,2*close-1)]*2
        posed=rest+sum(target*weight for target,weight in zip(targets,weights))
        assert np.isfinite(posed).all()
        if close==1:
            # Two eyes, two lids each, nine rows and 41 columns.
            rows=posed.reshape(2,2,9,41,3)
            assert np.max(np.abs(rows[:,0,-1]-rows[:,1,-1]))<1e-7
    return dict(gazePoses=9,blinkPoses=41,eyeSurfaceVertices=int(eye.sum()),
                maxGazeDisplacement=maximum,protectedSurfaceDisplacement=0,
                fullClosureSeamGap=0,openLidArea=0,lidVertices=len(rest),
                lidTriangles=len(triangles))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('rig',type=Path)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    result=json.dumps(check_eyes(args.rig),indent=2)+'\n'
    if args.report:args.report.write_bytes(result.encode('utf-8'))
    print(result)
