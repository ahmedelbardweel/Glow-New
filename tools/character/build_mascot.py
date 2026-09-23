"""Build Glow's original, reusable skinned mascot without a DCC dependency.

Run: python tools/character/build_mascot.py
All coordinates are metres-ish, +Y up, +Z forward. Geometry is authored in
bind-space; one mesh uses one skin. The source is deliberately dependency-free.
This is a parametric original inspired by the supplied character sheet, not an
extraction of the existing assets. See docs/character_system.md for the contract.
"""
from __future__ import annotations

import json
import math
import struct
import zlib
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
# Legacy procedural experiment. Never overwrite the supplied textured asset.
OUT = ROOT / "build/legacy_character/glow_procedural.glb"
TAU = math.tau

# The entire head is authored directly around these values.  There is no
# after-the-fact head scale: the skull, face pivots, glasses and fedora all
# share one bind-space design, which keeps them locked together in every clip.
HEAD_CENTER = (0.0, 2.125, -.055)
HEAD_RADIUS = (.705, .525, .455)
HEAD_EXPONENT = .88


def head_ring(v):
    """Superellipse ring radius at a crown-to-chin fraction."""
    theta = math.pi * max(0.0, min(1.0, v))
    return math.sin(theta) ** HEAD_EXPONENT


def head_width(v):
    """A soft skull profile: narrow crown, full cheek, gentle lower taper."""
    return .72 + .30*smooth(.06, .54, v) - .17*smooth(.70, .98, v)


def head_depth(v, phi):
    """Keep the forehead flatter and the rear compact in side view."""
    front = max(0.0, math.sin(phi))
    rear = max(0.0, -math.sin(phi))
    return 1-.11*front-.04*rear+.035*smooth(.25, .70, v)*front


def head_front_z(x, y):
    """Front surface of the rebuilt skull for attached facial panels."""
    cx, cy, cz = HEAD_CENTER
    rx, ry, rz = HEAD_RADIUS
    vertical = max(-1.0, min(1.0, (y-cy)/ry))
    theta = math.acos(spow(vertical, 1/HEAD_EXPONENT))
    v = theta / math.pi
    ring = head_ring(v)
    half_width = rx*ring*head_width(v)
    if half_width < 1e-6:
        return cz
    lateral = min(1.0, abs((x-cx)/half_width))
    return cz + rz*ring*head_depth(v, math.pi/2)*math.sqrt(max(0.0, 1-lateral*lateral))


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, s): return tuple(x * s for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def norm(a):
    length = math.sqrt(dot(a, a))
    return mul(a, 1 / length) if length > 1e-12 else (0, 1, 0)
def lerp(a, b, t): return add(mul(a, 1-t), mul(b, t))
def smooth(a, b, x):
    t = max(0, min(1, (x-a)/(b-a)))
    return t*t*(3-2*t)
def spow(a, p): return math.copysign(abs(a)**p, a)


class Builder:
    def __init__(self):
        self.doc = {"asset": {"version": "2.0", "generator": "Glow parametric mascot 1.0"},
                    "scene": 0, "scenes": [{"name": "GlowMascot", "nodes": []}],
                    "nodes": [], "meshes": [], "materials": [], "skins": [],
                    "animations": [], "accessors": [], "bufferViews": [], "buffers": []}
        self.binary = bytearray()
        self.bones = OrderedDict()
        self.geometry = OrderedDict()
        self.material_ids = {}

    def material(self, name, rgb, roughness=.5, metal=0):
        index = len(self.doc["materials"])
        self.material_ids[name] = index
        self.doc["materials"].append({"name": name, "pbrMetallicRoughness": {
            "baseColorFactor": list(rgb) + [1], "metallicFactor": metal,
            "roughnessFactor": roughness}, "doubleSided": False})
        self.geometry[name] = {"p": [], "n": [], "j": [], "w": [], "i": [], "uv": []}

    def bone(self, name, position, parent=None):
        index = len(self.doc["nodes"])
        local = sub(position, self.bones[parent]["position"]) if parent else position
        node = {"name": name, "translation": list(local)}
        if parent:
            self.doc["nodes"][self.bones[parent]["node"]].setdefault("children", []).append(index)
        else:
            self.doc["scenes"][0]["nodes"].append(index)
        self.doc["nodes"].append(node)
        self.bones[name] = {"node": index, "joint": len(self.bones), "position": position}

    def weights(self, weighted):
        if isinstance(weighted, str): weighted = [(weighted, 1)]
        weighted = [(n, w) for n, w in weighted if w > 1e-7]
        assert 0 < len(weighted) <= 4
        total = sum(w for _, w in weighted)
        joints = [self.bones[n]["joint"] for n, _ in weighted]
        weights = [w / total for _, w in weighted]
        return tuple(joints + [0] * (4-len(joints))), tuple(weights + [0] * (4-len(weights)))

    def append(self, material, positions, normals, indices, skin, vertex_skins=None, uvs=None):
        geom = self.geometry[material]
        base = len(geom["p"])
        for index, (p, n) in enumerate(zip(positions, normals)):
            weighted = vertex_skins[index] if vertex_skins is not None else skin(p) if callable(skin) else skin
            js, ws = self.weights(weighted)
            geom["p"].append(p)
            geom["n"].append(norm(n))
            geom["j"].append(js)
            geom["w"].append(ws)
            geom["uv"].append(uvs[index] if uvs else (p[0]*2, p[1]*2))
        for a, b, c in indices:
            if dot(cross(sub(positions[b], positions[a]), sub(positions[c], positions[a])),
                   cross(sub(positions[b], positions[a]), sub(positions[c], positions[a]))) > 1e-17:
                geom["i"].extend([base+a, base+b, base+c])

    def accessor(self, data, component, kind, target=None, bounds=False):
        while len(self.binary) % 4: self.binary.append(0)
        offset = len(self.binary)
        flat = [v for row in data for v in row] if kind != "SCALAR" else data
        fmt = {5126: "f", 5125: "I", 5123: "H"}[component]
        self.binary.extend(struct.pack("<" + fmt * len(flat), *flat))
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(self.binary)-offset}
        if target: view["target"] = target
        vi = len(self.doc["bufferViews"])
        self.doc["bufferViews"].append(view)
        accessor = {"bufferView": vi, "componentType": component, "count": len(data), "type": kind}
        if bounds:
            rows = [(x,) for x in data] if kind == "SCALAR" else data
            accessor["min"] = [min(row[i] for row in rows) for i in range(len(rows[0]))]
            accessor["max"] = [max(row[i] for row in rows) for i in range(len(rows[0]))]
        ai = len(self.doc["accessors"])
        self.doc["accessors"].append(accessor)
        return ai

    def finalize_geometry(self):
        primitives = []
        for material, geom in self.geometry.items():
            if not geom["p"]: continue
            primitive = {"attributes": {
                "POSITION": self.accessor(geom["p"], 5126, "VEC3", 34962, True),
                "NORMAL": self.accessor(geom["n"], 5126, "VEC3", 34962),
                "JOINTS_0": self.accessor(geom["j"], 5123, "VEC4", 34962),
                "WEIGHTS_0": self.accessor(geom["w"], 5126, "VEC4", 34962)},
                "indices": self.accessor(geom["i"], 5125 if len(geom["p"]) > 65535 else 5123, "SCALAR", 34963),
                "material": self.material_ids[material], "mode": 4}
            if "normalTexture" in self.doc["materials"][self.material_ids[material]]:
                primitive["attributes"]["TEXCOORD_0"] = self.accessor(geom["uv"], 5126, "VEC2", 34962)
                primitive["attributes"]["TANGENT"] = self.accessor(mesh_tangents(geom), 5126, "VEC4", 34962)
            primitives.append(primitive)
        matrices = []
        for bone in self.bones.values():
            x, y, z = bone["position"]
            matrices.append((1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -x, -y, -z, 1))
        self.doc["skins"].append({"name": "GlowSkeleton", "skeleton": self.bones["Root"]["node"],
                                  "joints": [b["node"] for b in self.bones.values()],
                                  "inverseBindMatrices": self.accessor(matrices, 5126, "MAT4")})
        self.doc["meshes"].append({"name": "GlowMascotMesh", "primitives": primitives})
        self.doc["scenes"][0]["nodes"].append(len(self.doc["nodes"]))
        self.doc["nodes"].append({"name": "GlowMascot", "mesh": 0, "skin": 0})

    def soft_surface_texture(self):
        """A tiny embedded micro-normal tile; all materials remain offline."""
        size = 128
        def height(x, y):
            # Deterministic, seamless felt grain with restrained woven fibers.
            x, y = x % size, y % size
            seed = ((x*374761393+y*668265263)^0x51A7) & 0xffffffff
            seed = ((seed^(seed >> 13))*1274126177) & 0xffffffff
            grain = ((seed^(seed >> 16)) & 65535)/65535-.5
            return .45*grain+.18*math.sin(TAU*x/8)*math.sin(TAU*y/8)
        raw = bytearray()
        for y in range(size):
            raw.append(0)
            for x in range(size):
                normal = norm((height(x-1,y)-height(x+1,y),
                               height(x,y-1)-height(x,y+1), 1))
                raw.extend(round((value*.5+.5)*255) for value in normal)
        def chunk(kind, data):
            return struct.pack(">I", len(data))+kind+data+struct.pack(">I", zlib.crc32(kind+data)&0xffffffff)
        png = b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR", struct.pack(">IIBBBBB",size,size,8,2,0,0,0))
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))+chunk(b"IEND", b"")
        while len(self.binary)%4: self.binary.append(0)
        view = len(self.doc["bufferViews"])
        self.doc["bufferViews"].append({"buffer":0,"byteOffset":len(self.binary),"byteLength":len(png)})
        self.binary.extend(png)
        self.doc["images"] = [{"name":"Embedded soft felt microstructure","bufferView":view,"mimeType":"image/png"}]
        self.doc["samplers"] = [{"magFilter":9729,"minFilter":9987,"wrapS":10497,"wrapT":10497}]
        self.doc["textures"] = [{"sampler":0,"source":0}]
        for material, strength in (("BodyColor",.12),("Cream",.24),("Hat",.30),("HatBand",.14)):
            self.doc["materials"][self.material_ids[material]]["normalTexture"] = {"index":0,"scale":strength}

    def animation(self, name, duration, tracks, fps=30):
        count = int(duration * fps) + 1
        times = [duration * i / (count-1) for i in range(count)]
        time_index = self.accessor(times, 5126, "SCALAR", bounds=True)
        animation = {"name": name, "channels": [], "samplers": [],
                     "extras": {"loop": True, "durationSeconds": duration}}
        for bone, path, function in tracks:
            output = [function(t, t/duration) for t in times]
            if path == "rotation":
                output = [quat(*angles) for angles in output]
                # Same hemisphere between successive keys avoids long slerp paths.
                for i in range(1, len(output)):
                    if dot(output[i-1], output[i]) < 0: output[i] = mul(output[i], -1)
            if path == "translation":
                rest = self.doc["nodes"][self.bones[bone]["node"]]["translation"]
                output = [add(rest, delta) for delta in output]
            accessor = self.accessor(output, 5126, "VEC4" if path == "rotation" else "VEC3")
            animation["channels"].append({"sampler": len(animation["samplers"]),
                "target": {"node": self.bones[bone]["node"], "path": path}})
            animation["samplers"].append({"input": time_index, "output": accessor, "interpolation": "LINEAR"})
        self.doc["animations"].append(animation)

    def save(self):
        self.doc["extras"] = {"character": "Glow original mascot", "assetVersion": 1,
            "forward": "+Z", "up": "+Y", "colorMaterial": "BodyColor",
            "facialRig": "bones", "license": "Original generated project asset; embedded procedural texture; no external models.",
            "jawRangeRadians": [0, .38], "mouthOpenScaleY": [1, 15],
            "eyelidUpperCloseTranslationY": -.20, "eyelidLowerCloseTranslationY": .08,
            "source": "tools/character/build_mascot.py"}
        self.doc["buffers"] = [{"byteLength": len(self.binary)}]
        raw = json.dumps(self.doc, separators=(",", ":"), ensure_ascii=True).encode()
        raw += b" " * ((-len(raw)) % 4)
        self.binary.extend(b"\0" * ((-len(self.binary)) % 4))
        glb = struct.pack("<III", 0x46546C67, 2, 12+8+len(raw)+8+len(self.binary))
        glb += struct.pack("<II", len(raw), 0x4E4F534A) + raw
        glb += struct.pack("<II", len(self.binary), 0x004E4942) + self.binary
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_bytes(glb)
        print(json.dumps({"output": str(OUT), "bytes": len(glb), "bones": len(self.bones),
              "materials": len(self.doc["materials"]), "vertices": sum(len(g["p"]) for g in self.geometry.values()),
              "triangles": sum(len(g["i"])//3 for g in self.geometry.values()),
              "animations": [a["name"] for a in self.doc["animations"]]}, indent=2))


def quat(x=0, y=0, z=0):
    sx, sy, sz = math.sin(x/2), math.sin(y/2), math.sin(z/2)
    cx, cy, cz = math.cos(x/2), math.cos(y/2), math.cos(z/2)
    return (sx*cy*cz+cx*sy*sz, cx*sy*cz-sx*cy*sz, cx*cy*sz+sx*sy*cz, cx*cy*cz-sx*sy*sz)


def mesh_tangents(geom):
    """Area-averaged tangent frames for the embedded normal texture."""
    tangents = [(0,0,0)]*len(geom["p"])
    bitangents = [(0,0,0)]*len(geom["p"])
    for k in range(0, len(geom["i"]), 3):
        a,c,d = geom["i"][k:k+3]
        e1,e2 = sub(geom["p"][c],geom["p"][a]),sub(geom["p"][d],geom["p"][a])
        uv1,uv2 = sub(geom["uv"][c],geom["uv"][a]),sub(geom["uv"][d],geom["uv"][a])
        det = uv1[0]*uv2[1]-uv1[1]*uv2[0]
        if abs(det)<1e-12: continue
        tangent = mul(sub(mul(e1,uv2[1]),mul(e2,uv1[1])),1/det)
        bitangent = mul(sub(mul(e2,uv1[0]),mul(e1,uv2[0])),1/det)
        for i in (a,c,d):
            tangents[i] = add(tangents[i],tangent)
            bitangents[i] = add(bitangents[i],bitangent)
    result = []
    for n,t,bt in zip(geom["n"],tangents,bitangents):
        t = sub(t,mul(n,dot(n,t)))
        if dot(t,t)<1e-15:
            t = cross((0,1,0) if abs(n[1])<.9 else (1,0,0),n)
        t = norm(t)
        result.append((*t,-1 if dot(cross(n,t),bt)<0 else 1))
    return result


def sphere(b, material, center, radius, skin, lon=40, lat=24, exponent=1):
    p, n, tris = [], [], []
    power = 2/exponent
    for j in range(lat+1):
        theta = math.pi*j/lat
        for i in range(lon+1):
            phi = TAU*i/lon
            xyz = (spow(math.sin(theta), exponent)*spow(math.cos(phi), exponent),
                   spow(math.cos(theta), exponent),
                   spow(math.sin(theta), exponent)*spow(math.sin(phi), exponent))
            p.append(add(center, tuple(a*r for a, r in zip(xyz, radius))))
            n.append(norm(tuple(spow(a, power-1)/r for a, r in zip(xyz, radius))))
    for j in range(lat):
        for i in range(lon):
            a = j*(lon+1)+i
            if j > 0: tris.append((a, a+1, a+lon+1))
            if j < lat-1: tris.append((a+1, a+lon+2, a+lon+1))
    b.append(material, p, n, tris, skin,
             uvs=[(i/lon*5, j/lat*4) for j in range(lat+1) for i in range(lon+1)])


def surface(b, material, fn, us, vs, skin, reverse=False, skin_uv=None):
    positions, normals, indices = [], [], []
    vertex_skins = [] if skin_uv else None
    for v in range(vs+1):
        for u in range(us+1):
            a, c = u/us, v/vs
            positions.append(fn(a, c))
            if skin_uv: vertex_skins.append(skin_uv(a, c))
            du = mul(sub(fn(a+1e-5, c), fn(a-1e-5, c)), 50000)
            dv = mul(sub(fn(a, c+1e-5), fn(a, c-1e-5)), 50000)
            if dot(cross(du, dv), cross(du, dv)) < 1e-20:
                sample_c = max(1e-4, min(1-1e-4, c))
                du = mul(sub(fn(a+1e-5, sample_c), fn(a-1e-5, sample_c)), 50000)
                dv = mul(sub(fn(a, sample_c+1e-5), fn(a, sample_c-1e-5)), 50000)
            normals.append(mul(norm(cross(du, dv)), -1 if reverse else 1))
    for v in range(vs):
        for u in range(us):
            i = v*(us+1)+u
            for tri in [(i, i+1, i+us+1), (i+1, i+us+2, i+us+1)]:
                indices.append(tuple(reversed(tri)) if reverse else tri)
    b.append(material, positions, normals, indices, skin, vertex_skins,
             uvs=[(u/us*5, v/vs*4) for v in range(vs+1) for u in range(us+1)])


def sculpted_head(b, material, skin, lon=80, lat=56):
    """Closed mascot skull with a compact, cheek-led side silhouette.

    The profile deliberately reaches its widest point below the brow.  This
    makes the crown sit inside the fedora while the cheeks carry the friendly
    character volume, instead of reading as a uniform green ball.
    """
    cx, cy, cz = HEAD_CENTER
    rx, ry, rz = HEAD_RADIUS

    def shape(u, v):
        # ``surface`` samples just outside its domain while estimating normals.
        v = max(0.0, min(1.0, v))
        theta, phi = math.pi*v, TAU*u
        ring = head_ring(v)
        return (
            cx + rx*ring*head_width(v)*math.cos(phi),
            cy + ry*spow(math.cos(theta), HEAD_EXPONENT)-.018*smooth(.70, .98, v),
            cz + rz*ring*head_depth(v, phi)*math.sin(phi),
        )

    surface(b, material, shape, lon, lat, skin)


def curve(b, material, points, radius, skin, sides=10):
    """Parallel-ish frames for thin continuous facial/accessory tubes."""
    positions, normals, indices = [], [], []
    for i, point in enumerate(points):
        direction = norm(sub(points[min(i+1, len(points)-1)], points[max(0, i-1)]))
        helper = (0, 0, 1) if abs(direction[2]) < .9 else (0, 1, 0)
        u = norm(cross(direction, helper))
        v = norm(cross(direction, u))
        for j in range(sides+1):
            angle = j*TAU/sides
            normal = add(mul(u, math.cos(angle)), mul(v, math.sin(angle)))
            positions.append(add(point, mul(normal, radius)))
            normals.append(normal)
    for i in range(len(points)-1):
        for j in range(sides):
            a = i*(sides+1)+j
            indices += [(a, a+sides+1, a+1), (a+1, a+sides+1, a+sides+2)]
    b.append(material, positions, normals, indices, skin)


def tube(b, material, controls, radii, skin, rings=40, sides=24):
    def sample(t):
        t = max(0, min(1, t))
        location = t*(len(controls)-1)
        i = min(int(location), len(controls)-2)
        f = location-i
        # Catmull-Rom with clamped endpoints, smooth through authored controls.
        def cat(values):
            p0, p1, p2, p3 = [values[max(0, min(len(values)-1, j))] for j in (i-1, i, i+1, i+2)]
            return .5*((2*p1)+(-p0+p2)*f+(2*p0-5*p1+4*p2-p3)*f*f+(-p0+3*p1-3*p2+p3)*f*f*f)
        return tuple(cat([p[k] for p in controls]) for k in range(3)), max(.001, cat(radii))
    def fn(u, v):
        point, radius = sample(v)
        direction = norm(sub(sample(v+1e-4)[0], sample(v-1e-4)[0]))
        helper = (1, 0, 0) if abs(direction[0]) < .9 else (0, 0, 1)
        a = norm(cross(helper, direction))
        c = norm(cross(direction, a))
        return add(point, mul(add(mul(a, math.cos(u*TAU)), mul(c, math.sin(u*TAU))), radius))
    surface(b, material, fn, sides, rings, skin)


def torso_weights(p):
    # The torso is deliberately short. Its upper third is carried by Chest so
    # the rounded transition into the neck stays stable in every arm pose.
    t = smooth(.64, 1.10, p[1])
    u = smooth(1.04, 1.48, p[1])
    return [("Hips", 1-t), ("Spine", t*(1-u)), ("Chest", t*u)]


def chest_yoke_weights(p):
    """A soft chest-to-neck bridge: no visible head/body seam in motion."""
    t = smooth(1.57, 1.83, p[1])
    return [("Chest", 1-t), ("Neck", t)]


def cream_bib_front_z(x, y):
    """The cream is an inlaid surface on the body, not a suspended panel."""
    def front(cx, cy, cz, rx, ry, rz, exponent):
        q = abs((x-cx)/rx)**(2/exponent)+abs((y-cy)/ry)**(2/exponent)
        return cz+rz*max(.0001, 1-q)**(exponent/2)
    # The torso carries high into the head, so there is no narrow dark neck
    # stalk underneath the muzzle when seen from the front or side.
    torso = front(0, 1.10, -.040, .660, .835, .508, .94)
    head = head_front_z(x, y)
    neck = front(0, 1.64, -.012, .405, .260, .350, .94)
    # Smooth unions avoid a shading ridge where the three rounded forms meet.
    def union(a, c, softness):
        return .5*(a+c+math.sqrt((a-c)**2+softness*softness))
    # A very shallow upper-chest lift meets the underside of the muzzle. This
    # removes the dark step created by two otherwise valid but separated front
    # surfaces, while staying below the cheek silhouette at the sides.
    throat_lift = .045*smooth(1.34, 1.75, y)
    return union(union(torso, neck, .030), head, .045)+.004+throat_lift


def cream_width(y):
    # Rounded lower abdomen, gently narrower throat, buried under the muzzle.
    lower = math.sqrt(max(0, 1-((y-.79)/.39)**2)) if y < .79 else 1
    # The top narrows into a small, curved throat instead of a parallel-sided
    # apron. It disappears beneath the lower muzzle at the final rows.
    return lower*(.463-.100*smooth(.92, 1.45, y)-.153*smooth(1.45, 1.88, y))


def cream_weights(p):
    """Keep the cream torso a stable garment through every facial gesture.

    The previous upper rows blended into Neck and Head.  That made the bib
    stretch or rise whenever an expressive clip tilted the head, while the Sad
    clip happened to look correct.  The entire panel now belongs to the torso:
    lower rows blend naturally through Hips/Spine and the upper throat locks
    to Chest.  The head and jaw can animate above it without changing its
    silhouette.
    """
    base = torso_weights(p)
    chest_lock = smooth(1.15, 1.56, p[1])
    # Preserve exactly one influence per bone. `torso_weights` already has a
    # Chest entry, so fold the lock into it instead of appending Chest again.
    return [
        (name, weight*(1-chest_lock)+(chest_lock if name == "Chest" else 0))
        for name, weight in base
    ]


def limb_weights(side, p, arm=True):
    y = p[1]
    if arm:
        elbow = 1-smooth(.96, 1.22, y)
        wrist = 1-smooth(.70, .86, y)
        # Only the buried medial root blends into the chest. Blending the
        # visible shoulder 50/50 would collapse it in the raised-arm clips.
        chest = (1-smooth(.37, .52, abs(p[0])))*smooth(1.34, 1.48, y)
        return [("Chest", chest), (side+"UpperArm", (1-elbow)*(1-chest)),
                (side+"ForeArm", elbow*(1-wrist)*(1-chest)), (side+"Hand", elbow*wrist*(1-chest))]
    knee = 1-smooth(.25, .44, y)
    ankle = 1-smooth(.10, .21, y)
    return [(side+"UpperLeg", 1-knee), (side+"LowerLeg", knee*(1-ankle)), (side+"Foot", knee*ankle)]


def make_skeleton(b):
    b.bone("Root", (0, 0, 0))
    b.bone("Hips", (0, .64, 0), "Root")
    b.bone("Spine", (0, 1.02, 0), "Hips")
    b.bone("Chest", (0, 1.43, 0), "Spine")
    b.bone("Neck", (0, 1.74, 0), "Chest")
    # Facial pivots are authored in the same direct head space as the mesh.
    # This is what prevents lids, glasses and jaw features drifting after a
    # story animation rotates the head.
    b.bone("Head", HEAD_CENTER, "Neck")
    b.bone("Jaw", (0, 1.94, .43), "Head")
    b.bone("Mouth", (0, 1.87, .50), "Head")
    for side, sign, tag in [("Left", 1, "L"), ("Right", -1, "R")]:
        b.bone(side+"UpperArm", (sign*.52, 1.49, 0), "Chest")
        b.bone(side+"ForeArm", (sign*.755, 1.08, .04), side+"UpperArm")
        b.bone(side+"Hand", (sign*.835, .765, .10), side+"ForeArm")
        # Three small paw-digit bones make the hand expressive while keeping
        # the broad, friendly silhouette of the mascot's mitten-like palms.
        for digit, offset in enumerate((-.065, 0, .065), 1):
            b.bone(side+f"Finger{digit}", (sign*(.833+offset), .690, .190), side+"Hand")
        b.bone(side+"UpperLeg", (sign*.285, .55, 0), "Hips")
        b.bone(side+"LowerLeg", (sign*.285, .29, .015), side+"UpperLeg")
        b.bone(side+"Foot", (sign*.285, .13, .075), side+"LowerLeg")
        # Toes are separate child bones so they can flex during walking.
        for toe, offset in enumerate((-.070, 0, .070), 1):
            b.bone(side+f"Toe{toe}", (sign*(.287+offset), .135, .270), side+"Foot")
        b.bone("Eye_"+tag, (sign*.335, 2.270, .334), "Head")
        b.bone("UpperEyelid_"+tag, (sign*.335, 2.412, .346), "Head")
        b.bone("LowerEyelid_"+tag, (sign*.335, 2.124, .342), "Head")
        b.bone("Brow_"+tag, (sign*.335, 2.485, .340), "Head")
    b.bone("Tail1", (0, .63, -.36), "Hips")
    b.bone("Tail2", (0, .59, -.66), "Tail1")
    b.bone("Tail3", (0, .67, -.94), "Tail2")


def make_body(b):
    # Shorter, fuller torso. The yoke below overlaps both torso and neck to
    # create one uninterrupted silhouette between the body and the head.
    sphere(b, "BodyColor", (0, 1.10, -.040), (.660, .835, .508), torso_weights, 64, 52, .94)
    sculpted_head(b, "BodyColor", "Head")
    # A compact collar disappears inside head and torso instead of reading as
    # a separate dark band between them.
    sphere(b, "BodyColor", (0, 1.64, -.012), (.405, .260, .350), chest_yoke_weights, 44, 28, .94)

    # Follow the reference's organic inlaid belly. Its rounded base and narrow
    # throat hug the torso and share the same weights, avoiding a floating bib.
    def bib(u, v):
        # It slightly overlaps the lower muzzle in rest pose; the matching
        # surface and bone weights keep that transition continuous in motion.
        y = .401+1.470*v
        x = (2*u-1)*cream_width(y)
        return x, y, cream_bib_front_z(x, y)
    surface(b, "Cream", bib, 64, 72, cream_weights)

    for side, sign in [("Left", 1), ("Right", -1)]:
        skin = lambda p, side=side: limb_weights(side, p)
        # A round cap centred on the existing pivot keeps the shoulder joined
        # at the full Wave/Victory range, with a soft taper into the upper arm.
        sphere(b, "BodyColor", (sign*.52, 1.49, 0), (.187, .187, .187), side+"UpperArm", 36, 26)
        tube(b, "BodyColor", [(sign*.40, 1.53, -.015), (sign*.55, 1.46, 0),
             (sign*.68, 1.28, .015), (sign*.77, 1.05, .055), (sign*.825, .80, .095)],
             [.128, .186, .169, .149, .112], skin, 44, 28)
        sphere(b, "BodyColor", (sign*.825, .708, .10), (.141, .193, .147), side+"Hand", 32, 24)
        sphere(b, "BodyColor", (sign*.739, .747, .161), (.063, .085, .065), side+"Hand", 24, 16)
        # Rounded fingers sit on the front of the palm. They have their own
        # child bones, so wave and happy gestures can flex the paw naturally.
        for digit, offset in enumerate((-.065, 0, .065), 1):
            sphere(b, "BodyColor", (sign*(.825+offset*.88), .580, .158),
                   (.052, .070 if digit == 2 else .062, .061),
                   side+f"Finger{digit}", 24, 18, .86)
        for offset in (-.033, .033):
            points = [(sign*(.825+offset*.88), .605-.046*t, .216+.003*math.sin(t*math.pi))
                      for t in [i/8 for i in range(9)]]
            curve(b, "BodyDetail", points, .002, side+"Hand", 6)
        skin_leg = lambda p, side=side: limb_weights(side, p, False)
        sphere(b, "BodyColor", (sign*.285, .354, -.017), (.215, .343, .242), skin_leg, 36, 26, .90)
        sphere(b, "BodyColor", (sign*.287, .138, .080), (.221, .139, .251), side+"Foot", 40, 26, .88)
        # Three soft teddy-bear toes extend from each foot. The darker seams
        # are restrained, so the paws read as rounded toes rather than claws.
        for toe, offset in enumerate((-.070, 0, .070), 1):
            sphere(b, "BodyColor", (sign*(.287+offset), .099, .275),
                   (.061, .061, .084), side+f"Toe{toe}", 24, 18, .90)
        for offset in (-.035, .035):
            points = [(sign*(.287+offset), .140-.027*t, .337+.004*math.sin(t*math.pi))
                      for t in [i/8 for i in range(9)]]
            curve(b, "BodyDetail", points, .002, side+"Foot", 6)

    def tail_weights(p):
        t = smooth(.44, .77, -p[2]); u = smooth(.76, 1.03, -p[2])
        return [("Tail1", 1-t), ("Tail2", t*(1-u)), ("Tail3", t*u)]
    # A compact teddy-dinosaur tail supports the silhouette without extending
    # far past the body in profile.
    tube(b, "BodyColor", [(0, .646, -.31), (0, .590, -.50), (0, .61, -.66),
         (0, .678, -.79), (0, .742, -.88)], [.20, .195, .126, .058, .002], tail_weights, 42, 30)


def make_face(b):
    """A restrained face integrated into the new compact skull.

    The cream area is a contained cheek-and-chin form.  It follows the skull
    rather than becoming a large horizontal stripe, while the mouth boundary
    remains weighted to the existing Jaw and Mouth controls.
    """
    def mouth_rim(u):
        angle = u*TAU
        c, s = math.cos(angle), math.sin(angle)
        return .255*c, 1.875+.004*s+.016*c*c, .435-.027*c*c

    def lip_weights(u, v):
        s = math.sin(u*TAU)
        middle = s*s
        # The outside is attached to Head.  Only the lower inner rim follows
        # the hinge, so speaking opens a mouth instead of pulling the cheeks.
        mouth = (.46 if s >= 0 else .24)*middle*(1-smooth(0, .60, v))
        jaw = .58*middle*(1-smooth(.65, 1, v)) if s < 0 else 0
        return [("Head", 1-mouth-jaw), ("Jaw", jaw), ("Mouth", mouth)]

    def muzzle(u, v):
        angle = u*TAU
        c, s = math.cos(angle), math.sin(angle)
        inner = mouth_rim(u)
        x = .575*c
        y = 1.950+.205*s-.055*max(0, s)*math.exp(-(x/.22)**2)
        # A slight central relief makes the muzzle soft, while the side edges
        # stay seated on the green cheek surface in front and profile views.
        outer = (x, y, head_front_z(x, y)+.020+.026*math.exp(-(x/.29)**2))
        x, y, z = lerp(inner, outer, v)
        return x, y, z+.012*math.sin(math.pi*v)

    surface(b, "Cream", muzzle, 88, 26, "Head", reverse=True, skin_uv=lip_weights)

    def cavity(u, v):
        rim = mouth_rim(u)
        return (rim[0]*(1-v), rim[1]*(1-v)+1.874*v,
                rim[2]*(1-v)+.365*v-.008*math.sin(v*math.pi))

    def cavity_weights(u, v):
        return [(name, weight*(1-v)+(v if name == "Head" else 0))
                for name, weight in lip_weights(u, 0)]

    surface(b, "MouthInterior", cavity, 88, 16, "Head", skin_uv=cavity_weights)
    sphere(b, "Tongue", (0, 1.861, .398), (.121, .004, .021),
           [("Jaw", .70), ("Mouth", .30)], 32, 18)

    # A compact green snout bridges the eyes and cream cheeks.  It is part of
    # the head silhouette rather than a projecting oval glued on the face.
    sphere(b, "BodyColor", (0, 2.100, .365), (.215, .103, .078), "Head", 40, 26)
    for sign, tag in [(1, "L"), (-1, "R")]:
        sphere(b, "BodyDetail", (sign*.075, 2.095, .441), (.012, .015, .004), "Head", 18, 12)
        cx = sign*.335
        eye = "Eye_"+tag
        sphere(b, "Sclera", (cx, 2.270, .334), (.135, .151, .065), eye, 36, 26)
        sphere(b, "IrisRim", (cx-sign*.005, 2.271, .402), (.086, .098, .010), eye, 32, 22)
        sphere(b, "Iris", (cx-sign*.007, 2.271, .411), (.074, .087, .009), eye, 32, 22)
        sphere(b, "Pupil", (cx-sign*.011, 2.274, .420), (.041, .057, .006), eye, 28, 20)
        sphere(b, "EyeHighlight", (cx-.024, 2.308, .427), (.016, .020, .003), eye, 18, 12)
        sphere(b, "EyeHighlight", (cx+.018, 2.251, .428), (.005, .006, .002), eye, 14, 10)
        sphere(b, "BodyColor", (cx, 2.412, .346), (.137, .043, .038), "UpperEyelid_"+tag, 32, 22)
        sphere(b, "BodyColor", (cx, 2.124, .342), (.130, .028, .036), "LowerEyelid_"+tag, 32, 20)
        brow_points = [
            (cx+.118*(2*i/24-1), 2.485+.021*math.sin(math.pi*i/24),
             head_front_z(cx+.118*(2*i/24-1), 2.485+.021*math.sin(math.pi*i/24))+.027)
            for i in range(25)
        ]
        curve(b, "BodyDetail", brow_points, .0085, "Brow_"+tag, 9)


def make_glasses(b):
    for sign in [1, -1]:
        circle = [
            (sign*.335+.178*math.cos(t*TAU/64), 2.270+.185*math.sin(t*TAU/64),
             .414-.010*abs(math.cos(t*TAU/64))) for t in range(65)
        ]
        curve(b, "Glasses", circle, .010, "Head", 10)
        highlight = [
            (sign*.335+.173*math.cos(t*TAU/64), 2.270+.180*math.sin(t*TAU/64),
             .420-.010*abs(math.cos(t*TAU/64))) for t in range(65)
        ]
        curve(b, "GlassesRim", highlight, .0022, "Head", 7)
        temple = [(sign*x, y, z) for x, y, z in [
            (.513, 2.278, .400), (.570, 2.275, .332), (.625, 2.247, .205),
            (.670, 2.205, .075), (.672, 2.175, -.010),
        ]]
        curve(b, "Glasses", temple, .009, "Head", 10)
        sphere(b, "GlassesRim", (sign*.513, 2.278, .400), (.014, .014, .010), "Head", 16, 11)
    bridge = [
        (-.158+.316*i/36, 2.276+.032*math.sin(math.pi*i/36), .417)
        for i in range(37)
    ]
    curve(b, "Glasses", bridge, .0095, "Head", 10)


def make_hat(b):
    for sign in [-1, 1]:
        # Character ears emerge from the head behind the cap.  Keeping them
        # green stops the fedora silhouette from turning into a second animal.
        sphere(b, "BodyColor", (sign*.470, 2.650, -.075), (.105, .115, .090), "Head", 30, 20)

    # The brim sits into the forehead with only a modest overhang.  Its front
    # drops slightly, matching a real fedora instead of floating above the face.
    def brim_y(phi): return 2.555+.012*math.cos(phi)**2-.025*math.sin(phi)
    def brim_top(u, v):
        phi = u*TAU
        rx, rz = .625+.210*v, .485+.140*v
        return rx*math.cos(phi), brim_y(phi)+.017+.006*math.sin(math.pi*v), rz*math.sin(phi)
    def brim_bottom(u, v):
        x, y, z = brim_top(u, v)
        return x, y-.040, z
    surface(b, "Hat", brim_top, 88, 6, "Head")
    surface(b, "Hat", brim_bottom, 88, 6, "Head", reverse=True)
    edge = [(.835*math.cos(i*TAU/88), brim_y(i*TAU/88)-.002,
             .625*math.sin(i*TAU/88)) for i in range(89)]
    curve(b, "Hat", edge, .017, "Head", 10)

    def crown(u, v):
        phi = u*TAU
        # A soft tapered crown follows the green skull, with enough height for
        # a recognizable fedora without becoming a second oversized head.
        rx = .625-.150*v+.016*math.sin(math.pi*v)
        rz = .500-.135*v+.012*math.sin(math.pi*v)
        front_pinch = 1-.050*max(0, math.sin(phi))**2*math.sin(math.pi*v)
        x = rx*math.cos(phi)*front_pinch
        z = rz*math.sin(phi)
        y = 2.565+.350*v+.010*math.sin(math.pi*v)
        y -= .012*math.exp(-(x/.16)**2)*smooth(.56, 1, v)
        return x, y, z
    surface(b, "Hat", crown, 96, 40, "Head", reverse=True)

    def hat_top(u, v):
        phi = u*TAU
        radius = 1-v
        x, z = .475*radius*math.cos(phi), .365*radius*math.sin(phi)
        y = 2.915+.010*(1-radius*radius)-.014*(1-radius*radius)*math.exp(-(x/.17)**2)
        return x, y, z
    surface(b, "Hat", hat_top, 96, 24, "Head", reverse=True)

    def band(u, v):
        x, y, z = crown(u, .020+.135*v)
        return x*1.008, y, z*1.008
    surface(b, "HatBand", band, 96, 8, "Head", reverse=True)
    for v in (0, 1):
        points = [band(i/96, v) for i in range(97)]
        curve(b, "HatTrim", points, .0032, "Head", 7)


def make_badge(b):
    # Bevelled lightning bolt on the upper belly, custom polygon triangulated
    # with an ear-clipping pass (the outline is intentionally concave).
    polygon = [(-.008,.174),(-.119,-.003),(-.026,-.003),(-.072,-.141),(.120,.055),(.027,.055),(.064,.174)]
    polygon = [(x*.78+.190,y*.80+1.255) for x,y in polygon]
    # Ensure counter-clockwise winding for +Z-facing triangles.
    area = sum(polygon[i][0]*polygon[(i+1)%len(polygon)][1]-polygon[(i+1)%len(polygon)][0]*polygon[i][1] for i in range(len(polygon)))
    if area < 0: polygon.reverse()
    def z(x,y):
        return cream_bib_front_z(x, y)+.007
    outer = [(x,y,z(x,y)) for x,y in polygon]
    center = tuple(sum(p[k] for p in outer)/len(outer) for k in range(3))
    inner = [(center[0]+(x-center[0])*.86,center[1]+(y-center[1])*.92,z(x,y)+.014) for x,y in polygon]
    tris, remaining = [], list(range(len(inner)))
    def sign2(a,b,c): return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    while len(remaining)>3:
        for j in range(len(remaining)):
            a,c,d = remaining[j-1],remaining[j],remaining[(j+1)%len(remaining)]
            if sign2(inner[a],inner[c],inner[d]) <= 0: continue
            if any(all(v>=0 for v in (sign2(inner[a],inner[c],inner[e]),sign2(inner[c],inner[d],inner[e]),sign2(inner[d],inner[a],inner[e]))) for e in remaining if e not in (a,c,d)): continue
            tris.append((a,c,d)); remaining.pop(j); break
        else: raise RuntimeError("Cannot triangulate badge")
    tris.append(tuple(remaining))
    b.append("Gold", inner, [(0,0,1)]*len(inner), tris, cream_weights)
    positions, normals, sides = [], [], []
    for i in range(len(inner)):
        j = (i+1)%len(inner)
        vertices = [outer[i],outer[j],inner[j],inner[i]]
        normal = norm(cross(sub(vertices[1],vertices[0]),sub(vertices[2],vertices[0])))
        base = len(positions); positions.extend(vertices); normals.extend([normal]*4)
        sides.extend([(base,base+1,base+2),(base,base+2,base+3)])
    b.append("GoldEdge", positions, normals, sides, cream_weights)


def compact_proportions(b):
    """Shorten the lower anatomy while retaining a broad, expressive head.

    Transform rest bones as well as vertices; animation translation samplers
    are subsequently authored from these new rest transforms.
    """
    def height(y):
        return y*.82 if y < 1.70 else y-.306
    for geom in b.geometry.values():
        positions = geom["p"]
        geom["n"] = [norm((n[0], n[1]/(.82 if p[1] < 1.70 else 1), n[2]))
                     for p, n in zip(positions, geom["n"])]
        geom["p"] = [(x, height(y), z) for x, y, z in positions]
    parents = {child: parent for parent, node in enumerate(b.doc["nodes"])
               for child in node.get("children", [])}
    positions = {}
    for bone in b.bones.values():
        x, y, z = bone["position"]
        bone["position"] = (x, height(y), z)
        positions[bone["node"]] = bone["position"]
    for bone in b.bones.values():
        node = bone["node"]
        parent = parents.get(node)
        b.doc["nodes"][node]["translation"] = list(sub(
            positions[node], positions[parent] if parent is not None else (0, 0, 0)))


def make_animations(b):
    sin, pi = math.sin, math.pi
    # Every story clip begins from the same gently lowered head posture.  The
    # individual clips may still look left/right or breathe, but none of them
    # raises the chin above the calm, composed Sad silhouette.
    resting_head_pitch = .160
    def blink(t, period=4):
        phase = t % period
        return math.sin(pi*(phase-2.25)/.18)**2 if 2.25 <= phase <= 2.43 else 0
    def expression(mood, duration):
        tracks = []
        for sign, tag in [(1,"L"),(-1,"R")]:
            if mood in ("Happy","Victory"):
                upper = lambda t,u: (0,-.065-.075*blink(t),0)
                lower = lambda t,u: (0,.028+.04*blink(t),0)
                brow = lambda t,u,s=sign: (0,0,s*.08)
            elif mood == "Sad":
                upper = lambda t,u: (0,-.083-.08*blink(t),0)
                lower = lambda t,u: (0,0,0)
                brow = lambda t,u,s=sign: (0,0,-s*.26)
            elif mood == "Thinking":
                upper = lambda t,u,s=sign: (0,-(.026 if s==1 else .062)-.12*blink(t),0)
                lower = lambda t,u: (0,0,0)
                brow = lambda t,u,s=sign: (0,0,s*.22)
            else:
                upper = lambda t,u: (0,-.20*blink(t),0)
                lower = lambda t,u: (0,.08*blink(t),0)
                brow = lambda t,u: (0,0,0)
            tracks += [("UpperEyelid_"+tag,"translation",upper),("LowerEyelid_"+tag,"translation",lower),
                       ("UpperEyelid_"+tag,"scale",lambda t,u: (1,1+.85*blink(t),1)),
                       ("Brow_"+tag,"rotation",brow)]
        return tracks

    def finger_motion(side, curl, flutter=0):
        sign = 1 if side == "Left" else -1
        tracks = []
        for digit in range(1, 4):
            phase = (digit-2)*.55
            tracks.append((side+f"Finger{digit}", "rotation",
                lambda t, u, phase=phase, digit=digit, sign=sign:
                    (curl+flutter*sin(TAU*2*u+phase), 0, sign*(digit-2)*.035)))
        return tracks

    def idle_fingers():
        tracks = []
        for side in ("Left", "Right"):
            tracks += finger_motion(side, .035, .016)
        return tracks

    # Idle is subtle enough to layer below one narrative action.  Keep the
    # resting head softly lowered, matching the composed silhouette used by
    # Sad rather than holding the chin unnaturally high between story beats.
    # Talk only addresses facial/head bones so its weights can blend with body
    # gestures.
    b.animation("Idle",4,[
        ("Spine","rotation",lambda t,u:(.010*sin(TAU*u),0,.009*sin(TAU*u))),
        ("Chest","scale",lambda t,u:(1+.009*sin(TAU*u),1+.012*sin(TAU*u),1+.016*sin(TAU*u))),
        ("Head","rotation",lambda t,u:(resting_head_pitch+.015*sin(TAU*u),.025*sin(TAU*u),.012*sin(TAU*u))),
        ("LeftUpperArm","rotation",lambda t,u:(.024*sin(TAU*u),0,-.014*sin(TAU*u))),
        ("RightUpperArm","rotation",lambda t,u:(-.024*sin(TAU*u),0,-.014*sin(TAU*u))),
        ("Tail1","rotation",lambda t,u:(0,.085*sin(TAU*u),0)),
        ("Tail2","rotation",lambda t,u:(0,.075*sin(TAU*u+.45),0)),
        ("Tail3","rotation",lambda t,u:(0,.075*sin(TAU*u+.85),0)),
    ]+idle_fingers()+expression("Idle",4))
    def speech(t,u): return (.5+.5*sin(TAU*4*u))*(.63+.37*sin(TAU*7*u)**2)
    b.animation("Talk",2,[
        ("Jaw","rotation",lambda t,u:(.035+.28*speech(t,u),0,0)),
        ("Mouth","scale",lambda t,u:(.98+.02*speech(t,u),1+1.70*speech(t,u),1)),
        ("Head","rotation",lambda t,u:(resting_head_pitch+.024*sin(TAU*2*u),.022*sin(TAU*u),.012*sin(TAU*2*u))),
        ("Brow_L","translation",lambda t,u:(0,.018*speech(t,u),0)),
        ("Brow_R","translation",lambda t,u:(0,.018*speech(t,u),0)),
    ])
    # Actions stay in their expressive pose and loop. Application cross-fades
    # establish/release each pose; clips do not contain a repeated reset.
    b.animation("Wave",2.4,[
        ("LeftUpperArm","rotation",lambda t,u:(-.2,0,1.92)),
        ("LeftForeArm","rotation",lambda t,u:(-.12,0,.12+.24*sin(TAU*2*u))),
        ("LeftHand","rotation",lambda t,u:(0,.12*sin(TAU*2*u),.17*sin(TAU*2*u))),
        ("Head","rotation",lambda t,u:(resting_head_pitch,.055,-.055+.018*sin(TAU*u))),
        ("Jaw","rotation",lambda t,u:(.07,0,0)),
        ("Mouth","scale",lambda t,u:(1.0,1.35,1)),
    ]+finger_motion("Left", .18, .13)+expression("Wave",2.4))
    b.animation("Happy",2,[
        ("Root","translation",lambda t,u:(0,.065*(1-math.cos(TAU*2*u)),0)),
        ("Spine","rotation",lambda t,u:(0,0,.045*sin(TAU*u))),
        ("LeftUpperArm","rotation",lambda t,u:(-.17,0,1.56+.10*sin(TAU*2*u))),
        ("RightUpperArm","rotation",lambda t,u:(-.17,0,-1.56-.10*sin(TAU*2*u))),
        ("LeftForeArm","rotation",lambda t,u:(-.17,0,.38)),
        ("RightForeArm","rotation",lambda t,u:(-.17,0,-.38)),
        # Keep the celebratory bob below the same lowest pitch used by Sad;
        # happiness changes the expression, never lifts the chin.
        ("Head","rotation",lambda t,u:(resting_head_pitch+.025*sin(TAU*2*u),0,.025*sin(TAU*u))),
        ("Jaw","rotation",lambda t,u:(.28+.045*sin(TAU*2*u),0,0)),
        ("Mouth","scale",lambda t,u:(1.01,1.65+.05*sin(TAU*2*u),1)),
        ("Tail1","rotation",lambda t,u:(0,.21*sin(TAU*2*u),0)),
    ]+finger_motion("Left", .24, .045)+finger_motion("Right", .24, .045)+expression("Happy",2))
    b.animation("Sad",4,[
        ("Spine","rotation",lambda t,u:(.055,0,0)),
        ("Head","rotation",lambda t,u:(resting_head_pitch+.025*sin(TAU*u),0,-.035)),
        ("LeftUpperArm","rotation",lambda t,u:(.13,0,-.065)),
        ("RightUpperArm","rotation",lambda t,u:(.13,0,.065)),
        ("Tail1","rotation",lambda t,u:(-.21,0,0)),
        ("Jaw","rotation",lambda t,u:(0,0,0)),
        ("Mouth","scale",lambda t,u:(.92,1,1)),
    ]+finger_motion("Left", .13)+finger_motion("Right", .13)+expression("Sad",4))
    b.animation("Thinking",4,[
        ("Head","rotation",lambda t,u:(resting_head_pitch,.095+.025*sin(TAU*u),-.08)),
        ("LeftUpperArm","rotation",lambda t,u:(-1.03,0,-.2)),
        ("LeftForeArm","rotation",lambda t,u:(-1.34,.13,-.55)),
        ("LeftHand","rotation",lambda t,u:(0,.18,.18)),
        ("RightUpperArm","rotation",lambda t,u:(-.23,0,.12)),
        ("RightForeArm","rotation",lambda t,u:(-.83,0,.28)),
        ("Eye_L","rotation",lambda t,u:(-.065,.12,0)),
        ("Eye_R","rotation",lambda t,u:(-.065,.12,0)),
        ("Jaw","rotation",lambda t,u:(.025,0,0)),
        ("Mouth","scale",lambda t,u:(.95,1.06,1)),
    ]+finger_motion("Left", .38)+finger_motion("Right", .25)+expression("Thinking",4))
    b.animation("Victory",2.4,[
        ("Root","translation",lambda t,u:(0,.045*(1-math.cos(TAU*2*u)),0)),
        ("Spine","rotation",lambda t,u:(-.025,0,.045*sin(TAU*u))),
        ("LeftUpperArm","rotation",lambda t,u:(-.19,0,2.21+.06*sin(TAU*2*u))),
        ("RightUpperArm","rotation",lambda t,u:(-.19,0,-2.21-.06*sin(TAU*2*u))),
        ("LeftForeArm","rotation",lambda t,u:(-.05,0,.35)),
        ("RightForeArm","rotation",lambda t,u:(-.05,0,-.35)),
        ("Head","rotation",lambda t,u:(resting_head_pitch+.022*sin(TAU*2*u),0,0)),
        ("Jaw","rotation",lambda t,u:(.31,0,0)),
        ("Mouth","scale",lambda t,u:(1.04,1.78,1)),
        ("Tail1","rotation",lambda t,u:(0,.19*sin(TAU*2*u),0)),
    ]+finger_motion("Left", .20, .06)+finger_motion("Right", .20, .06)+expression("Victory",2.4))
    walk = [
        ("Root","translation",lambda t,u:(0,.026*(1-math.cos(TAU*2*u)),0)),
        ("Hips","rotation",lambda t,u:(0,.06*sin(TAU*u),.035*sin(TAU*u))),
        ("Head","rotation",lambda t,u:(resting_head_pitch+.013*sin(TAU*2*u),-.035*sin(TAU*u),0)),
        ("Tail1","rotation",lambda t,u:(0,.13*sin(TAU*u),0)),
    ]
    for side, sign in [("Left",1),("Right",-1)]:
        walk += [
            (side+"UpperLeg","rotation",lambda t,u,s=sign:(.43*s*sin(TAU*u),0,0)),
            (side+"LowerLeg","rotation",lambda t,u,s=sign:(.38*max(0,-s*sin(TAU*u)),0,0)),
            (side+"Foot","rotation",lambda t,u,s=sign:(-.20*s*sin(TAU*u),0,0)),
            (side+"UpperArm","rotation",lambda t,u,s=sign:(-.27*s*sin(TAU*u),0,0)),
            (side+"ForeArm","rotation",lambda t,u,s=sign:(-.1-.07*s*sin(TAU*u),0,0)),
        ]
        for toe in range(1, 4):
            walk.append((side+f"Toe{toe}", "rotation",
                lambda t, u, s=sign, toe=toe:
                    (.18*max(0, s*sin(TAU*u))*(1 if toe == 2 else .82), 0, s*(toe-2)*.018)))
    b.animation("Walk",1.2,walk+idle_fingers()+expression("Walk",1.2))


def build():
    b = Builder()
    b.material("BodyColor", (.075,.285,.14), .82)
    b.material("BodyDetail", (.040,.098,.042), .80)
    b.material("Cream", (.40,.293,.147), .88)
    b.material("Hat", (.028,.029,.036), .94)
    b.material("HatBand", (.047,.041,.041), .86)
    b.material("HatTrim", (.040,.035,.035), .88)
    b.material("Glasses", (.115,.135,.113), .45, .56)
    b.material("GlassesRim", (.235,.251,.202), .39, .50)
    b.material("Sclera", (.235,.270,.172), .52)
    b.material("IrisRim", (.090,.133,.058), .45)
    b.material("Iris", (.139,.204,.085), .40)
    b.material("Pupil", (.013,.026,.018), .37)
    b.material("EyeHighlight", (.75,.78,.68), .25)
    b.material("MouthInterior", (.14,.022,.025), .74)
    b.material("Tongue", (.69,.18,.20), .49)
    b.material("Gold", (.62,.32,.057), .48, .36)
    b.material("GoldEdge", (.40,.18,.022), .53, .38)
    make_skeleton(b)
    make_body(b)
    make_face(b)
    make_glasses(b)
    make_hat(b)
    make_badge(b)
    compact_proportions(b)
    b.soft_surface_texture()
    b.finalize_geometry()
    make_animations(b)
    b.save()
    return b


if __name__ == "__main__":
    build()
