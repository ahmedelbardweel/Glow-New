"""Add the reference sheet's acting poses to the completed mouth/head model.

All clips key the same skeleton/prop bindings so interrupted blends never leave
an arm or trophy behind. Geometry, rig, UVs and the approved Wave are retained.
Uses analytical two-bone IK for hand placement, and only NumPy for generation.
"""
import argparse
import copy
import json
import math
import struct
from pathlib import Path
import numpy as np
from check_wave import read
from frame_math import Rotation

REFERENCE = ['PowerPose', 'Neutral', 'Victory', 'Happy', 'Laugh', 'Excited',
             'Curious', 'Encourage', 'WinCelebration', 'Frustrated', 'Nervous',
             'Confused', 'UltimateWin']


def unit(v):
    return v / max(np.linalg.norm(v), 1e-10)


def multiply(a, b):
    return np.r_[a[3]*b[:3]+b[3]*a[:3]+np.cross(a[:3], b[:3]),
                 a[3]*b[3]-a[:3]@b[:3]]


def inverse(q):
    return q*np.array([-1, -1, -1, 1])


def matrix(q):
    return Rotation.from_quat(np.asarray(q)[None]).as_matrix()[0]


def quat(x=0, y=0, z=0):
    x, y, z = np.radians([x, y, z])/2
    sx, sy, sz = np.sin([x, y, z]); cx, cy, cz = np.cos([x, y, z])
    return np.array([sx*cy*cz-cx*sy*sz, cx*sy*cz+sx*cy*sz,
                     cx*cy*sz-sx*sy*cz, cx*cy*cz+sx*sy*sz])


def between(a, b):
    a, b = unit(a), unit(b)
    q = np.r_[np.cross(a, b), 1+a@b]
    if np.linalg.norm(q) < 1e-7:
        return np.r_[unit(np.cross(a, [0, 0, 1])), 0]
    return unit(q)


class Builder:
    def __init__(self, source):
        self.g, binary = read(source)
        self.blob = bytearray(binary)
        self.names = {n.get('name'): i for i, n in enumerate(self.g['nodes'])}
        self.original_nodes = len(self.g['nodes'])
        self.props = {}
        self.particles = []
        self.grip_offset = None

    def acc(self, data, kind='VEC3', component=5126, target=None):
        data = np.asarray(data, dtype={5126:'<f4', 5125:'<u4'}[component])
        self.blob.extend(b'\0'*(-len(self.blob)%4))
        view = dict(buffer=0, byteOffset=len(self.blob), byteLength=data.nbytes)
        if target: view['target'] = target
        vi = len(self.g['bufferViews']); self.g['bufferViews'].append(view)
        self.blob.extend(data.tobytes())
        ai = len(self.g['accessors'])
        self.g['accessors'].append(dict(bufferView=vi, componentType=component,
            count=len(data), type=kind, min=data.reshape(len(data), -1).min(0).tolist(),
            max=data.reshape(len(data), -1).max(0).tolist()))
        return ai

    def node(self, name, parent, **values):
        i = len(self.g['nodes'])
        self.g['nodes'].append(dict(name=name, **values))
        self.g['nodes'][parent].setdefault('children', []).append(i)
        return i

    def material(self, name, color, metal=0, glow=0):
        i = len(self.g['materials'])
        self.g['materials'].append(dict(name=name, pbrMetallicRoughness=dict(
            baseColorFactor=[*color, 1], metallicFactor=metal, roughnessFactor=.32),
            emissiveFactor=[c*glow for c in color], doubleSided=True))
        return i

    def mesh(self, name, parent, vertices, faces, material, **transform):
        v, f = np.asarray(vertices, float), np.asarray(faces, int)
        n = np.zeros_like(v)
        cross = np.cross(v[f[:,1]]-v[f[:,0]], v[f[:,2]]-v[f[:,0]])
        for j in range(3): np.add.at(n, f[:,j], cross)
        lens = np.linalg.norm(n, axis=1)
        n[lens<1e-10] = [0,1,0]; n /= np.linalg.norm(n, axis=1)[:,None]
        m = len(self.g['meshes'])
        self.g['meshes'].append(dict(name=name, primitives=[dict(
            attributes=dict(POSITION=self.acc(v, target=34962), NORMAL=self.acc(n, target=34962)),
            indices=self.acc(f.ravel(), 'SCALAR', 5125, 34963), material=material)]))
        return self.node(name, parent, mesh=m, **transform)

    def lathe(self, name, parent, profile, material, **transform):
        v = [[r*math.cos(a), y, r*math.sin(a)] for r,y in profile for a in np.linspace(0,2*math.pi,48,endpoint=False)]
        f = []
        for j in range(len(profile)-1):
            for k in range(48):
                a=j*48+k;b=j*48+(k+1)%48;c=a+48;d=b+48
                f += [[a,c,b],[b,c,d]]
        return self.mesh(name,parent,v,f,material,**transform)

    def sphere(self, name, parent, material, position, scale):
        # A shared closed lathe avoids duplicated zero-area polar triangles.
        profile = [(max(.00001,math.sin(t)),math.cos(t)) for t in np.linspace(math.pi,0,17)]
        return self.lathe(name,parent,profile,material,translation=list(position),scale=list(scale))

    def box(self, name, parent, material, position, scale):
        v = [[x,y,z] for x in [-.5,.5] for y in [-.5,.5] for z in [-.5,.5]]
        f = [[0,1,3],[0,3,2],[4,6,7],[4,7,5],[0,4,5],[0,5,1],
             [2,3,7],[2,7,6],[0,2,6],[0,6,4],[1,5,7],[1,7,3]]
        return self.mesh(name,parent,v,f,material,translation=list(position),scale=list(scale))

    def tube(self,name,parent,points,radius,material):
        points=np.asarray(points);v=[];f=[]
        for j,p in enumerate(points):
            direction=unit(points[min(j+1,len(points)-1)]-points[max(j-1,0)])
            u=unit(np.cross(direction,[0,0,1]));w=np.cross(direction,u)
            v.extend([p+radius*(math.cos(a)*u+math.sin(a)*w) for a in np.linspace(0,2*math.pi,10,endpoint=False)])
        for j in range(len(points)-1):
            for k in range(10):
                a=j*10+k;b=j*10+(k+1)%10;c=a+10;d=b+10
                f.extend([[a,b,c],[b,d,c]])
        return self.mesh(name,parent,v,f,material)

    def star(self,name,parent,material,position,size):
        outline=[[math.sin(a)*r,math.cos(a)*r] for a,r in zip(np.arange(10)*math.pi/5,[1,.46]*5)]
        v=[[0,0,-.14],[0,0,.14]]+[[x,y,z] for z in [-.10,.10] for x,y in outline]
        f=[]
        for k in range(10):
            a=2+k;b=2+(k+1)%10;c=a+10;d=b+10
            f.extend([[0,b,a],[1,c,d],[a,b,c],[b,d,c]])
        return self.mesh(name,parent,v,f,material,translation=list(position),scale=[size]*3)

    def make_props(self):
        gold=self.material('CelebrationGold',[1,.57,.045],.58,.08)
        dark=self.material('TrophyBase',[.10,.07,.035],.25)
        blue=self.material('ThoughtBlue',[.24,.57,.85],.12,.06)
        white=self.material('ThoughtPearl',[.82,.92,1],.1)
        paper=self.material('BookPages',[.90,.78,.55])
        leather=self.material('BookCover',[.24,.065,.035])
        colors=[gold,blue,self.material('ConfettiCoral',[.95,.17,.22]),self.material('ConfettiMint',[.12,.8,.52])]
        for name in ['StarTrophy','CupTrophy','ExcitementFX','CuriosityFX','ConfusionFX','SweatFX','VictoryFX','ConfettiFX']:
            parent=self.names['LeftHand'] if name in ['StarTrophy','CupTrophy'] else self.names['Armature']
            self.props[name]=self.node(name,parent,scale=[0,0,0])
        q,t,_=self.pose('UltimateWin',.25)
        _,rotations=self.world(q,t)
        self.grip_offset=matrix(rotations[self.names['LeftHand']]).T@np.array([.02,.015,.018])
        for name in ['StarTrophy','CupTrophy']:
            p=self.props[name]
            self.box(name+'Foot',p,dark,[0,-.026,0],[.078,.023,.052])
            self.lathe(name+'Stem',p,[(.024,-.015),(.024,-.008),(.008,0),(.008,.065),(.018,.073)],gold)
        self.star('TrophyStar',self.props['StarTrophy'],gold,[0,.13,0],.074)
        self.lathe('CupBowl',self.props['CupTrophy'],[(.013,.05),(.026,.065),(.046,.087),(.058,.13),(.06,.153),(.056,.158),(.05,.148),(.044,.11),(.028,.08),(.012,.075)],gold)
        for s in [-1,1]:
            self.tube('CupHandle',self.props['CupTrophy'],[[s*(.05+.035*math.sin(t)),.125+.04*math.cos(t),0] for t in np.linspace(0,math.pi,20)],.006,gold)
        for effect, count in [('ExcitementFX',10),('VictoryFX',7)]:
            for k in range(count):
                a=math.tau*k/count
                p=[.35*math.sin(a),.48+.25*math.cos(a),.10]
                n=self.star(effect+str(k),self.props[effect],gold,p,.014+(k%3)*.004)
                self.particles.append((n,effect,p,k))
        for effect in ['CuriosityFX','ConfusionFX']:
            p=self.props[effect]
            for k,s in enumerate([-1,1] if effect=='ConfusionFX' else [-1]):
                x=s*.24;y=.91+k*.03
                points=[[x+.026*math.cos(t),y+.026*math.sin(t),.08] for t in np.linspace(math.pi, -math.pi/2,22)]
                points += [[x,y-.047,.08]]
                self.tube('QuestionCurl',p,points,.006,blue)
                self.sphere('QuestionDot',p,blue,[x,y-.069,.08],[.007]*3)
            if effect=='CuriosityFX':
                for k,(x,y,r) in enumerate([(.18,.90,.032),(.21,.93,.041),(.255,.92,.036),(.215,.88,.03)]):
                    self.sphere('ThoughtCloud',p,white,[x,y,0],[r,r*.8,r*.5])
                for k in range(3):
                    self.box('Book',p,leather,[.33,.025+k*.034,.02],[.12,.032,.08])
                    self.box('Pages',p,paper,[.332,.025+k*.034,.026],[.112,.020,.077])
        for s in [-1,1]:
            self.sphere('SweatDrop',self.props['SweatFX'],blue,[s*.215,.62,.20],[.012,.025,.009])
        for k in range(24):
            a=k*2.39996;p=[math.sin(a)*(.24+.12*(k%3)/2),.22+(k%8)*.095,.11+.10*math.cos(a)]
            n=self.box('Confetti'+str(k),self.props['ConfettiFX'],colors[k%4],p,[.012,.025,.003])
            self.particles.append((n,'ConfettiFX',p,k))

    def world(self, q, t):
        positions={};rotations={}
        parents={c:i for i,n in enumerate(self.g['nodes']) for c in n.get('children',[])}
        def visit(i):
            if i in positions:return
            node=self.g['nodes'][i];parent=parents.get(i)
            local=np.array(node.get('translation',[0,0,0]),float)
            if i==self.names['Hips']:local=t
            qr=q.get(i,np.array(node.get('rotation',[0,0,0,1]),float))
            if parent is None:positions[i]=local;rotations[i]=qr
            else:
                visit(parent);positions[i]=positions[parent]+matrix(rotations[parent])@local
                rotations[i]=multiply(rotations[parent],qr)
        for i in range(self.original_nodes):visit(i)
        return positions,rotations

    def arm(self,q,t,side,target,pole):
        a,b,h=[self.names[side+n] for n in ['Arm','ForeArm','Hand']]
        positions,rotations=self.world(q,t)
        parent=self.names[side+'Shoulder'];start=positions[a]
        v1=np.array(self.g['nodes'][b]['translation']);v2=np.array(self.g['nodes'][h]['translation'])
        l1,l2=np.linalg.norm(v1),np.linalg.norm(v2)
        delta=np.asarray(target)-start;d=np.clip(np.linalg.norm(delta),abs(l1-l2)+.004,l1+l2-.003)
        axis=unit(delta);along=(l1*l1-l2*l2+d*d)/(2*d)
        bend=unit(np.asarray(pole)-start-axis*((np.asarray(pole)-start)@axis))
        elbow=start+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
        upper=between(v1,elbow-start)
        lower=multiply(between(matrix(upper)@v2,start+axis*d-elbow),upper)
        q[a]=multiply(inverse(rotations[parent]),upper)
        q[b]=multiply(inverse(upper),lower)
        q[h]=quat()

    def pose(self,name,u):
        s=math.sin(math.tau*u);c=math.cos(math.tau*u)
        q={i:quat() for i in range(29)}
        t=np.array(self.g['nodes'][self.names['Hips']]['translation'],float)
        def r(n,*e):q[self.names[n]]=quat(*e)
        r('LeftArm',0,0,-55);r('RightArm',0,0,55)
        r('LeftForeArm',0,0,-8);r('RightForeArm',0,0,8)
        r('Tail',0,4*s,0);r('Spine1',.7*s,0,0);r('Head',-.7*s,0,c)
        mouth=[0,.12,0,0]
        def hand(side,position,pole=None):
            sign=1 if side=='Left' else -1
            self.arm(q,t,side,np.array(position)+[0,t[1]-.2,0],pole or [sign*.35,.28,.10])
        def palm(side,euler):
            _,rotations=self.world(q,t)
            arm=self.names[side+'Arm'];fore=self.names[side+'ForeArm'];wrist=self.names[side+'Hand']
            current=rotations[fore];desired=quat(*euler)
            axis=unit(matrix(current)@np.array(self.g['nodes'][wrist]['translation']))
            difference=multiply(desired,inverse(current))
            if difference[3]<0:difference=-difference
            twist=unit(np.r_[axis*(difference[:3]@axis),difference[3]])
            angle=2*math.atan2(twist[:3]@axis,twist[3])*.65
            rolled=multiply(np.r_[axis*math.sin(angle/2),math.cos(angle/2)],current)
            q[fore]=multiply(inverse(rotations[arm]),rolled)
            q[wrist]=multiply(inverse(rolled),desired)
        if name=='PowerPose':
            for side,k in [('Left',1),('Right',-1)]:hand(side,[k*.19,.285,.12],[k*.38,.28,.02])
            r('Head',-3,3*s,0);mouth=[0,.40,0,0]
        elif name=='Neutral':
            # Stagger the forearms in height/depth and rest each hand farther
            # across the chest; wrists retain the forearm direction without a kink.
            hand('Right',[-.035,.310,.130],[-.34,.205,.10])
            hand('Left',[.035,.355,.170],[.34,.245,.12])
            r('Head',0,2*s,0)
        elif name=='Curious':
            r('Head',3,-7+3*s,-7)
            hand('Right',[-.105,.452,.20],[-.29,.32,.16]);hand('Left',[.155,.32,.15],[.33,.29,.08])
            mouth=[0,.04,0,.18]
        elif name=='Encourage':
            hand('Right',[-.265,.415+.006*s,.16],[-.32,.32,.05]);hand('Left',[.19,.28,.12],[.36,.27,.03])
            palm('Right',(0,90,0))
            r('Head',-2+2*s,0,-4);mouth=[.08,.75,0,0]
        elif name=='Confused':
            r('Head',0,8*s,8*c)
            hand('Left',[.28,.54+.004*s,.06],[.37,.45,.03]);hand('Right',[-.23,.23,.065])
            palm('Left',(0,0,104+4*s))
            mouth=[0,0,.25,.25]
        elif name=='Nervous':
            r('Head',6,4*s,1.5*math.sin(math.tau*3*u))
            hand('Right',[-.10,.435+.003*s,.207],[-.28,.32,.12])
            hand('Left',[.10,.435-.003*s,.207],[.28,.32,.12]);mouth=[.055,0,.65,.10]
        elif name=='Frustrated':
            r('Spine1',8,0,0);r('Head',13,2*s,0)
            r('LeftArm',-8,0,-68);r('RightArm',-8,0,68)
            mouth=[0,0,1,0]
        elif name=='Laugh':
            r('Spine1',-3+3*math.sin(math.tau*3*u),0,3)
            r('Head',-9+3*math.sin(math.tau*3*u),0,-5)
            hand('Left',[.30,.46,.10],[.37,.34,.03]);hand('Right',[-.09,.30,.20],[-.32,.26,.12])
            mouth=[.25+.5*(.5+.5*math.sin(math.tau*3*u)),.9,0,0]
        elif name in ['Victory','Happy','Excited','WinCelebration','UltimateWin']:
            bounce=(1-(math.cos(math.tau*2*u) if name=='Excited' else c))*.5
            if name in ['Happy','Excited','UltimateWin']:
                t[1]+=.018*bounce
                t[0]-=.006*bounce
                r('LeftUpLeg',-12*bounce,0,18*bounce);r('LeftLeg',-24*bounce,0,0)
                r('LeftFoot',16*bounce,0,-5*bounce)
            r('Head',-5,0,3*s);r('Spine1',-2,0,2*s)
            if name in ['Victory','Excited']:
                for side,k in [('Left',1),('Right',-1)]:
                    hand(side,[k*(.29+.01*s),.55+.012*c,.07],[k*.39,.43,.02])
            elif name=='Happy':
                hand('Left',[.31,.47+.015*s,.08],[.38,.36,.02]);hand('Right',[-.31,.48-.015*s,.08],[-.38,.36,.02])
            else:
                hand('Left',[.32,.53+.008*s,.09],[.40,.40,.01])
                hand('Right',[-.32,.43+.015*c,.10],[-.40,.34,.02])
            mouth=[.25 if name=='Victory' else .48,.9,0,0]
        return q,t,mouth

    def track(self,animation,node,path,times,values):
        values=np.array(values,float)
        if path=='rotation':
            values/=np.linalg.norm(values,axis=1)[:,None]
            for j in range(1,len(values)):
                if values[j-1]@values[j]<0:values[j]*=-1
        values[-1]=values[0]
        output=self.acc(values.ravel() if path=='weights' else values,
                        'SCALAR' if path=='weights' else 'VEC4' if path=='rotation' else 'VEC3')
        animation['channels'].append(dict(sampler=len(animation['samplers']),target=dict(node=node,path=path)))
        animation['samplers'].append(dict(input=times,output=output,interpolation='LINEAR'))

    def build(self,destination):
        self.make_props()
        # Preserve established clip order and authored tracks, except the three
        # celebration poses explicitly refined to match the new reference.
        old={a['name']:a for a in self.g['animations']}
        names=list(old)+[n for n in REFERENCE if n not in old]
        animations=[]
        for name in names:
            duration=4.0 if name in ['Neutral','PowerPose','Curious','Frustrated','Confused'] else 3.2
            if name not in REFERENCE:
                duration=max(self.g['accessors'][sampler['input']]['max'][0] for sampler in old[name]['samplers'])
            frames=81;u=np.linspace(0,1,frames);times=self.acc(u*duration,'SCALAR')
            a=dict(name=name,channels=[],samplers=[],extras=dict(loop=True,referencePose=True,durationSeconds=duration)) if name in REFERENCE else copy.deepcopy(old[name])
            existing={(ch['target']['node'],ch['target']['path']) for ch in a['channels']}
            poses=[self.pose(name,f) for f in u]
            for i in range(29):
                if (i,'rotation') not in existing:
                    self.track(a,i,'rotation',times,[p[0][i] if name in REFERENCE else quat() for p in poses])
            hips=self.names['Hips']
            if (hips,'translation') not in existing:
                self.track(a,hips,'translation',times,[p[1] for p in poses])
            if name in REFERENCE:
                for mesh in ['Body','ExpressiveMouth','MouthTeeth','MouthTongue']:
                    self.track(a,self.names[mesh],'weights',times,[p[2] for p in poses])
            active={'WinCelebration':['StarTrophy'],'UltimateWin':['CupTrophy','ConfettiFX'],
                    'Excited':['ExcitementFX'],'Victory':['VictoryFX'],'Curious':['CuriosityFX'],
                    'Confused':['ConfusionFX'],'Nervous':['SweatFX']}.get(name,[])
            hand_orientations=[multiply(inverse(self.world(q,t)[1][self.names['LeftHand']]),quat(0,0,3*math.sin(math.tau*f))) for f,(q,t,_) in zip(u,poses)]
            for prop,i in self.props.items():
                self.track(a,i,'scale',times,[[1 if prop in active else 0]*3]*frames)
                held=prop in ['CupTrophy','StarTrophy']
                points=[self.grip_offset]*frames if held else [[0,0,0]]*frames
                self.track(a,i,'translation',times,points)
                if held:self.track(a,i,'rotation',times,hand_orientations)
            for node,effect,base,k in self.particles:
                if effect=='ConfettiFX':
                    points=[np.array(base)+[.02*math.sin(math.tau*f+k),.045*math.cos(math.tau*f+k),.015*math.sin(math.tau*f*2+k)] for f in u]
                else:
                    points=[np.array(base)+[.008*math.sin(math.tau*f+k),.012*math.cos(math.tau*f+k),0] for f in u]
                self.track(a,node,'translation',times,points)
                self.track(a,node,'rotation',times,[quat(12*math.sin(math.tau*f+k),20*math.cos(math.tau*f+k),14*math.sin(math.tau*f+k)) for f in u])
            animations.append(a)
        self.g['animations']=animations
        self.g.setdefault('extras',{})['referenceMotions']=dict(version=2,referenceStates=REFERENCE,
            clipCount=len(animations),handPlacement='two-bone-IK-with-palm-orientation',props=list(self.props),
            fullResetTracks=True,trophyAttachment='LeftHand',gripOffset=self.grip_offset.tolist())
        self.g['buffers'][0]['byteLength']=len(self.blob)
        js=json.dumps(self.g,separators=(',',':')).encode();js+=b' '*(-len(js)%4)
        self.blob+=b'\0'*(-len(self.blob)%4)
        destination=Path(destination);destination.parent.mkdir(parents=True,exist_ok=True)
        destination.write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(self.blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(self.blob),0x004e4942)+self.blob)
        print(json.dumps(self.g['extras']['referenceMotions'],indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('source');parser.add_argument('output');args=parser.parse_args()
    Builder(args.source).build(args.output)
