"""
cga_grammar_v3.py — BCGA-style shape grammar, working version.
Paste into Blender 4.0+ Scripting workspace → Alt+P.

v2 failed because split() couldn't track faces across successive bisects.
v3 rewrites split() around a clean primitive:

  bisect_face_axis(bm, face, axis_vec, offsets_from_low)
    Cuts ONE face with planes perpendicular to axis_vec at given offsets.
    Returns the resulting strips ordered low → high along axis_vec.
    Uses bisect_plane on exactly the target face's geom (not the whole mesh).

Grammars also beefed up so results are visually obvious:
  A — 10m block (baseline)
  B — 9m block with floors PUSHED OUT alternately (ledges visible)
  C — 10m block with actual window insets at every tile position

If split now works, B will show horizontal ledges and C will show a grid
of window recesses on every side.
"""

import bpy
import bmesh
from mathutils import Vector


# ─── Core primitive: robust face bisect ───────────────────────

def bisect_face_axis(bm, face, axis_vec, offsets_from_low):
    """Cut `face` with planes perpendicular to `axis_vec` at distances
    offsets_from_low (measured from the face's lowest projection along
    axis_vec). Returns list of face indices from low to high.
    axis_vec must be a unit vector.
    """
    if not face.is_valid:
        return []
    # Find the low extent of this face along axis_vec
    projs = [v.co.dot(axis_vec) for v in face.verts]
    low = min(projs)

    # Keep a list of CURRENT face indices from low→high
    strip_indices = [face.index]

    for off in offsets_from_low:
        plane_d = low + off
        # Grab the face to cut (always the last one — offsets must be ascending)
        bm.faces.ensure_lookup_table()
        target = None
        if strip_indices[-1] < len(bm.faces):
            target = bm.faces[strip_indices[-1]]
        if target is None or not target.is_valid:
            break

        # Verify the cut plane actually intersects this face
        tprojs = [v.co.dot(axis_vec) for v in target.verts]
        if plane_d <= min(tprojs) + 1e-4 or plane_d >= max(tprojs) - 1e-4:
            # Plane is outside the face — skip this cut
            continue

        # Geom = the target face + its edges + its verts
        geom = [target] + list(target.edges) + list(target.verts)
        res = bmesh.ops.bisect_plane(
            bm, geom=geom,
            dist=1e-5,
            plane_co=axis_vec * plane_d,
            plane_no=axis_vec,
            clear_inner=False, clear_outer=False,
        )
        # Collect valid resulting faces. bisect_plane keeps original face but
        # may invalidate it — collect any live face whose center projects near
        # the cut region we care about.
        bm.faces.ensure_lookup_table()
        new_faces = [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace) and g.is_valid]
        # bisect_plane sometimes doesn't list the kept face in res — sweep all
        # faces within the small bounding region too:
        candidate_faces = set(new_faces)

        before = None
        after = None
        for f in candidate_faces:
            cp = f.calc_center_median().dot(axis_vec)
            if cp < plane_d:
                before = f
            elif cp > plane_d:
                after = f
        if before is None or after is None:
            continue
        # Replace last index with "before", append "after"
        strip_indices[-1] = before.index
        strip_indices.append(after.index)

    return strip_indices


# ─── Extrude helper (Sinestesia pattern) ──────────────────────

def extrude_faces_by(bm, faces, amount):
    """Extrude `faces` along their average normal. Returns new top faces."""
    faces = [f for f in faces if f.is_valid]
    if not faces or amount == 0:
        return list(faces)
    avg_n = Vector()
    for f in faces:
        avg_n += f.normal
    avg_n = avg_n.normalized() if avg_n.length > 1e-6 else Vector((0, 0, 1))

    res = bmesh.ops.extrude_face_region(bm, geom=faces)
    new_verts = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
    new_faces = [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace)]
    bmesh.ops.translate(bm, verts=new_verts, vec=avg_n * amount)
    # Top faces: all their verts are in new_verts
    nvset = set(new_verts)
    return [f for f in new_faces if all(v in nvset for v in f.verts)]


def inset_faces(bm, faces, thickness, depth=0.0):
    faces = [f for f in faces if f.is_valid]
    if not faces:
        return []
    res = bmesh.ops.inset_individual(
        bm, faces=faces, thickness=thickness, depth=depth
    )
    return list(res.get("faces", []))


# ─── Split convenience ────────────────────────────────────────

def split_face(bm, face, axis_vec, pieces):
    """Given a flat face and a pieces list of
        [(size, rule), ("repeat", step, rule), ("flex", factor, rule)]
    cut the face into strips along axis_vec and dispatch each strip to
    its rule. Rule signature: rule(bm, face_index) -> None.
    """
    if not face.is_valid:
        return
    projs = [v.co.dot(axis_vec) for v in face.verts]
    total = max(projs) - min(projs)

    resolved = _resolve_pieces(pieces, total)
    if not resolved:
        return

    # Build the list of OFFSETS at which to cut (cumulative, exclusive of last)
    offsets = []
    running = 0.0
    for i, (size, _rule) in enumerate(resolved):
        if i < len(resolved) - 1:
            running += size
            offsets.append(running)

    face_idx = face.index
    strips = bisect_face_axis(bm, face, axis_vec, offsets)
    # Dispatch — strip i gets rule i
    for i, (_size, rule) in enumerate(resolved):
        if i >= len(strips):
            break
        rule(bm, strips[i])


def _resolve_pieces(pieces, total):
    """Turn a spec with (size), ('flex', factor), ('repeat', step) into a
    flat list of (size, rule) that exactly tiles `total`.
    """
    absolute = 0.0
    flex_weight = 0.0
    expanded = []
    for p in pieces:
        if isinstance(p, tuple) and len(p) == 2:
            size, rule = p
            absolute += size
            expanded.append(("abs", size, rule))
        elif isinstance(p, tuple) and p[0] == "flex":
            _, factor, rule = p
            flex_weight += factor
            expanded.append(("flex", factor, rule))
        elif isinstance(p, tuple) and p[0] == "repeat":
            _, step, rule = p
            expanded.append(("repeat", step, rule))

    remaining = max(0.0, total - absolute)
    out = []
    # First pass: resolve repeats (they eat remaining space as integer counts)
    has_repeat = any(e[0] == "repeat" for e in expanded)
    repeat_out = []
    repeat_total = 0.0
    if has_repeat:
        repeats_only = [e for e in expanded if e[0] == "repeat"]
        if len(repeats_only) == 1 and flex_weight == 0:
            _, step, rule = repeats_only[0]
            n = max(1, int(round(remaining / step)))
            each = remaining / n if n > 0 else step
            repeat_out = [(each, rule)] * n
            repeat_total = remaining
    # Second pass: emit in original order
    repeat_idx = 0
    for kind, *args in expanded:
        if kind == "abs":
            size, rule = args
            out.append((size, rule))
        elif kind == "flex":
            factor, rule = args
            space = (remaining - repeat_total)
            if flex_weight > 0:
                out.append((space * factor / flex_weight, rule))
        elif kind == "repeat":
            if repeat_idx == 0:
                out.extend(repeat_out)
                repeat_idx += 1
    return out


# ─── Face classification (the decompose primitive) ───────────

def classify(faces, tol=0.6):
    b = {"top": [], "bottom": [], "front": [], "back": [], "left": [], "right": []}
    for f in faces:
        if not f.is_valid: continue
        n = f.normal
        if n.z > tol:     b["top"].append(f)
        elif n.z < -tol:  b["bottom"].append(f)
        elif n.y < -tol:  b["front"].append(f)
        elif n.y > tol:   b["back"].append(f)
        elif n.x < -tol:  b["left"].append(f)
        elif n.x > tol:   b["right"].append(f)
    b["side"] = b["front"] + b["back"] + b["left"] + b["right"]
    return b


# ─── Grammars (v3 — visually distinct) ───────────────────────

def grammar_a_minimal(bm, seed_faces):
    """Just extrude."""
    extrude_faces_by(bm, seed_faces, 10.0)


def grammar_b_ledges(bm, seed_faces):
    """Extrude + split each side into floors + push alternating floors out."""
    extrude_faces_by(bm, seed_faces, 9.0)
    # Re-classify all faces of the whole mesh
    all_faces = [f for f in bm.faces if f.is_valid]
    buckets = classify(all_faces)

    # For each vertical side, split along Z into 3 floors, alternate push
    for side_key in ("front", "back", "left", "right"):
        for face in list(buckets[side_key]):
            if not face.is_valid:
                continue
            def push_out(bm, face_idx, depth=0.3):
                bm.faces.ensure_lookup_table()
                if face_idx >= len(bm.faces): return
                f = bm.faces[face_idx]
                if f.is_valid:
                    extrude_faces_by(bm, [f], depth)

            def noop(bm, face_idx):
                pass

            split_face(bm, face, Vector((0, 0, 1)), [
                (3.0, noop),           # ground floor (3m, no push)
                (3.0, push_out),       # 2nd floor (3m, pushed out 0.3m)
                (3.0, noop),           # 3rd floor (3m, no push)
            ])


def grammar_c_windows(bm, seed_faces):
    """Extrude + split each facade into floors + split each floor into tiles
    + inset + recess each tile to make a window."""
    extrude_faces_by(bm, seed_faces, 9.0)
    all_faces = [f for f in bm.faces if f.is_valid]
    buckets = classify(all_faces)

    def window_rule(bm, face_idx):
        bm.faces.ensure_lookup_table()
        if face_idx >= len(bm.faces): return
        f = bm.faces[face_idx]
        if not f.is_valid: return
        inner = inset_faces(bm, [f], thickness=0.15)
        if inner:
            extrude_faces_by(bm, inner, -0.25)  # push window pane back

    def noop(bm, face_idx):
        pass

    def tile_rule(bm, face_idx):
        """Inside each tile strip, split VERTICALLY: wall / window / wall."""
        bm.faces.ensure_lookup_table()
        if face_idx >= len(bm.faces): return
        f = bm.faces[face_idx]
        if not f.is_valid: return
        split_face(bm, f, Vector((0, 0, 1)), [
            (0.6, noop),
            (1.4, window_rule),
            (1.0, noop),
        ])

    def floor_rule(bm, face_idx):
        """Inside each floor strip, split HORIZONTALLY into tiles."""
        bm.faces.ensure_lookup_table()
        if face_idx >= len(bm.faces): return
        f = bm.faces[face_idx]
        if not f.is_valid: return
        # Figure out horizontal axis: perpendicular to face normal and to Z
        z = Vector((0, 0, 1))
        horiz = f.normal.cross(z)
        if horiz.length < 1e-6:
            horiz = Vector((1, 0, 0))
        horiz.normalize()
        split_face(bm, f, horiz, [
            (0.4, noop),
            ("repeat", 2.5, tile_rule),
            (0.4, noop),
        ])

    # Apply floor split to each side
    for side_key in ("front", "back", "left", "right"):
        for face in list(buckets[side_key]):
            if not face.is_valid:
                continue
            split_face(bm, face, Vector((0, 0, 1)), [
                (3.0, floor_rule),
                ("repeat", 3.0, floor_rule),
            ])


# ─── Scene scaffolding ────────────────────────────────────────

def make_rect(bm, w, d, z=0.0):
    v = [
        bm.verts.new((-w/2, -d/2, z)),
        bm.verts.new(( w/2, -d/2, z)),
        bm.verts.new(( w/2,  d/2, z)),
        bm.verts.new((-w/2,  d/2, z)),
    ]
    f = bm.faces.new(v)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    return [f]


def build(name, grammar_fn, loc):
    mesh = bpy.data.meshes.new(name + "_mesh")
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()
    seed = make_rect(bm, 8.0, 6.0, 0.0)
    grammar_fn(bm, seed)
    bmesh.ops.recalc_face_normals(bm, faces=[f for f in bm.faces if f.is_valid])
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj


def clear_previous():
    for obj in list(bpy.data.objects):
        if obj.name.startswith("CGA_"):
            bpy.data.objects.remove(obj, do_unlink=True)
    for coll in list(bpy.data.collections):
        if coll.name.startswith("CGA_"):
            bpy.data.collections.remove(coll)


def main():
    clear_previous()
    coll = bpy.data.collections.new("CGA_v3_Demos")
    bpy.context.scene.collection.children.link(coll)
    for name, fn, loc in [
        ("CGA_A_plain",   grammar_a_minimal, Vector((-14, 0, 0))),
        ("CGA_B_ledges",  grammar_b_ledges,  Vector((  0, 0, 0))),
        ("CGA_C_windows", grammar_c_windows, Vector(( 14, 0, 0))),
    ]:
        obj = build(name, fn, loc)
        bpy.context.scene.collection.objects.unlink(obj)
        coll.objects.link(obj)
        print(f"  built {name}  faces={len(obj.data.polygons)}")
    print("Done. Expected: A=plain block, B=3 floors with middle ledge, C=grid of windows")


main()
