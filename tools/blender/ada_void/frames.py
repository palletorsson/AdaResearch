"""frames.py — Godot (Y-up) <-> Blender (Z-up) for a Void record. Pure Python.

A Void record places a mount by `position [x, z]`, `height` (Godot y), `facing`
(degrees about Godot +Y) and a uniform `scale` (commons/void/rooms.json; the web
viewer's listEntries in ada_encyclopedia/src/components/lab-editor/void-model.ts
is the reference). Godot's GLTFDocument writes Godot axes straight into the glb
(both are Y-up, right-handed); Blender's glTF importer then turns glTF Y-up into
Blender Z-up with the fixed change of basis

    blender = C * godot,   C: (x, y, z) -> (x, -z, y)

so a mount's Blender matrix is C * G * C^T and its translation C * p. A rotation
about Godot +Y becomes a rotation about Blender +Z by the same angle (C is a
proper rotation, +90 degrees about X). Everything here is plain lists so the
module can be checked without bpy (tools/live_update_blender_test.py does).
"""
from __future__ import annotations

import math

# Change of basis Godot -> Blender, row-major 3x3.
C = [[1.0, 0.0, 0.0],
     [0.0, 0.0, -1.0],
     [0.0, 1.0, 0.0]]
CT = [[1.0, 0.0, 0.0],
      [0.0, 0.0, 1.0],
      [0.0, -1.0, 0.0]]


def mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def mat_vec(m, v):
    return [sum(m[i][k] * v[k] for k in range(3)) for i in range(3)]


def transpose(m):
    return [[m[j][i] for j in range(3)] for i in range(3)]


def godot_to_blender_point(p):
    """Godot (x, y, z) -> Blender (x, -z, y)."""
    return [float(p[0]), -float(p[2]), float(p[1])]


def blender_to_godot_point(p):
    """Blender (x, y, z) -> Godot (x, z, -y)."""
    return [float(p[0]), float(p[2]), -float(p[1])]


def godot_to_blender_basis(g):
    """Conjugate a Godot rotation matrix (row-major) into Blender axes."""
    return mat_mul(mat_mul(C, g), CT)


def blender_to_godot_basis(b):
    return mat_mul(mat_mul(CT, b), C)


def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


def godot_euler_to_basis(deg):
    """Godot's default Euler order YXZ: basis = Ry(y) * Rx(x) * Rz(z) (degrees in)."""
    x, y, z = (math.radians(float(v)) for v in deg)
    return mat_mul(mat_mul(rot_y(y), rot_x(x)), rot_z(z))


def basis_to_godot_euler(m):
    """Inverse of godot_euler_to_basis (Godot Basis.get_euler, order YXZ), degrees out."""
    sx = -m[1][2]
    sx = max(-1.0, min(1.0, sx))
    x = math.asin(sx)
    if abs(sx) < 0.999999:
        y = math.atan2(m[0][2], m[2][2])
        z = math.atan2(m[1][0], m[1][1])
    else:  # gimbal lock: put everything on y
        y = math.atan2(-m[2][0], m[0][0])
        z = 0.0
    return [math.degrees(x), math.degrees(y), math.degrees(z)]


def godot_matrix16_to_blender(m16):
    """A Godot Transform3D as the exporter's 16-float column-major list
    (basis.x, basis.y, basis.z, origin) -> (blender 3x3 row-major, blender location)."""
    # column-major: columns are basis.x, basis.y, basis.z; row-major rows follow
    g = [[m16[0], m16[4], m16[8]],
         [m16[1], m16[5], m16[9]],
         [m16[2], m16[6], m16[10]]]
    return godot_to_blender_basis(g), godot_to_blender_point([m16[12], m16[13], m16[14]])


# ── mounts ─────────────────────────────────────────────────────────────────

def mount_to_blender(position_xz, height, facing_deg, scale=1.0):
    """Record transform -> (location, rotation_euler (radians, XYZ), scale) for the mount Empty."""
    x, z = float(position_xz[0]), float(position_xz[1])
    loc = godot_to_blender_point([x, float(height), z])
    rot = (0.0, 0.0, math.radians(float(facing_deg)))
    s = float(scale)
    return loc, rot, (s, s, s)


def normalize_deg(a):
    a = float(a) % 360.0
    if a < 0:
        a += 360.0
    if abs(a - 360.0) < 1e-6:
        a = 0.0
    return a


def mount_from_blender(location, rotation_z_rad, scale_x=1.0):
    """Mount Empty -> position [x, z], height, facing (degrees in [0, 360)), scale."""
    p = blender_to_godot_point(location)
    return [p[0], p[2]], p[1], normalize_deg(math.degrees(float(rotation_z_rad))), float(scale_x)


def part_to_blender(local_position, local_rotation_deg):
    """A composite artifact's part (Godot local position + YXZ Euler degrees) -> Blender
    (location, 3x3 rotation row-major) relative to the artifact mount."""
    return godot_to_blender_point(local_position), godot_to_blender_basis(godot_euler_to_basis(local_rotation_deg))


def part_from_blender(location, basis3x3):
    return blender_to_godot_point(location), basis_to_godot_euler(blender_to_godot_basis(basis3x3))


# ── writing back without noise ─────────────────────────────────────────────

def settle(value, original, places=3, tol=1e-3):
    """Round a read-back number; keep the record's own value when it is within tol
    (so an untouched object never rewrites 0 as 0.0 or -6.5 as -6.4999999)."""
    v = round(float(value), places)
    if original is not None:
        try:
            if abs(float(original) - float(value)) <= tol:
                return original
        except (TypeError, ValueError):
            pass
    if v == int(v):
        return int(v)
    return v


def settle_list(values, originals, places=3, tol=1e-3):
    out = []
    for i, v in enumerate(values):
        o = originals[i] if originals is not None and i < len(originals) else None
        out.append(settle(v, o, places, tol))
    return out


def settle_facing(value, original):
    """Facing compares on the circle: 359.9995 is 0."""
    v = normalize_deg(value)
    if original is not None:
        try:
            d = abs(normalize_deg(original) - v)
            if min(d, 360.0 - d) <= 1e-3:
                return original
        except (TypeError, ValueError):
            pass
    return settle(v, None)


def settle_angles(values, originals, tol=1e-3):
    """Euler components compare on the circle: a read-back -180 is the record's 180."""
    out = []
    for i, v in enumerate(values):
        o = originals[i] if originals is not None and i < len(originals) else None
        if o is not None:
            try:
                d = abs(normalize_deg(o) - normalize_deg(v))
                if min(d, 360.0 - d) <= tol:
                    out.append(o)
                    continue
            except (TypeError, ValueError):
                pass
        a = float(v) % 360.0
        if a > 180.0:
            a -= 360.0
        out.append(settle(a, None))
    return out


def rotate_y_xz(p, angle_deg):
    """The web viewer's rotateY on a Godot-frame vector (void-model.ts)."""
    c, s = math.cos(math.radians(angle_deg)), math.sin(math.radians(angle_deg))
    return [c * p[0] + s * p[2], p[1], -s * p[0] + c * p[2]]
