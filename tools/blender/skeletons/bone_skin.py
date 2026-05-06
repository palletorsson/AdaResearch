"""
bone_skin.py — Blender prototype for "graph with skin" bodies.

Runs inside Blender (Scripting workspace → paste → Run).
Builds a random branching skeleton as a vertex+edge mesh, then uses
Blender's Skin modifier to inflate the edges into capsule-like tubes,
then subdivides. Output is one mesh per DNA sample.

Why Skin modifier? Per-vertex radius, automatic capsule-like interpolation
along edges, handles branching joints for free. This is exactly the target
behaviour we'd want from graph_sdf.gd + smooth_union in Godot — Blender
gives us an instant visual of whether the approach produces usable form.

Tune DNA below and re-run. Each sample lands in its own collection so you
can compare.
"""

import bpy
import bmesh
import random
import math
from mathutils import Vector, Matrix

# ─── DNA ───────────────────────────────────────────────────
DNA = {
    "trunk_length":   3.0,   # initial trunk height
    "branch_count":   3,     # children per node at each level
    "depth":          4,     # recursion depth
    "length_decay":   0.65,  # each child's length = parent * decay
    "angle_spread":   45.0,  # degrees — how far children splay from parent
    "radius_base":    0.35,  # trunk radius
    "radius_decay":   0.62,  # radius shrinks per depth
    "jitter":         0.25,  # random offset per child direction
    "subdivisions":   2,     # subsurf levels for final smoothness
}

N_SAMPLES = 6      # how many organisms to generate side-by-side
SPACING   = 4.5    # X-distance between samples
SEED_BASE = 7      # changing this reshuffles everything deterministically


# ─── Skeleton graph ───────────────────────────────────────

def build_skeleton(dna, rng):
    """Returns (verts, edges, radii) — lists ready for a Blender mesh."""
    verts = [Vector((0, 0, 0))]
    edges = []
    radii = [dna["radius_base"]]

    def grow(parent_idx, direction, length, radius, depth):
        if depth == 0 or length < 0.05:
            return
        # This node
        parent_pos = verts[parent_idx]
        end_pos = parent_pos + direction * length
        new_idx = len(verts)
        verts.append(end_pos)
        edges.append((parent_idx, new_idx))
        radii.append(radius)
        # Spawn children
        n = dna["branch_count"]
        child_len = length * dna["length_decay"]
        child_rad = radius * dna["radius_decay"]
        spread = math.radians(dna["angle_spread"])
        for i in range(n):
            # Distribute children around parent direction
            phi = (i / n) * math.tau + rng.uniform(-0.3, 0.3)
            theta = spread + rng.uniform(-dna["jitter"], dna["jitter"])
            # Local spherical → vector around parent direction
            local = Vector((
                math.sin(theta) * math.cos(phi),
                math.sin(theta) * math.sin(phi),
                math.cos(theta),
            ))
            # Rotate so +Z aligns with parent direction
            up = Vector((0, 0, 1))
            if direction.length > 0 and (direction - up).length > 0.001:
                rot = up.rotation_difference(direction).to_matrix()
                new_dir = (rot @ local).normalized()
            else:
                new_dir = local.normalized()
            grow(new_idx, new_dir, child_len, child_rad, depth - 1)

    # Seed growth upward from root
    grow(0, Vector((0, 0, 1)), dna["trunk_length"], dna["radius_base"], dna["depth"])
    return verts, edges, radii


# ─── Mesh + Skin modifier ─────────────────────────────────

def create_skinned_body(name, verts, edges, radii, dna, location):
    # Build mesh from vertex/edge data (no faces — Skin modifier wraps them)
    mesh = bpy.data.meshes.new(name + "_mesh")
    mesh.from_pydata([v[:] for v in verts], edges, [])
    mesh.update()

    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    bpy.context.scene.collection.objects.link(obj)

    # Skin modifier — the key step. Inflates edges into tubes with
    # per-vertex radius. Branching joints are handled automatically.
    skin_mod = obj.modifiers.new(name="Skin", type='SKIN')
    skin_mod.use_smooth_shade = True

    # Set per-vertex radius
    skin_data = obj.data.skin_vertices[0].data
    for i, r in enumerate(radii):
        skin_data[i].radius = (r, r)
    # Mark root vertex so Skin anchors there
    if len(skin_data) > 0:
        skin_data[0].use_root = True

    # Smooth the blocky skin output
    subsurf = obj.modifiers.new(name="Subsurf", type='SUBSURF')
    subsurf.levels = dna["subdivisions"]
    subsurf.render_levels = dna["subdivisions"]

    # Simple material so it reads in the viewport
    mat = bpy.data.materials.new(name=name + "_mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.72, 0.55, 0.42, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.65
    obj.data.materials.append(mat)

    return obj


# ─── Scene setup ──────────────────────────────────────────

def clear_previous():
    """Remove any BoneSkin_* collections from prior runs."""
    for coll in list(bpy.data.collections):
        if coll.name.startswith("BoneSkin_"):
            for obj in list(coll.objects):
                bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.collections.remove(coll)


def make_collection(name):
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    return coll


# ─── Main ─────────────────────────────────────────────────

def main():
    clear_previous()
    coll = make_collection(f"BoneSkin_{SEED_BASE}")

    for i in range(N_SAMPLES):
        rng = random.Random(SEED_BASE + i * 31)
        verts, edges, radii = build_skeleton(DNA, rng)
        x = (i - (N_SAMPLES - 1) * 0.5) * SPACING
        obj = create_skinned_body(
            f"body_{i:02d}",
            verts, edges, radii,
            DNA,
            location=Vector((x, 0, 0)),
        )
        # Move to our collection (out of the default Scene Collection)
        bpy.context.scene.collection.objects.unlink(obj)
        coll.objects.link(obj)
        print(f"body_{i:02d}: {len(verts)} joints, {len(edges)} bones")

    print(f"\nGenerated {N_SAMPLES} organisms with DNA: {DNA}")


main()
