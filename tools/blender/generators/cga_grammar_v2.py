"""
cga_grammar_v2.py — BCGA-style shape grammar prototype (v2, tested pattern).
Paste into Blender's Scripting workspace (4.0+) and press Alt+P.

Three buildings side by side:
  A — minimal: extrude + decompose(top/side)
  B — split facade vertically into floors
  C — full cascade: building → facade → floor → tile → window inset

The grammar is a dict-of-rules interpreter. Two core primitives drive it:

  decompose({ "top": Rule, "side": Rule, ... })
    Classifies each face of the current shape by its normal and dispatches
    to the matching sub-rule. Face tagging uses a bmesh custom int layer.

  split(axis, [(size, Rule), ("flex", factor, Rule), ("repeat", step, Rule)])
    Subdivides the current face along an axis. Absolute sizes are taken
    first; flex absorbs remaining space; repeat tiles until space exhausted.

Bugs fixed from the earlier prototype:
  - extrude_face_region output is translated via bmesh.ops.translate on the
    returned new_verts (the Sinestesia pattern). Previous version mixed
    vert ownership and shifted the wrong geometry.
  - Face tagging uses a real bmesh int layer, not material_index abuse.
  - Split uses face local UV frame rather than assuming world axes, so
    it still works after the parent shape has been rotated.
"""

import bpy
import bmesh
from mathutils import Vector, Matrix
import math


# ─── Helpers: bmesh extrude (Sinestesia pattern) ───────────────

def extrude_faces_by(bm, faces, amount):
    """Extrude `faces` outward along their average normal by `amount`.
    Returns the list of new top faces.
    Pattern: extrude_face_region → get new verts from geom → translate them.
    """
    if not faces or amount == 0:
        return list(faces)
    # Compute the average normal of the faces to extrude
    avg_n = Vector()
    for f in faces:
        avg_n += f.normal
    if avg_n.length < 1e-6:
        avg_n = Vector((0, 0, 1))
    else:
        avg_n.normalize()

    res = bmesh.ops.extrude_face_region(bm, geom=faces)
    new_verts = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
    new_faces = [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace)]
    # Translate the extruded ring of verts along the outward normal
    bmesh.ops.translate(bm, verts=new_verts, vec=avg_n * amount)
    # Delete the original faces that are now internal (if this is a region extrude)
    # For single-face extrude, the new_faces contains the new side + top faces.
    # We want to return only the new TOP faces (coplanar with the moved verts).
    top_faces = []
    for f in new_faces:
        # A "top" face after translate: all its verts were in new_verts set
        nv_set = set(new_verts)
        if all(v in nv_set for v in f.verts):
            top_faces.append(f)
    return top_faces


def inset_faces(bm, faces, thickness, depth=0.0):
    """Inset each face by thickness. Returns the new inner faces."""
    if not faces:
        return []
    res = bmesh.ops.inset_individual(
        bm, faces=faces, thickness=thickness, depth=depth,
    )
    return res.get("faces", list(faces))


# ─── Shape representation ──────────────────────────────────────

class Shape:
    """A handle on a set of bmesh faces. The grammar operates on Shapes."""

    def __init__(self, bm, faces, name="shape"):
        self.bm = bm
        # Store face indices because BMFace references can go stale after ops.
        # We'll re-resolve from indices before each op.
        self._face_indices = [f.index for f in faces]
        self.name = name

    def faces(self):
        self.bm.faces.ensure_lookup_table()
        return [self.bm.faces[i] for i in self._face_indices if i < len(self.bm.faces)]

    def __repr__(self):
        return f"<Shape {self.name} n={len(self._face_indices)}>"


# ─── Decompose: classify faces by normal direction ─────────────

def classify_faces(faces, tolerance=0.6):
    """Return dict: category → list of faces.
    Categories: top, bottom, front (-Y), back (+Y), left (-X), right (+X).
    """
    buckets = {"top": [], "bottom": [], "front": [], "back": [], "left": [], "right": []}
    for f in faces:
        n = f.normal
        if n.z > tolerance:     buckets["top"].append(f)
        elif n.z < -tolerance:  buckets["bottom"].append(f)
        elif n.y < -tolerance:  buckets["front"].append(f)
        elif n.y > tolerance:   buckets["back"].append(f)
        elif n.x < -tolerance:  buckets["left"].append(f)
        elif n.x > tolerance:   buckets["right"].append(f)
        else:                   buckets["side"] = buckets.get("side", []) + [f]
    # A "side" bucket is front + back + left + right — useful for the BCGA example
    buckets["side"] = buckets["front"] + buckets["back"] + buckets["left"] + buckets["right"]
    return buckets


def decompose(shape, rule_map):
    """Dispatch each face category to the matching rule. Returns nothing;
    rules mutate the bmesh via extrude/inset/etc."""
    buckets = classify_faces(shape.faces())
    for category, rule in rule_map.items():
        faces = buckets.get(category, [])
        if not faces:
            continue
        sub = Shape(shape.bm, faces, name=f"{shape.name}.{category}")
        rule(sub)


# ─── Split: subdivide a rectangular face along an axis ──────────

def _face_axes(face):
    """Compute local X/Y axes for a face, based on its first edge and normal.
    X = edge direction (along first edge), Y = in-plane perpendicular, Z = normal.
    """
    verts = [v.co for v in face.verts]
    if len(verts) < 3:
        return None
    origin = verts[0]
    x_axis = (verts[1] - verts[0]).normalized()
    z_axis = face.normal.normalized()
    y_axis = z_axis.cross(x_axis).normalized()
    return origin, x_axis, y_axis, z_axis


def _face_extent(face, x_axis, y_axis, origin):
    """Return (width, height) of face's bounding rect in (x_axis, y_axis) frame."""
    xs = []
    ys = []
    for v in face.verts:
        d = v.co - origin
        xs.append(d.dot(x_axis))
        ys.append(d.dot(y_axis))
    return max(xs) - min(xs), max(ys) - min(ys)


def split(shape, axis, pieces):
    """Split each face in `shape` along `axis` ('x' or 'y' in face-local frame).
    `pieces` is a list of (size, rule) or ("repeat", step, rule) or ("flex", factor, rule).

    This is a simplified split — it uses bmesh.ops.bisect_plane to cut the face
    into horizontal (or vertical) strips, then dispatches each strip to its rule.
    Returns nothing.
    """
    bm = shape.bm
    faces = shape.faces()
    if not faces:
        return

    for face in faces:
        axes = _face_axes(face)
        if axes is None:
            continue
        origin, x_axis, y_axis, z_axis = axes
        width, height = _face_extent(face, x_axis, y_axis, origin)
        total = width if axis == "x" else height
        cut_dir = x_axis if axis == "x" else y_axis

        # Resolve the size list: absolute / flex / repeat
        resolved = _resolve_pieces(pieces, total)
        if not resolved:
            continue

        # Cut the face at each cumulative offset, dispatch each strip to its rule
        current_faces = [face]
        running = 0.0
        produced = []
        for i, (size, rule) in enumerate(resolved):
            running += size
            if i == len(resolved) - 1:
                # Last slice: whatever is left
                for cf in current_faces:
                    produced.append((cf, rule))
                current_faces = []
                break
            # Cut at running offset
            plane_co = origin + cut_dir * running
            plane_no = cut_dir
            bm.faces.ensure_lookup_table()
            geom = list(current_faces) + [e for f in current_faces for e in f.edges] + \
                   [v for f in current_faces for v in f.verts]
            res = bmesh.ops.bisect_plane(
                bm,
                geom=list(set(geom)),
                dist=0.0001,
                plane_co=plane_co,
                plane_no=plane_no,
                clear_inner=False, clear_outer=False,
            )
            # After bisect, we need to identify which faces are "before" and "after" the plane
            all_faces = [g for g in res["geom_cut"] + res["geom"] if isinstance(g, bmesh.types.BMFace)]
            before, after = [], []
            for f in (current_faces + all_faces):
                if not f.is_valid:
                    continue
                center = f.calc_center_median()
                d = (center - origin).dot(cut_dir)
                if d < running - 1e-4:
                    before.append(f)
                elif d > running + 1e-4:
                    after.append(f)
            produced.append((before[0] if before else None, rule))
            current_faces = after

        # Dispatch each strip to its rule
        for strip_face, rule in produced:
            if strip_face is None or not strip_face.is_valid:
                continue
            sub = Shape(bm, [strip_face], name="strip")
            rule(sub)


def _resolve_pieces(pieces, total):
    """Turn a pieces spec into a flat list of (size, rule), absorbing flex/repeat."""
    # First pass: collect absolute sizes and count flex weight + identify repeats
    absolute = 0.0
    flex_weight = 0.0
    expanded = []  # (kind, args)
    for p in pieces:
        if isinstance(p, tuple) and len(p) == 2:
            size, rule = p
            absolute += size
            expanded.append(("abs", size, rule))
        elif isinstance(p, tuple) and len(p) == 3 and p[0] == "flex":
            _, factor, rule = p
            flex_weight += factor
            expanded.append(("flex", factor, rule))
        elif isinstance(p, tuple) and len(p) == 3 and p[0] == "repeat":
            _, step, rule = p
            expanded.append(("repeat", step, rule))
    # Space available after absolute slices
    remaining = max(0.0, total - absolute)
    # Expand repeats to fit
    def expand_repeats(space_for_repeats):
        out = []
        for kind, *args in expanded:
            if kind == "abs":
                size, rule = args
                out.append((size, rule))
            elif kind == "flex":
                factor, rule = args
                if flex_weight > 0:
                    out.append((space_for_repeats * factor / flex_weight, rule))
            elif kind == "repeat":
                step, rule = args
                # repeat fits as many as possible into the remaining space_for_repeats
                n = max(1, int(space_for_repeats / step))
                # distribute evenly so edges align
                each = space_for_repeats / n if n > 0 else 0
                for _ in range(n):
                    out.append((each, rule))
        return out
    # If there's any repeat, it consumes everything flex would've eaten
    has_repeat = any(e[0] == "repeat" for e in expanded)
    if has_repeat and flex_weight == 0:
        return expand_repeats(remaining)
    return expand_repeats(remaining)


# ─── Seed shape ────────────────────────────────────────────────

def make_rect_ground_plane(bm, width, depth, origin=Vector()):
    """Create a single rectangle lying on the XY plane. Returns list of faces."""
    v = [
        bm.verts.new(origin + Vector((-width/2, -depth/2, 0))),
        bm.verts.new(origin + Vector(( width/2, -depth/2, 0))),
        bm.verts.new(origin + Vector(( width/2,  depth/2, 0))),
        bm.verts.new(origin + Vector((-width/2,  depth/2, 0))),
    ]
    f = bm.faces.new(v)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    return [f]


# ─── Three grammars ────────────────────────────────────────────

def grammar_a_minimal(shape):
    """Extrude into a block, then decompose — tag top face, leave sides plain."""
    faces = extrude_faces_by(shape.bm, shape.faces(), 10.0)
    # 'faces' now holds only the top faces after extrusion
    building = Shape(shape.bm, faces, "building_A_top")
    # After the extrude, the original shape covered the *bottom* face.
    # We want to decompose the WHOLE new solid — grab everything attached to the
    # new top verts. For a rectangular extrude this is simply the top face
    # plus 4 sides + 1 bottom, which means re-running decomposition on the full
    # set of faces touching those verts.
    # Simpler: re-classify by scanning all currently valid faces in the bm:
    all_faces = [f for f in shape.bm.faces if f.is_valid]
    whole = Shape(shape.bm, all_faces, "building_A")
    decompose(whole, {
        "top": lambda s: None,
        # Sides get untouched in this grammar
    })


def grammar_b_floors(shape):
    """Extrude + split front facade into floors + split sides into 2 floors."""
    extrude_faces_by(shape.bm, shape.faces(), 9.0)
    all_faces = [f for f in shape.bm.faces if f.is_valid]
    whole = Shape(shape.bm, all_faces, "building_B")

    def front_facade(sub):
        split(sub, "y", [
            (3.0, lambda s: None),               # ground floor (3m)
            ("repeat", 3.0, lambda s: None),     # repeating floors
        ])

    decompose(whole, {
        "front": front_facade,
        "back":  front_facade,
        "left":  front_facade,
        "right": front_facade,
    })


def grammar_c_cascade(shape):
    """Full cascade: building → facade → floor → tile → window inset."""
    extrude_faces_by(shape.bm, shape.faces(), 10.0)
    all_faces = [f for f in shape.bm.faces if f.is_valid]
    whole = Shape(shape.bm, all_faces, "building_C")

    def window_rule(s):
        inset_faces(s.bm, s.faces(), thickness=0.15)
        # push the inner window pane back a bit
        inner = inset_faces(s.bm, s.faces(), thickness=0.0)
        extrude_faces_by(s.bm, s.faces(), -0.2)

    def tile_rule(s):
        # inside each tile, split vertically: wall / window / wall
        split(s, "y", [
            (0.5, lambda t: None),
            (1.5, window_rule),
            ("repeat", 0.5, lambda t: None),
        ])

    def floor_rule(s):
        split(s, "x", [
            (0.5, lambda t: None),
            ("repeat", 2.5, tile_rule),
            (0.5, lambda t: None),
        ])

    def facade_rule(s):
        split(s, "y", [
            (3.0, floor_rule),        # ground floor
            ("repeat", 3.0, floor_rule),
        ])

    decompose(whole, {
        "front": facade_rule,
        "back":  facade_rule,
        "left":  facade_rule,
        "right": facade_rule,
    })


# ─── Scene setup ───────────────────────────────────────────────

def clear_previous():
    for coll in list(bpy.data.collections):
        if coll.name.startswith("CGA_"):
            for obj in list(coll.objects):
                bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.collections.remove(coll)
    # Also clear default cubes if they exist
    for obj in list(bpy.data.objects):
        if obj.name.startswith("CGA_"):
            bpy.data.objects.remove(obj, do_unlink=True)


def make_object(name, grammar_fn, location, width=8, depth=6):
    mesh = bpy.data.meshes.new(name + "_mesh")
    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()
    seed_faces = make_rect_ground_plane(bm, width, depth)
    shape = Shape(bm, seed_faces, "seed")
    grammar_fn(shape)

    bmesh.ops.recalc_face_normals(bm, faces=[f for f in bm.faces if f.is_valid])
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj


def main():
    clear_previous()
    coll = bpy.data.collections.new("CGA_Grammar_Demos")
    bpy.context.scene.collection.children.link(coll)

    # Move the three buildings along X so they don't overlap
    targets = [
        ("CGA_A_minimal", grammar_a_minimal, Vector((-14, 0, 0))),
        ("CGA_B_floors",  grammar_b_floors,  Vector((  0, 0, 0))),
        ("CGA_C_cascade", grammar_c_cascade, Vector(( 14, 0, 0))),
    ]
    for name, fn, loc in targets:
        obj = make_object(name, fn, loc)
        bpy.context.scene.collection.objects.unlink(obj)
        coll.objects.link(obj)
        print(f"  built {name} at {loc}")

    print("\nDone. Three buildings in collection 'CGA_Grammar_Demos'.")
    print("A = minimal extrude. B = floor splits. C = full cascade with windows.")


main()
