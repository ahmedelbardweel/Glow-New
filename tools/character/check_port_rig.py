"""Compare the expressive rig against the complete supplied rest surface.

Run: python tools/character/check_port_rig.py SOURCE.glb RIG.glb --report REPORT.json
This does not use Flutter or modify either model.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from pygltflib import GLTF2
from rig_port_frontal import read_accessor


def matrix(node, rotation=None):
    if node.matrix:
        return np.array(node.matrix).reshape(4, 4).T
    x, y, z, w = rotation if rotation is not None else (node.rotation or [0, 0, 0, 1])
    result = np.eye(4)
    result[:3, :3] = [[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                      [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                      [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]
    result[:3, :3] *= node.scale or [1, 1, 1]
    result[:3, 3] = node.translation or [0, 0, 0]
    return result


def world_matrices(gltf, rotations=None, translations=None):
    rotations = rotations or {}
    translations = translations or {}
    result = {}
    def visit(index, parent):
        local=matrix(gltf.nodes[index], rotations.get(index))
        if index in translations:
            local[:3,3]=translations[index]
        result[index] = parent @ local
        for child in gltf.nodes[index].children or []:
            visit(child, result[index])
    for index in gltf.scenes[gltf.scene or 0].nodes:
        visit(index, np.eye(4))
    return result


def positions(gltf):
    p = read_accessor(gltf, gltf.meshes[0].primitives[0].attributes.POSITION)
    return np.c_[p, np.ones(len(p))] @ world_matrices(gltf)[0].T


def sample_rotation(times, values, time):
    index = min(max(0, np.searchsorted(times, time, side='right')-1), len(times)-2)
    t = np.clip((time-times[index])/(times[index+1]-times[index]), 0, 1)
    a, b = values[index].astype(float), values[index+1].astype(float)
    dot = np.dot(a, b)
    if dot < 0:
        b = -b
        dot = -dot
    if dot > .9995:
        value = (1-t)*a+t*b
    else:
        angle = np.arccos(np.clip(dot, -1, 1))
        value = (np.sin((1-t)*angle)*a+np.sin(t*angle)*b)/np.sin(angle)
    return value/np.linalg.norm(value)


class PoseEvaluator:
    def __init__(self, gltf, primitive=0, mesh=0):
        self.gltf = gltf
        attrs = gltf.meshes[mesh].primitives[primitive].attributes
        points=read_accessor(gltf,attrs.POSITION)
        self.rest = np.c_[points,np.ones(len(points))]
        self.joints = read_accessor(gltf, attrs.JOINTS_0).astype(int)
        self.weights = read_accessor(gltf, attrs.WEIGHTS_0).astype(float)
        self.skin = gltf.skins[0]
        self.binds = read_accessor(gltf, self.skin.inverseBindMatrices).reshape(-1, 4, 4).transpose(0, 2, 1)
        self.tracks = {}
        for anim in gltf.animations:
            self.tracks[anim.name] = [(ch.target.node, ch.target.path,
                read_accessor(gltf, anim.samplers[ch.sampler].input).ravel(),
                read_accessor(gltf, anim.samplers[ch.sampler].output)) for ch in anim.channels]

    def rotations(self, clip, time):
        channels={}
        for node,path,times,values in self.tracks.get(clip,[]):
            if path=='rotation':
                channels[node,path]=sample_rotation(times,values,time)
            else:
                channels[node,path]=np.array([np.interp(time,times,values[:,axis]) for axis in range(3)])
        return channels

    def pose(self, clip=None, time=0, rotations=None):
        rotations = rotations if rotations is not None else self.rotations(clip, time)
        world = world_matrices(self.gltf,
            {node:value for (node,path),value in rotations.items() if path=='rotation'},
            {node:value for (node,path),value in rotations.items() if path=='translation'})
        transforms = np.array([world[node] @ inverse
                              for node, inverse in zip(self.skin.joints, self.binds)])
        posed = np.zeros_like(self.rest)
        for slot in range(4):
            moved = np.einsum('nij,nj->ni', transforms[self.joints[:, slot]], self.rest)
            posed += moved*self.weights[:, slot, None]
        return posed[:, :3]


def check(source_path, rig_path):
    source,rig=(GLTF2().load_binary(str(path)) for path in (source_path,rig_path))
    original=positions(source)[:,:3]
    rest=positions(rig)[:,:3]
    count=len(original)
    mouth=rig.extras['mouth']
    assert mouth['sourceVertexCount']==count
    max_error=float(np.abs(original-rest[:count]).max())
    assert max_error<6e-8
    a,b=source.meshes[0].primitives[0],rig.meshes[0].primitives[0]
    for attribute in ('NORMAL','TEXCOORD_0'):
        src=read_accessor(source,getattr(a.attributes,attribute))
        dst=read_accessor(rig,getattr(b.attributes,attribute))
        assert np.array_equal(src,dst[:count]),attribute
    original_uv=read_accessor(source,a.attributes.TEXCOORD_0)
    new_uv=read_accessor(rig,b.attributes.TEXCOORD_0)
    records=mouth['surfaceVertexSources']
    assert len(records)==len(rest)-count
    for vertex,record in enumerate(records,count):
        ids=record['indices'];coeff=np.array(record['weights'])
        assert (coeff>=-1e-8).all() and abs(coeff.sum()-1)<1e-7
        assert np.max(np.abs(coeff@original[ids]-rest[vertex]))<6e-8
        assert np.max(np.abs(coeff@original_uv[ids]-new_uv[vertex]))<1e-7
    triangles=read_accessor(rig,b.indices).reshape(-1,3).astype(int)
    source_triangles=read_accessor(source,a.indices).reshape(-1,3).astype(int)
    parent=np.r_[np.arange(len(source_triangles)),mouth['addedTriangleSource']].astype(int)
    assert len(parent)==len(triangles)
    # Prove every output triangle stays inside its original triangle and that
    # the complete original surface area remains covered exactly once.
    # Compare subdivision in the exported float32 coordinate representation;
    # the source-to-float rounding is checked separately above.
    sp=rest[:count][source_triangles[parent]]
    out=rest[triangles]
    v0,v1=sp[:,1]-sp[:,0],sp[:,2]-sp[:,0]
    cross=np.cross(v0,v1)
    area=np.linalg.norm(cross,axis=1)
    valid=area>1e-10
    distances=np.abs(np.einsum('nij,nj->ni',out-sp[:,0,None,:],cross))
    assert np.max(distances[valid]/area[valid,None])<1e-7
    offset=out-sp[:,0,None,:]
    safe=np.where(valid,area*area,1)
    v=np.einsum('nij,nj->ni',np.cross(offset,v1[:,None,:]),cross)/safe[:,None]
    w=np.einsum('nij,nj->ni',np.cross(v0[:,None,:],offset),cross)/safe[:,None]
    assert min(v[valid].min(),w[valid].min(),(1-v-w)[valid].min())>-.002
    new_area=np.linalg.norm(np.cross(out[:,1]-out[:,0],out[:,2]-out[:,0]),axis=1)
    original_area=np.linalg.norm(np.cross(original[source_triangles[:,1]]-original[source_triangles[:,0]],
                                           original[source_triangles[:,2]]-original[source_triangles[:,0]]),axis=1)
    area_error=float(np.abs(np.bincount(parent,new_area,minlength=len(source_triangles))-original_area).max())
    assert area_error<2e-8
    assert source.materials[0].to_dict()==rig.materials[0].to_dict()
    assert [m.to_dict() for m in source.textures]==[m.to_dict() for m in rig.textures]
    assert [m.to_dict() for m in source.samplers]==[m.to_dict() for m in rig.samplers]
    image_hashes=[]
    assert len(source.images)==len(rig.images)
    for first,second in zip(source.images,rig.images):
        def payload(model,image):
            view=model.bufferViews[image.bufferView]
            return model.binary_blob()[view.byteOffset:view.byteOffset+view.byteLength]
        assert payload(source,first)==payload(rig,second)
        image_hashes.append(hashlib.sha256(payload(source,first)).hexdigest())
    evaluators=[PoseEvaluator(rig,index,mesh) for mesh,value in enumerate(rig.meshes) for index in range(len(value.primitives))]
    evaluator=evaluators[0]
    joints,weights=evaluator.joints,evaluator.weights
    for item in evaluators:
        assert np.isfinite(item.weights).all() and item.weights.min()>=0
        assert np.max(np.abs(item.weights.sum(1)-1))<1e-7
        assert item.joints.max()<21 and item.joints.min()>=0
        assert np.all(item.joints[item.weights==0]==0)
        assert np.max(np.abs(item.pose()-item.rest[:,:3]))<1e-7
    _,representatives,inverse=np.unique(rest[:count],axis=0,return_index=True,return_inverse=True)
    assert np.array_equal(joints[:count],joints[representatives][inverse])
    assert np.array_equal(weights[:count],weights[representatives][inverse])
    root_only=((joints==0)|(weights==0)).all(axis=1)
    x,y,z=rest.T
    palette=read_accessor(rig,getattr(b.attributes,'_GLOW_SKIN_REGION')).ravel()
    assert len(palette)==len(rest) and np.isfinite(palette).all()
    assert palette.min()>=0 and palette.max()<=1
    assert np.array_equal(palette[:count],palette[representatives][inverse])
    eye_centers=(((np.abs(x)-.106)/.047)**2+((y-.606)/.057)**2<.80)&(z>.205)
    assert eye_centers.any() and np.max(palette[eye_centers])==0
    assert np.min(palette[y<.54])==1
    old_protected=((y>=.432)|((np.abs(x)<=.145)&(y>=.154))|(z<=-.155)|((z>=.116)&(y>=.154)))
    face_region=(y>.433)&(y<.539)&(np.abs(x)<.170)&(z>.163)
    eye_region=(y>.556)&(y<.657)&(np.abs(x)>.065)&(np.abs(x)<.185)&(z>.195)
    assert root_only[old_protected&~face_region&~eye_region].all(),'Facial influence escaped its local region'
    face_weights=((joints>=16)&(joints<19)&(weights>0)).any(axis=1)
    assert face_region[face_weights].all()
    eye_weights=((joints>=19)&(weights>0)).any(axis=1)
    assert eye_region[eye_weights].all()
    assert len(rig.skins)==1 and len(rig.skins[0].joints)==21
    expected={'Idle','Talk','Wave','Happy','Sad','Thinking','Victory','Walk','Smile','Laugh'}
    assert {a.name for a in rig.animations}==expected
    limb_nodes=set(rig.skins[0].joints[4:16])
    nodes={node.name:index for index,node in enumerate(rig.nodes)}
    permitted={(node,'rotation') for node in limb_nodes|{nodes['EyeLeft'],nodes['EyeRight']}}|{
        (nodes['Jaw'],'rotation'),(nodes['MouthCornerLeft'],'translation'),(nodes['MouthCornerRight'],'translation')}
    edges=np.unique(np.sort(np.concatenate([triangles[:,(0,1)],triangles[:,(1,2)],triangles[:,(2,0)]]),axis=1),axis=0)
    length=np.linalg.norm(rest[edges[:,0]]-rest[edges[:,1]],axis=1)
    selected=(~root_only[edges].all(1))&(length>.001)
    edges,length=edges[selected],length[selected]
    upper=np.array(mouth['lipUpperIndices']);lower=np.array(mouth['lipLowerIndices'])
    assert np.max(np.abs(rest[upper]-rest[lower]))<1e-7
    clips=[]
    for animation in rig.animations:
        assert {(ch.target.node,ch.target.path) for ch in animation.channels}==permitted
        tracks=evaluator.tracks[animation.name]
        for _,path,times,values in tracks:
            assert np.isfinite(values).all() and np.all(np.diff(times)>0)
            assert np.max(np.abs(values[0]-values[-1]))<1e-6
            if path=='rotation':
                assert np.max(np.abs(np.linalg.norm(values,axis=1)-1))<2e-7
        duration=float(tracks[0][2][-1])
        stretch=0.;seam=0.;fixed=0.;gap=0.;displacement=0.
        for time in np.linspace(0,duration,25):
            channels=evaluator.rotations(animation.name,time)
            posed=evaluator.pose(rotations=channels)
            for item in evaluators[1:]:
                assert np.isfinite(item.pose(rotations=channels)).all()
            fixed=max(fixed,float(np.abs(posed[root_only]-rest[root_only]).max()))
            seam=max(seam,float(np.abs(posed[:count]-posed[representatives][inverse]).max()))
            gap=max(gap,float(np.linalg.norm(posed[upper]-posed[lower],axis=1).max()))
            displacement=max(displacement,float(np.linalg.norm(posed-rest,axis=1).max()))
            ratio=np.linalg.norm(posed[edges[:,0]]-posed[edges[:,1]],axis=1)/length
            stretch=max(stretch,float(ratio.max()))
        assert fixed==0 and seam==0
        assert stretch<3.05,f'{animation.name}: excessive surface strain {stretch}'
        if animation.name in ('Idle','Smile','Sad'):
            assert gap<1e-7,'Closed lips separated'
        if animation.name in ('Happy','Laugh','Talk'):
            assert gap>.012,'Jaw did not open the lips'
        if animation.name=='Idle':
            assert displacement<1e-7
        clips.append(dict(name=animation.name,sampledFrames=25,staticDisplacement=fixed,
                          sourceUvSeamSeparation=seam,maxLipOpening=gap,maxEdgeStretch=stretch))
    transition_frames=0
    for first in rig.animations:
        for second in rig.animations:
            if first.name==second.name:continue
            a=evaluator.rotations(first.name,evaluator.tracks[first.name][0][2][-1]*.23)
            b=evaluator.rotations(second.name,evaluator.tracks[second.name][0][2][-1]*.61)
            for alpha in (.25,.5,.75):
                mixed={key:(sample_rotation(np.array([0.,1.]),np.array([a[key],b[key]]),alpha)
                            if key[1]=='rotation' else (1-alpha)*a[key]+alpha*b[key]) for key in permitted}
                posed=evaluator.pose(rotations=mixed)
                assert np.isfinite(posed).all()
                assert np.array_equal(posed[root_only],rest[root_only])
                assert np.array_equal(posed[:count],posed[representatives][inverse])
                transition_frames+=1
    return dict(source=str(source_path),rig=str(rig_path),
                sourceSha256=hashlib.sha256(source_path.read_bytes()).hexdigest(),
                rigSha256=hashlib.sha256(rig_path.read_bytes()).hexdigest(),
                originalVertices=count,originalTriangles=len(source_triangles),
                originalSurfaceVerticesRetained=True,sourceTextureBytesIdentical=True,
                originalNormalsAndUvsIdentical=True,sourceMaterialIdentical=True,
                insertedLipVertices=len(rest)-count,refinedSurfaceTriangles=len(triangles),
                maxOriginalPositionError=max_error,maxSurfaceAreaError=area_error,
                bones=21,primitiveCount=len(evaluators),textureSha256=image_hashes,
                eyeSurfaceVertices=int(eye_weights.sum()),
                skinPaletteAttribute=True,protectedEyeVertices=int(eye_centers.sum()),
                staticSurfaceVertices=int(root_only.sum()),facialSurfaceVertices=int(face_weights.sum()),
                transitionFrames=transition_frames,clips=clips)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('rig', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    report = check(args.source, args.rig)
    encoded = json.dumps(report, indent=2, ensure_ascii=False)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_bytes((encoded+'\n').encode('utf-8'))
    print(json.dumps(report, indent=2))
