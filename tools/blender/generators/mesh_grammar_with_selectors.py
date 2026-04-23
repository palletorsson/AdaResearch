# mesh_grammar_with_selectors.py — Prototype selector-driven mesh grammar.
#
# Proves the concept before porting: a grammar is a list of (selector, op)
# pairs. At each step, the selector picks a set of faces, the op mutates
# just those, and faces can be TAGGED so later rules match against them.
#
# Run in Blender's Scripting workspace (Alt+P). Creates three cubes side
# by side, each driven by a different grammar, to show how selectors
# change the emergent shape.

import bpy
import bmesh
from mathutils import Vector
import math
import random

# ─── Selectors ─────────────────────────────────────────────────
# A selector takes a bmesh and returns a list of BMFaces.

def sel_all(bm):
    return list(bm.faces)

def sel_top(bm):
    """Faces whose normal points up."""
    return [f for f in bm.faces if f.normal.z > 0.9]

def sel_sides(bm):
    """Faces whose normal is roughly horizontal."""
    return [f for f in bm.faces if abs(f.normal.z) < 0.5]

def sel_tag(tag):
    """Faces carrying a given tag in their face.material_index slot used as tag."""
    def _sel(bm):
        return [f for f in bm.faces if f.material_index == tag]
    return _sel

def sel_random(fraction, seed):
    rng = random.Random(seed)
    def _sel(bm):
        faces = list(bm.faces)
        k = max(1, int(len(faces) * fraction))
        return rng.sample(faces, min(k, len(faces)))
    return _sel

def sel_largest(n):
    def _sel(bm):
        faces = sorted(bm.faces, key=lambda f: f.calc_area(), reverse=True)
        return faces[:n]
    return _sel


# ─── Operations ────────────────────────────────────────────────
# An op takes (bm, faces) and mutates. It may return new faces to tag.

def op_inset(amount):
    def _op(bm, faces):
        if not faces: return []
        res = bmesh.ops.inset_individual(bm, faces=faces, thickness=amount, depth=0.0)
        return res.get("faces", [])
    return _op

def op_extrude(height):
    def _op(bm, faces):
        if not faces: return []
        res = bmesh.ops.extrude_face_region(bm, geom=faces)
        new_geom = res["geom"]
        new_verts = [v for v in new_geom if isinstance(v, bmesh.types.BMVert)]
        new_faces = [f for f in new_geom if isinstance(f, bmesh.types.BMFace)]
        for v in new_verts:
            v.co += v.normal * 0  # extrude_face_region doesn't auto-translate
        # Translate the new vertices along their face normals
        avg_normal = sum((f.normal for f in faces), Vector()).normalized()
        for v in new_verts:
            v.co += avg_normal * height
        return new_faces
    return _op

def op_scale(factor):
    def _op(bm, faces):
        for f in faces:
            center = f.calc_center_median()
            for v in f.verts:
                v.co = center + (v.co - center) * factor
        return []
    return _op

def op_tag(tag_id):
    def _op(bm, faces):
        for f in faces:
            f.material_index = tag_id
        return []
    return _op


# ─── Grammar engine ────────────────────────────────────────────

class Rule:
    def __init__(self, selector, operation, tag_result=None):
        self.selector = selector
        self.operation = operation
        self.tag_result = tag_result  # tag_id to apply to new faces, or None

    def apply(self, bm):
        faces = self.selector(bm)
        result_faces = self.operation(bm, faces)
        if self.tag_result is not None:
            for f in result_faces:
                f.material_index = self.tag_result


def run_grammar(bm, rules, steps):
    for _ in range(steps):
        for rule in rules:
            rule.apply(bm)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


# ─── Build seed + apply grammar → Blender object ───────────────

def make_object(name, location, grammar, steps):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    bm = bmesh.new()
    bm.from_mesh(obj.data)

    run_grammar(bm, grammar, steps)

    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    # Smooth shade
    for p in obj.data.polygons:
        p.use_smooth = False  # keep hard edges — shows the steps clearly


# ─── Three grammars demonstrating the selector idea ─────────────

GRAMMAR_A_TOWER = [
    # Only top face: inset, extrude, repeat. Makes a stacked tower.
    Rule(sel_top, op_inset(0.15)),
    Rule(sel_top, op_extrude(0.4)),
]

GRAMMAR_B_CORAL = [
    # Random 40% of faces each step: inset + extrude. Coral-like bumps.
    Rule(sel_random(0.4, seed=3), op_inset(0.2)),
    Rule(sel_random(0.4, seed=3), op_extrude(0.3)),
]

GRAMMAR_C_TAGGED = [
    # Tag the top face as 'stem', only extrude stem, then re-tag its new top.
    Rule(sel_top, op_tag(1)),         # tag top face = material_index 1
    Rule(sel_tag(1), op_inset(0.1)),  # inset only tagged
    Rule(sel_tag(1), op_extrude(0.35)),  # extrude only tagged
    Rule(sel_all, op_tag(0)),         # clear all tags
    Rule(sel_top, op_tag(1)),         # re-tag new top
]


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()


def main():
    clear_scene()
    STEPS = 4
    make_object("A_Tower",  ( 0, 0, 0), GRAMMAR_A_TOWER,  STEPS)
    make_object("B_Coral",  ( 3, 0, 0), GRAMMAR_B_CORAL,  STEPS)
    make_object("C_Tagged", ( 6, 0, 0), GRAMMAR_C_TAGGED, STEPS)
    print(f"Built 3 grammar demos at Y=0. Steps: {STEPS}")


main()
