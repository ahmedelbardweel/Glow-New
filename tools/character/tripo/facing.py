"""Per-character forward direction from the beige belly, then front-facing tiles."""
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

pos = np.fromfile('pos.bin', np.float32).reshape(-1, 3)
idx = np.fromfile('idx.bin', np.uint32).reshape(-1, 3)
comp = np.fromfile('comp.bin', np.uint8)
uv = np.fromfile('uv.bin', np.float32).reshape(-1, 2)
vn = np.fromfile('nrm.bin', np.float32).reshape(-1, 3)
tex = np.asarray(Image.open('color.jpg').convert('RGB')).astype(float)
TH, TW = tex.shape[:2]
n = int(comp.max()) + 1
out = {}
T = 300
cols = 6
sheet = Image.new('RGB', (cols * T, ((n + cols - 1) // cols) * (T + 30)), 'white')
font = ImageFont.truetype('arial.ttf', 26)
for c in range(n):
    tri = idx[comp == c]
    p = pos[tri]
    t = uv[tri].mean(1)
    col = tex[(t[:, 1] * (TH - 1)).astype(int).clip(0, TH - 1), (t[:, 0] * (TW - 1)).astype(int).clip(0, TW - 1)]
    r, g, b = col.T
    beige = (r > 150) & (g > 120) & (b < r * .85) & (r - g < 70) & (g - b > 15)
    face = np.cross(p[:, 1] - p[:, 0], p[:, 2] - p[:, 0])
    f = face[beige].sum(0)
    yaw = float(np.arctan2(f[0], f[2]))
    # Rotate so forward (+z) faces the camera.
    cy, sy = np.cos(-yaw), np.sin(-yaw)
    rot = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    q = (p.reshape(-1, 3) @ rot.T).reshape(p.shape)
    out[c] = dict(yaw=yaw, beige=int(beige.sum()), tris=int(len(tri)))
    u, v, d = q[..., 0], q[..., 1], q[..., 2]
    lo_u, hi_u, lo_v, hi_v = u.min(), u.max(), v.min(), v.max()
    s = (T - 20) / max(hi_u - lo_u, hi_v - lo_v)
    x = ((u - (lo_u + hi_u) / 2) * s + T / 2).mean(1).astype(int).clip(0, T - 1)
    y = (((lo_v + hi_v) / 2 - v) * s + T / 2).mean(1).astype(int).clip(0, T - 1)
    nrm = vn[tri].mean(1) @ rot.T
    nrm /= np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-12
    shade = np.clip(nrm @ np.array([.3, .5, .81]), 0, 1) * .7 + .35
    img = np.full((T, T, 3), 255, np.uint8)
    order = np.argsort(d.mean(1))
    img[y[order], x[order]] = np.clip(col * shade[:, None], 0, 255).astype(np.uint8)[order]
    sheet.paste(Image.fromarray(img), ((c % cols) * T, (c // cols) * (T + 30) + 30))
    ImageDraw.Draw(sheet).text(((c % cols) * T + 10, (c // cols) * (T + 30)), f'#{c} yaw {np.degrees(yaw):.0f}', fill=(200, 0, 0), font=font)
sheet.save('facing.png')
json.dump(out, open('facing.json', 'w'), indent=1)
print(json.dumps(out))
