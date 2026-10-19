"""Smooth local skin backing for the source mesh's fused glasses cutout.

The head is sampled in cylindrical coordinates.  Missing skin is filled by a
positive-weight harmonic extension of actual surrounding skin, avoiding local
polynomial extrapolation and its colour/radius overshoot.  The original Body
is not changed.  Analytic clipping makes the two eye openings smooth even at
the regular grid's resolution.
"""
import numpy as np
from scipy.ndimage import binary_dilation, distance_transform_edt, gaussian_filter
from scipy.sparse import coo_matrix
from scipy.sparse.linalg import spsolve


EYES = ((.125, .608, .205), (-.125, .608, .205))
RX, RY, RZ = .0565, .065, .027


def _normals(p, f):
    # Weld UV copies before accumulating; the skin atlas has split vertices.
    unique, inverse = np.unique(np.round(p, 7), axis=0, return_inverse=True)
    n = np.zeros_like(unique, dtype=float)
    tri = inverse[f]
    face = np.cross(p[f[:, 1]] - p[f[:, 0]], p[f[:, 2]] - p[f[:, 0]])
    for k in range(3):
        np.add.at(n, tri[:, k], face)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    return n[inverse]


def _raster(p, f, values, width, height, ymin, ymax):
    """Rasterize the outermost radial surface, with barycentric attributes."""
    theta = np.arctan2(p[:, 0], p[:, 2] + .015)
    radius = np.hypot(p[:, 0], p[:, 2] + .015)
    out = np.zeros((height, width, 1 + values.shape[1]), dtype=float)
    depth = np.full((height, width), -np.inf)
    use = (p[f, 1].max(1) >= ymin) & (p[f, 1].min(1) <= ymax)
    for face in f[use]:
        a = theta[face].copy()
        if np.ptp(a) > np.pi:
            a[a < 0] += 2 * np.pi
        xy = np.c_[(a + np.pi) / (2 * np.pi) * width,
                   (p[face, 1] - ymin) / (ymax - ymin) * (height - 1)]
        xs, ys = xy.T
        x0, x1 = int(np.floor(xs.min())), int(np.ceil(xs.max()))
        y0, y1 = max(0, int(np.floor(ys.min()))), min(height - 1, int(np.ceil(ys.max())))
        if y1 < y0 or x1 - x0 > width // 2:
            continue
        den = ((ys[1] - ys[2]) * (xs[0] - xs[2]) +
               (xs[2] - xs[1]) * (ys[0] - ys[2]))
        if abs(den) < 1e-10:
            continue
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        b0 = ((ys[1] - ys[2]) * (xx - xs[2]) + (xs[2] - xs[1]) * (yy - ys[2])) / den
        b1 = ((ys[2] - ys[0]) * (xx - xs[2]) + (xs[0] - xs[2]) * (yy - ys[2])) / den
        b2 = 1 - b0 - b1
        bary = np.stack([b0, b1, b2], axis=-1)
        r = bary @ radius[face]
        inside = (bary.min(-1) >= -1e-7) & (r > depth[yy, xx % width])
        rows, cols = yy[inside], xx[inside] % width
        depth[rows, cols] = r[inside]
        out[rows, cols, 0] = r[inside]
        out[rows, cols, 1:] = bary[inside] @ values[face]
    return out, np.isfinite(depth)


def _periodic_dilate(mask, iterations):
    pad = iterations + 1
    wrapped = np.pad(mask, ((0, 0), (pad, pad)), mode='wrap')
    return binary_dilation(wrapped, iterations=iterations)[:, pad:-pad]


def _harmonic(values, free, dx, dy):
    """Dirichlet fill with positive weights; RGB stays inside source bounds."""
    height, width = free.shape
    free = free.copy()
    free[[0, -1]] = False
    index = np.full(free.shape, -1, dtype=int)
    index[free] = np.arange(free.sum())
    rows, cols = np.nonzero(free)
    ids = index[free]
    rr, cc, data = [ids], [ids], [np.full(len(ids), 2 / dx**2 + 2 / dy**2)]
    rhs = np.zeros((len(ids), values.shape[-1]))
    for dr, dc, w in ((-1, 0, 1/dy**2), (1, 0, 1/dy**2),
                      (0, -1, 1/dx**2), (0, 1, 1/dx**2)):
        nr, nc = rows + dr, (cols + dc) % width
        ni = index[nr, nc]
        inner = ni >= 0
        rr.append(ids[inner]); cc.append(ni[inner]); data.append(np.full(inner.sum(), -w))
        rhs[~inner] += values[nr[~inner], nc[~inner]] * w
    mat = coo_matrix((np.concatenate(data), (np.concatenate(rr), np.concatenate(cc))),
                     shape=(len(ids), len(ids))).tocsr()
    result = values.copy()
    result[free] = spsolve(mat, rhs)
    return result


def _clip_eyes(p, n, f, color):
    """Trim triangles to the true ellipse; no staircase or centre-only cut."""
    packed = np.c_[p, n, color]
    points, faces = [], []
    for face in f:
        polygon = list(packed[face])
        for cx, cy, _ in EYES:
            if not polygon or max(v[2] for v in polygon) < .12:
                continue
            def value(v):
                return ((v[0]-cx)/RX)**2 + ((v[1]-cy)/RY)**2 - .90**2
            if min(value(v) for v in polygon) >= 0:
                continue
            clipped = []
            for i, a in enumerate(polygon):
                b = polygon[(i+1) % len(polygon)]
                va, vb = value(a), value(b)
                if va >= 0:
                    clipped.append(a)
                if (va >= 0) != (vb >= 0):
                    d = b-a
                    A = (d[0]/RX)**2 + (d[1]/RY)**2
                    B = 2*((a[0]-cx)*d[0]/RX**2 + (a[1]-cy)*d[1]/RY**2)
                    roots = np.roots([A, B, va])
                    t = next(float(root.real) for root in roots
                             if abs(root.imag) < 1e-8 and -1e-7 <= root.real <= 1+1e-7)
                    clipped.append(a + np.clip(t, 0, 1)*d)
            polygon = clipped
        if len(polygon) < 3:
            continue
        start = len(points)
        points.extend(polygon)
        faces.extend([start, start+i, start+i+1] for i in range(1, len(polygon)-1))
    data = np.asarray(points)
    unique, first, inverse = np.unique(np.round(data[:, :3], 9), axis=0,
                                      return_index=True, return_inverse=True)
    data = data[first]
    faces = inverse[np.asarray(faces)]
    keep = np.linalg.norm(np.cross(data[faces[:, 1], :3]-data[faces[:, 0], :3],
                                  data[faces[:, 2], :3]-data[faces[:, 0], :3]), axis=1) > 1e-12
    n = data[:, 3:6]
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    return data[:, :3], n, faces[keep], data[:, 6:9]


def socket_surface(body, original, body_rgb):
    width, height = 800, 193
    ymin, ymax = .485, .724
    angles = np.arange(width)*2*np.pi/width - np.pi
    ys = np.linspace(ymin, ymax, height)
    aa, yy = np.meshgrid(angles, ys)
    bp = body['vertices']
    bn = body.get('normals')
    if bn is None:
        bn = _normals(bp, body['faces'])
    samples, known = _raster(bp, body['faces'], np.c_[body_rgb, bn],
                             width, height, ymin, ymax)
    _, footprint = _raster(original['vertices'], original['faces'],
                          np.zeros((len(original['vertices']), 0)),
                          width, height, ymin, ymax)
    # Interpolate behind the complete fused region, including its baked rim.
    repair = _periodic_dilate(footprint, 8)
    patch_mask = _periodic_dilate(footprint, 11)
    # The sparse solve's exterior samples must exist even in tiny mesh slits.
    nearest = distance_transform_edt(~known, return_distances=False, return_indices=True)
    samples[~known] = samples[tuple(nearest[:, ~known])]
    dx, dy = .25*2*np.pi/width, (ymax-ymin)/(height-1)
    filled = _harmonic(samples[..., :4], repair | ~known, dx, dy)
    # Sub-grid curvature smoothing is confined to the patch interior.
    smoothed = gaussian_filter(filled[..., 0], sigma=1.4, mode=('nearest', 'wrap'))
    inside = distance_transform_edt(repair, sampling=(dy, dx))
    blend = np.clip(inside/.006, 0, 1)
    blend = blend*blend*(3-2*blend)
    radius = filled[..., 0]*(1-blend) + smoothed*blend
    radius += .00025
    p = np.stack([radius*np.sin(aa), yy, radius*np.cos(aa)-.015], axis=-1)
    # A C1 collar meets each eye's front at r=.90 and the head at r=1.30.
    # Extending the eye tangent avoids sqrt(max(0, 1-r*r))'s cusp at r=1.
    for cx, cy, cz in EYES:
        r = np.sqrt(((p[..., 0]-cx)/RX)**2 + ((p[..., 1]-cy)/RY)**2)
        t = np.clip((r-.90)/.40, 0, 1)
        w = (1-t*t*(3-2*t)) * (np.cos(aa) > .5)
        tangent = cz + RZ*np.sqrt(1-.90**2) - RZ*.90/np.sqrt(1-.90**2)*(r-.90)
        p[..., 2] = p[..., 2]*(1-w) + tangent*w
    # Shared periodic vertices; only the local backing enters the GLB.
    rows, cols = np.mgrid[:height-1, :width]
    a = rows*width+cols; b = rows*width+(cols+1)%width
    c = a+width; d = b+width
    use = patch_mask[:-1] | patch_mask[1:] | np.roll(patch_mask[:-1], -1, axis=1) | np.roll(patch_mask[1:], -1, axis=1)
    f = np.stack([np.stack([a,b,c], -1), np.stack([b,d,c], -1)], -2)[use].reshape(-1,3)
    p = p.reshape(-1,3)
    n = _normals(p, f)
    # Use the existing shading across the fixed overlapping collar.
    smooth_n = samples[..., 4:7].reshape(-1,3)
    normal_mix = np.clip(inside.ravel()/.008, 0, 1)[:,None]
    n = n*normal_mix + smooth_n*(1-normal_mix)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    colors = np.clip(filled[..., 1:4].reshape(-1,3), 0, 1)
    return _clip_eyes(p, n, f, colors)
