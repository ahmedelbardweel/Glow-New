"""Split triangles along the lip contour, keeping the source rest surface.

Inserted points are barycentric samples of existing triangles. Original
vertices and textures are retained; UV seams are refined on both sides.
"""
from __future__ import annotations
import numpy as np


def split_lips(p,n,uv,triangles):
    triangles=triangles.reshape(-1,3).astype(int)
    unique,inverse=np.unique(p,axis=0,return_inverse=True)
    f=p[:,1]-(.4855+1.60*p[:,0]**2)
    face_p=p[triangles]
    cut=((f[triangles].min(1)<0)&(f[triangles].max(1)>0)
         &(face_p[:,:,2].min(1)>.185)&(np.abs(face_p[:,:,0].mean(1))<.122))
    segments={};edge_points={};adjacent={}
    for fi in np.flatnonzero(cut):
        ids=triangles[fi];crossed=[]
        for i,j in ((0,1),(1,2),(2,0)):
            a,b=int(ids[i]),int(ids[j])
            if f[a]*f[b]>=0:
                continue
            key=tuple(sorted((int(inverse[a]),int(inverse[b]))))
            if key not in edge_points:
                aa,bb=unique[list(key)]
                fa=aa[1]-(.4855+1.60*aa[0]**2)
                fb=bb[1]-(.4855+1.60*bb[0]**2)
                t=fa/(fa-fb)
                edge_points[key]=(aa*(1-t)+bb*t).astype(np.float32)
            crossed.append(key)
        if len(crossed)!=2:
            raise ValueError('Invalid contour crossing')
        segments[fi]=crossed
        a,b=crossed
        adjacent.setdefault(a,set()).add(b);adjacent.setdefault(b,set()).add(a)
    center=min(edge_points,key=lambda key: abs(edge_points[key][0])+abs(edge_points[key][2]-.275))
    component={center};pending=[center]
    while pending:
        for key in adjacent[pending.pop()]-component:
            component.add(key);pending.append(key)
    ends=[key for key in component if len(adjacent[key])==1]
    if len(ends)!=2 or any(len(adjacent[key])>2 for key in component):
        raise ValueError('Mouth contour must be one open manifold chain')
    start=min(ends,key=lambda key:edge_points[key][0])
    path=[start]
    while True:
        options=adjacent[path[-1]]-set(path)
        if not options:break
        path.append(next(iter(options)))
    cut_faces={fi for fi,pair in segments.items() if pair[0] in component}
    pp=list(p);nn=list(n);uu=list(uv)
    # Each added vertex carries source barycentrics for independent QA.
    provenance=[];edge_cache={};lower_cache={};upper_by_key={};lower_by_key={}
    source_n=len(p)
    def add(ids,coeff,position=None):
        coeff=np.array(coeff,dtype=float)
        new_p=(coeff@p[ids]).astype(np.float32) if position is None else position.copy()
        normal=coeff@n[ids];normal/=max(np.linalg.norm(normal),1e-10)
        idx=len(pp);pp.append(new_p);nn.append(normal.astype(np.float32));uu.append((coeff@uv[ids]).astype(np.float32))
        provenance.append({'indices':[int(i) for i in ids],'weights':coeff.tolist()})
        return idx
    def edge(a,b,lower=False):
        cache_key=tuple(sorted((int(a),int(b))))
        key=tuple(sorted((int(inverse[a]),int(inverse[b]))))
        if cache_key not in edge_cache:
            a,b=cache_key;t=float(f[a]/(f[a]-f[b]))
            edge_cache[cache_key]=add([a,b],[1-t,t],edge_points[key])
            upper_by_key.setdefault(key,edge_cache[cache_key])
        upper=edge_cache[cache_key]
        if not lower:return upper
        if upper not in lower_cache:
            idx=len(pp);pp.append(pp[upper].copy());nn.append(nn[upper].copy());uu.append(uu[upper].copy())
            provenance.append(dict(provenance[upper-source_n]))
            lower_cache[upper]=idx
            lower_by_key.setdefault(key,idx)
        return lower_cache[upper]
    def clip(ids,positive):
        output=[]
        for i in range(3):
            a,b=int(ids[i]),int(ids[(i+1)%3])
            inside_a=f[a]>=0 if positive else f[a]<=0
            if inside_a:output.append(a)
            if f[a]*f[b]<0:output.append(edge(a,b,not positive))
        return output
    output=triangles.tolist();extra_sources=[]
    for fi,ids in enumerate(triangles):
        if fi in cut_faces:
            polygons=[clip(ids,True),clip(ids,False)]
        else:
            # Refine neighbouring faces too, eliminating T junctions at both
            # closed contour endpoints and across original UV boundaries.
            polygon=[]
            for i in range(3):
                a,b=int(ids[i]),int(ids[(i+1)%3]);polygon.append(a)
                key=tuple(sorted((int(inverse[a]),int(inverse[b]))))
                if key in component:polygon.append(edge(a,b))
            if len(polygon)==3:continue
            polygons=[polygon]
        children=[]
        for poly in polygons:
            # A fan from an original polygon corner with non-collinear
            # adjacent edges retains all boundary subdivision vertices.
            if len(poly)==3:
                children.append(poly);continue
            # Use a barycentric interior sample to avoid collinear fan ears.
            coeff=np.zeros(3)
            for vertex in poly:
                if vertex<source_n:
                    coeff[np.flatnonzero(ids==vertex)[0]]+=1/len(poly)
                else:
                    record=provenance[vertex-source_n]
                    for original,value in zip(record['indices'],record['weights']):
                        coeff[np.flatnonzero(ids==original)[0]]+=value/len(poly)
            center_id=add(ids,coeff)
            for i in range(len(poly)):
                children.append([center_id,poly[i],poly[(i+1)%len(poly)]])
        output[fi]=children[0]
        output.extend(children[1:]);extra_sources.extend([int(fi)]*(len(children)-1))
    # Force creation of both boundary representatives, including endpoints.
    upper=np.array([upper_by_key[key] for key in path])
    lower=np.array([lower_by_key.get(key,upper_by_key[key]) for key in path])
    return dict(positions=np.array(pp,np.float32),normals=np.array(nn,np.float32),uvs=np.array(uu,np.float32),
                indices=np.array(output,np.uint16),upper=upper,lower=lower,
                lowerCopies=np.array(list(lower_cache.values())),
                upperCopies=np.array(list(lower_cache)),
                surfaceVertexSources=provenance,addedTriangleSource=extra_sources,
                lipPathPositions=[edge_points[key].tolist() for key in path])
