"""Bind coordinates and surface weights for the supplied port_frontal mesh.

The temporary welded graph joins UV seams only for the weight solve. The
exported vertices, normals, UVs, triangles and textures are never welded,
resampled or sculpted. All copies of a seam vertex receive identical weights.
"""
from __future__ import annotations

import numpy as np


# Coordinates measured on the supplied asset in its original world units.
# The hat occupies y=.62..98; the actual shoulders are at y=.37, not .62.
ANCHORS = {
    "Root": (0.0, 0.0, 0.0),
    "Hips": (0.0, .133, -.028),
    "Spine": (0.0, .254, -.028),
    "Chest": (0.0, .375, -.028),
    "LeftUpperArm": (.181, .363, -.011),
    "LeftForeArm": (.240, .269, -.013),
    "LeftHand": (.251, .185, .018),
    "RightUpperArm": (-.180, .363, -.011),
    "RightForeArm": (-.240, .265, -.013),
    "RightHand": (-.250, .180, .018),
    "LeftUpperLeg": (.116, .119, -.016),
    "LeftLowerLeg": (.123, .073, .001),
    "LeftFoot": (.127, .037, .019),
    "RightUpperLeg": (-.114, .119, -.016),
    "RightLowerLeg": (-.124, .073, .001),
    "RightFoot": (-.128, .037, .019),
}


def ease(a, b, value):
    t = np.clip((value-a)/(b-a), 0.0, 1.0)
    return t*t*(3-2*t)


def solve_weights(positions, triangles):
    """Solve four pinned harmonic fields on the original surface adjacency."""
    unique, inverse = np.unique(positions, axis=0, return_inverse=True)
    tris = inverse[triangles.reshape(-1, 3)]
    edges = np.concatenate((tris[:, (0, 1)], tris[:, (1, 2)], tris[:, (2, 0)]))
    edges.sort(axis=1)
    edges = np.unique(edges, axis=0)
    edges = edges[edges[:, 0] != edges[:, 1]]
    a, b = edges.T
    conductance = 1/np.maximum(np.linalg.norm(unique[a]-unique[b], axis=1), 1e-5)
    degree = np.bincount(a, conductance, minlength=len(unique))
    degree += np.bincount(b, conductance, minlength=len(unique))
    fields = np.zeros((len(unique), 4), dtype=np.float64)
    x, y, z = unique.T
    info = []
    for column, (side, arm) in enumerate(((1, True), (-1, True), (1, False), (-1, False))):
        lateral = x*side
        if arm:
            # A sleeve-shaped domain around the hanging arm excludes the
            # front bib, tail and skull. Only its shoulder attachment is free
            # to blend into Root; the rest of the body is a Dirichlet boundary.
            domain = ((lateral > .145) & (y > .095) & (y < .432)
                      & (z > -.155) & (z < .116))
            distal = domain & (lateral > .223) & (y < .282)
            torso = (lateral < .182) & (y < .300)
            domain &= ~torso
        else:
            domain = ((lateral > .022) & (lateral < .218) & (y < .154)
                      & (z > -.109) & (z < .145))
            distal = domain & (y < .058) & (lateral > .065)
        pinned_zero = ~domain
        pinned_one = distal & domain
        if np.count_nonzero(pinned_one) < 10:
            raise ValueError("The source no longer matches the authored limb domains.")
        free = domain & ~pinned_one
        field = np.zeros(len(unique), dtype=np.float64)
        field[pinned_one] = 1.0
        # Solve only the free vertices with diagonally preconditioned CG.
        # Dirichlet pins exclude the protected surface exactly. A residual
        # threshold, rather than a fixed smoothing pass count, gates export.
        free_ids = np.flatnonzero(free)
        lookup = np.full(len(unique), -1, dtype=int)
        lookup[free_ids] = np.arange(len(free_ids))
        internal = free[a] & free[b]
        row, col, edge_w = lookup[a[internal]], lookup[b[internal]], conductance[internal]
        diagonal = degree[free]
        boundary_sum = np.bincount(a, conductance*field[b], minlength=len(unique))
        boundary_sum += np.bincount(b, conductance*field[a], minlength=len(unique))
        rhs = boundary_sum[free]
        def matvec(values):
            return (diagonal*values
                    -np.bincount(row, edge_w*values[col], minlength=len(free_ids))
                    -np.bincount(col, edge_w*values[row], minlength=len(free_ids)))
        solved = np.zeros(len(free_ids))
        residual = rhs.copy()
        direction = residual/diagonal
        rz = np.dot(residual, direction)
        error = 1.0
        for iteration in range(1000):
            product = matvec(direction)
            alpha = rz/np.dot(direction, product)
            solved += alpha*direction
            residual -= alpha*product
            error = float(np.linalg.norm(residual)/max(np.linalg.norm(rhs), 1e-12))
            if error < 1e-9:
                break
            preconditioned = residual/diagonal
            next_rz = np.dot(residual, preconditioned)
            direction = preconditioned+(next_rz/rz)*direction
            rz = next_rz
        if error >= 1e-9:
            raise ValueError(f'Limb weight solve did not converge: {error}')
        field[free] = np.clip(solved, 0, 1)
        # Smoothstep has zero derivatives at the static and rigid limits.
        # It avoids a visible slope break at each pin boundary.
        fields[:, column] = ease(.008, .992, field)
        info.append({"part": ("Left" if side == 1 else "Right")+("Arm" if arm else "Leg"),
                     "freeVertices": int(free.sum()), "iterations": iteration+1,
                     "residual": error})
    # Overlapping candidate domains are resolved by the stronger surface
    # field. A seam cannot end up attached to both a leg and a nearby hand.
    winner = np.argmax(fields, axis=1)
    fields *= np.eye(4)[winner]
    full = np.zeros((len(unique), len(ANCHORS)), dtype=np.float64)
    full[:, 0] = 1-fields.sum(axis=1)
    for column, (prefix, arm) in enumerate((("Left", True), ("Right", True), ("Left", False), ("Right", False))):
        if arm:
            # Joint weights use distance along the actual arm axis, not an
            # unrelated fraction of total height including the oversized hat.
            elbow_y = ANCHORS[prefix+"ForeArm"][1]
            wrist_y = ANCHORS[prefix+"Hand"][1]
            upper = ease(elbow_y-.038, elbow_y+.038, y)
            lower = ease(wrist_y-.027, wrist_y+.025, y)
            names = (prefix+"UpperArm", prefix+"ForeArm", prefix+"Hand")
        else:
            upper = ease(.063, .108, y)
            lower = ease(.031, .063, y)
            names = (prefix+"UpperLeg", prefix+"LowerLeg", prefix+"Foot")
        split = (upper, (1-upper)*lower, (1-upper)*(1-lower))
        for name, value in zip(names, split):
            full[:, list(ANCHORS).index(name)] = fields[:, column]*value
    # Sparse encoding: genuine zero slots use joint 0 and weight 0. Tiny
    # epsilon influences are unnecessary and would move protected vertices.
    full[full < 1e-7] = 0
    full /= full.sum(axis=1, keepdims=True)
    ids = np.argsort(-full, axis=1, kind="stable")[:, :4]
    weights = np.take_along_axis(full, ids, axis=1).astype(np.float32)
    ids[weights == 0] = 0
    # Pack exactly one Root entry per vertex with positive weight; zero
    # padding entries are legal glTF and intentionally remain exactly zero.
    return ids[inverse].astype(np.uint16), weights[inverse], {
        "weldedSolveVertices": len(unique), "sourceVertices": len(positions),
        "surfaceEdges": len(edges), "solvers": info,
        "sourceSeamsPreserved": True,
    }
