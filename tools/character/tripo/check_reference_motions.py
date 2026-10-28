"""Preservation, loops, prop isolation, pose deformation and transition checks."""
import argparse
import json
import tempfile
from pathlib import Path
import numpy as np
from check_wave import read,write_diagnostic
from validate_deformation import Rig,prepare_regions,slerp
from build_reference_motions import REFERENCE


def validate(source,destination,report):
    old,ob=read(source);new,nb=read(destination)
    assert nb[:len(ob)]==ob,'Original mesh payload changed'
    for key in ['meshes','materials','accessors','bufferViews']:
        assert new[key][:len(old[key])]==old[key],key
    assert new['skins']==old['skins'] and new['images']==old['images']
    for i,n in enumerate(old['nodes']):
        candidate=dict(new['nodes'][i])
        if n.get('name') in ['Armature','LeftHand']:
            added=candidate.get('children',[])[len(n.get('children',[])):]
            assert all(new['nodes'][child]['name'] in new['extras']['referenceMotions']['props'] for child in added)
            candidate['children']=candidate['children'][:len(n.get('children',[]))]
        assert candidate==n, n.get('name')
    assert len(new['animations'])==20
    assert set(REFERENCE)<=set(a['name'] for a in new['animations'])
    for original in old['animations']:
        if original['name'] in REFERENCE:continue
        candidate=next(a for a in new['animations'] if a['name']==original['name'])
        assert candidate['channels'][:len(original['channels'])]==original['channels']
        assert candidate['samplers'][:len(original['samplers'])]==original['samplers']
        duration=lambda a:max(new['accessors'][s['input']]['max'][0] for s in a['samplers'])
        assert abs(duration(candidate)-duration(original))<1e-5,original['name']
    report=Path(report)
    with tempfile.TemporaryDirectory(dir=report.parent) as temp:
        path=Path(temp)/'rig.glb';write_diagnostic(path,new,nb);rig=Rig(path)
        body=next(p for p in rig.primitives if p['name']=='Body');regions=prepare_regions(rig,body)
        seam=0.;samples=0;loop_error=0.;max_stretch=0.
        def sample(pose):
            nonlocal seam,samples,max_stretch
            world=rig.world(pose)
            v=Rig.deform(body,world);assert np.isfinite(v).all()
            for prop in ['CupTrophy','StarTrophy']:
                node=rig.names[prop];hand=rig.names['LeftHand']
                assert rig.parents[node]==hand
                expected=world[hand]@np.r_[new['extras']['referenceMotions']['gripOffset'],1]
                assert np.linalg.norm(world[node,:3,3]-expected[:3])<1e-7,'Trophy detached from grip'
            assert np.abs(v).max()<1.5,'Unbounded deformation'
            seam=max(seam,float(np.linalg.norm(v-v[regions['representative']],axis=1).max()))
            edges=regions['edges'];ratio=np.linalg.norm(v[edges[:,0]]-v[edges[:,1]],axis=1)/regions['lengths']
            max_stretch=max(max_stretch,float(np.percentile(ratio,99)))
            samples+=1
        for name,channels in rig.clips.items():
            duration=max(c[2][-1] for c in channels)
            for node,path,times,values,_ in channels:
                assert np.isfinite(values).all()
                if path=='rotation':assert np.max(abs(np.linalg.norm(values,axis=1)-1))<1e-5
                if new['nodes'][node].get('name') in new['extras']['referenceMotions']['props'] and path=='scale':
                    expected={'StarTrophy':'WinCelebration','CupTrophy':'UltimateWin','ConfettiFX':'UltimateWin',
                              'CuriosityFX':'Curious','ConfusionFX':'Confused','SweatFX':'Nervous',
                              'ExcitementFX':'Excited','VictoryFX':'Victory'}[new['nodes'][node]['name']]
                    assert np.all(values==(1 if name==expected else 0))
            for t in np.linspace(0,duration,13):sample(rig.pose(name,t))
            start=Rig.deform(body,rig.world(rig.pose(name,0)));end=Rig.deform(body,rig.world(rig.pose(name,duration)))
            loop_error=max(loop_error,float(np.linalg.norm(start-end,axis=1).max()))
        for i,name in enumerate(REFERENCE):
            following=REFERENCE[(i+1)%len(REFERENCE)]
            for f in np.linspace(0,1,9):
                a,b=rig.pose(name,.7*f),rig.pose(following,.7*f)
                sample(((1-f)*a[0]+f*b[0],slerp(a[1],b[1],f),(1-f)*a[2]+f*b[2]))
        assert loop_error<1e-5,loop_error
        assert seam<1e-5,seam
    result=dict(clips=20,referenceStates=len(REFERENCE),samples=samples,geometryPreserved=True,
        wavePreserved=True,oldClipDurationsPreserved=True,propsIsolated=True,
        loopDisplacement=loop_error,uvSeamSeparation=seam,stretchP99=max_stretch)
    report.write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('source');p.add_argument('candidate');p.add_argument('report');a=p.parse_args()
    validate(a.source,a.candidate,a.report)
