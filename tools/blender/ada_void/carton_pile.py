r"""carton_pile.py — the sorting line's AGAIN / YET cartons in Blender: a glossy heap, the line itself, a film of it.

The heap (a still):

    blender -b -P tools/blender/ada_void/carton_pile.py -- --out ada_run/blender/carton_pile.png \
        [--count 90] [--seed 7] [--frames 240] [--column 3] [--dist 6.0] [--exposure -1.2] [--samples 256] \
        [--res 1920x1080] [--blend ada_run/blender/carton_pile.blend]

The cartons are printed exactly as commons/artifacts/cube_sorting_line/carton_skins.gd prints them — paper, two accent
stripes, the word in its 5x7 glyphs, a barcode, the same on every face — redrawn here pixel for pixel (a 128-pixel
tile per edition). A heap in the game exists only while the line runs, so the heap is made the way the game makes
it: cartons dropped onto a floor under gravity (Blender's rigid bodies), seeded, then photographed in a studio:
lacquered cartons on a dark reflective floor, a softbox, two coloured rims, shallow depth of field. Palle, 3 Nov
2026: "simulate something like this in blender ... render it in a super glossy cool format".

The line (--line): the sorting line's own belt and the large box shelf, imported from the Void's exported glbs
(floor 7's cube_sorting_line, the ReturnToTheBoxLibrary hall's prefab_box_library), cartons jammed on the belt and
the missed ones tipped off its end; every imported surface gets the same lacquer. The defaults since 3 Nov: seen from
the works side (the operator's), the shelf behind the baskets (--shelf-x 6.4), the control stand left out
(--keep-controls puts it back). The still from the visitors' aisle:

    blender -b -P tools/blender/ada_void/carton_pile.py -- --line --shelf-x -6.2 --keep-controls --count 45 \
        --cam=-2.4,-8.6,2.3 --look=-2.0,-0.2,1.1 --lens 28 --out ada_run/blender/carton_line.png

The film (--line --fill N): the line RUNS. The belt is a loop of unrendered slats that carry the cartons by friction,
as a real conveyor does; the feeder lets a carton go above the belt at most every --every frames, and only while the
spot under it is clear (the game's line holds production the same way); the end tips them off. N frames are simulated
in ONE pass and filmed on the way, with a step that grows from --step-start to --step-end (the start at almost real
speed, the filling compressed); Blender's own ffmpeg encodes the mp4. --wall adds an L of 1 m walls around the belt's
end, so the spill rises in the corner instead of spreading and the line jams:

    blender -b -P tools/blender/ada_void/carton_pile.py -- --line --wall --fill 4800 \
        --out ada_run/blender/carton_fill.mp4 --res 1280x720 --samples 48

tools/blender/ada_void/README.md lists the six ways the film lied before it was honest.
"""
from __future__ import annotations

import argparse
import math
import os
import random
import sys
import time

import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))

GLYPHS = {"A": [14, 17, 17, 31, 17, 17, 17], "G": [14, 17, 16, 23, 17, 17, 14], "I": [31, 4, 4, 4, 4, 4, 31],
          "N": [17, 25, 25, 21, 19, 19, 17], "Y": [17, 17, 10, 4, 4, 4, 4], "E": [31, 16, 16, 30, 16, 16, 31],
          "T": [31, 4, 4, 4, 4, 4, 4]}
EDITIONS = {0: ("AGAIN", "f2efe5", "cc473c"), 1: ("YET", "c5e2cf", "167c79")}
INK = "19333d"


def srgb(h: str) -> np.ndarray:
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)] + [1.0])


def tile(kind: int) -> bpy.types.Image:
    """one face of carton_skins.gd's atlas: 128 x 128, top row first (Godot's image y runs down)"""
    word, paper, accent = EDITIONS[kind]
    a = np.empty((128, 128, 4)); a[:] = srgb(paper)
    rect = lambda x, y, w, h, c: a.__setitem__((slice(y, y + h), slice(x, x + w)), srgb(c))
    rect(0, 12, 128, 9, accent)
    rect(0, 106, 128, 10, accent)
    left = (128 - len(word) * 18 + 3) // 2
    for k, ch in enumerate(word):
        for y in range(7):
            for x in range(5):
                if GLYPHS[ch][y] & (1 << (4 - x)):
                    rect(left + k * 18 + x * 3, 42 + y * 3, 3, 3, INK)
    for bar in range(23):
        rect(28 + bar * 3, 82, 2 if bar % 3 == 0 else 1, 13, INK)
    img = bpy.data.images.new(f"carton_{word}", 128, 128, alpha=False)
    img.pixels.foreach_set(np.ascontiguousarray(a[::-1], dtype=np.float32).ravel())   # Blender's rows run up
    img.update()   # without it the texture stays black: the generated buffer is what renders
    img.pack()
    img.colorspace_settings.name = "sRGB"
    return img


def glossy_carton(kind: int, coat: float) -> bpy.types.Material:
    word = EDITIONS[kind][0]
    m = bpy.data.materials.new(f"Carton {word} gloss")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = tile(kind)
    tex.interpolation = "Closest"   # the print's pixels stay pixels, as in the game's atlas
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.32
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = 0.025
    bsdf.inputs["Coat IOR"].default_value = 1.55
    return m


def carton_mesh(edge: float) -> bpy.types.Mesh:
    """a cube whose every face carries the whole tile, as the game's six identical UV tiles do"""
    h = edge / 2
    v = [(-h, -h, -h), (h, -h, -h), (h, h, -h), (-h, h, -h), (-h, -h, h), (h, -h, h), (h, h, h), (-h, h, h)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    me = bpy.data.meshes.new("carton")
    me.from_pydata(v, [], f)
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        # project each face onto the frame of someone looking at it from outside, so no print reads mirrored
        n = poly.normal
        up = Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((0, 1, 0))
        right = up.cross(n)
        for li in poly.loop_indices:
            p = me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv = (p.dot(right) / edge + 0.5, p.dot(up) / edge + 0.5)
    # a small bevel reads as a printed card box, not a die
    me.update()
    return me


def import_glb(path: str, coat: float, at=(0.0, 0.0, 0.0), yaw_deg: float = 0.0) -> list:
    """one exported Void glb: its meshes unparented in world space (a rigid body ignores a parent's transform), turned
    by yaw then moved, every Principled material given the cartons' lacquer"""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    place = Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(yaw_deg), 4, "Z")
    meshes = []
    for o in new:
        if o.type == "MESH":
            mw = o.matrix_world.copy()
            o.parent = None
            o.matrix_world = place @ mw
            meshes.append(o)
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    for o in meshes:
        for m in o.data.materials:
            b = m and m.use_nodes and m.node_tree.nodes.get("Principled BSDF")
            if b:
                b.inputs["Coat Weight"].default_value = 0.6 * coat
                b.inputs["Coat Roughness"].default_value = 0.04
    return meshes


def area(name, loc, target, size, energy, color):
    d = bpy.data.lights.new(name, "AREA")
    d.shape = "RECTANGLE"; d.size = size[0]; d.size_y = size[1]; d.energy = energy; d.color = color
    o = bpy.data.objects.new(name, d)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return o


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "ada_run", "blender", "carton_pile.png"))
    ap.add_argument("--blend", default="")
    ap.add_argument("--count", type=int, default=90)
    ap.add_argument("--yet", type=float, default=0.62, help="the share of YET cartons (the screenshots hold more YET)")
    ap.add_argument("--edge", type=float, default=0.3)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--frames", type=int, default=240)
    ap.add_argument("--samples", type=int, default=256)
    ap.add_argument("--res", default="1920x1080")
    ap.add_argument("--coat", type=float, default=1.0)
    ap.add_argument("--exposure", type=float, default=-1.2)   # the softbox blows the paper white at 0
    ap.add_argument("--column", type=int, default=3)   # cartons per side of the falling block; narrower piles higher
    ap.add_argument("--dist", type=float, default=6.0)   # camera stand-off in m; 4.4 fills the frame with cartons
    ap.add_argument("--line", action="store_true", help="the heap at the end of the game's own sorting line, the box shelf across the aisle")
    ap.add_argument("--models", default=os.path.join(os.path.dirname(ROOT), "ada_encyclopedia", "public", "void-models"))
    ap.add_argument("--belt", type=int, default=12, help="line: cartons jammed on the belt")
    ap.add_argument("--wall", action="store_true", help="line: an L of 1 m walls around the belt's working end")
    ap.add_argument("--keep-controls", action="store_true", help="line: keep the control stand (table, buttons, panel)")
    ap.add_argument("--shelf-x", type=float, default=6.4, help="line: the shelf's centre across x; + puts it behind the baskets "
                    "(seen from the works side, Palle 3 Nov), - across the visitors' aisle")
    ap.add_argument("--cam", default="", help="camera position x,y,z (Blender metres); default per mode")
    ap.add_argument("--look", default="", help="camera aim x,y,z")
    ap.add_argument("--lens", type=float, default=0.0)
    ap.add_argument("--fill", type=int, default=0, help="line: simulate this many frames of a running line and film it (0 = a still)")
    ap.add_argument("--every", type=int, default=12, help="fill: frames between two cartons leaving the feeder")
    ap.add_argument("--speed", type=float, default=0.9, help="fill: belt speed, m/s")
    ap.add_argument("--fps", type=int, default=24)
    ap.add_argument("--step-start", type=int, default=3, help="fill: simulated frames per film frame at the start")
    ap.add_argument("--step-end", type=int, default=16, help="fill: ... and at the end")
    ap.add_argument("--render-limit", type=int, default=0, help="fill: render only this many film frames (a test)")
    args = ap.parse_args(argv)

    scene = bpy.context.scene
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    rng = random.Random(args.seed)
    mats = [glossy_carton(0, args.coat), glossy_carton(1, args.coat)]

    # the floor: dark, glossy, a rigid body that does not move
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.name = "Floor"
    fm = bpy.data.materials.new("Floor gloss"); fm.use_nodes = True
    fb = fm.node_tree.nodes["Principled BSDF"]
    fb.inputs["Base Color"].default_value = (0.018, 0.02, 0.026, 1)
    fb.inputs["Roughness"].default_value = 0.06
    fb.inputs["Coat Weight"].default_value = 1.0
    fb.inputs["Coat Roughness"].default_value = 0.02
    floor.data.materials.append(fm)
    bpy.ops.rigidbody.world_add()
    scene.rigidbody_world.substeps_per_frame = 20
    scene.rigidbody_world.solver_iterations = 20
    bpy.ops.rigidbody.object_add({"object": floor}) if bpy.app.version < (4, 0) else None
    bpy.context.view_layer.objects.active = floor
    floor.select_set(True)
    bpy.ops.rigidbody.object_add()
    floor.rigid_body.type = "PASSIVE"
    floor.rigid_body.friction = 0.7

    heap_at = Vector((0.0, 0.0))
    belt_spots = []
    if args.line:
        # the game's line: a 5.2 m belt along y at 0.95 m, the feeder gantry at the +y end; what it misses falls off -y
        line = import_glb(os.path.join(args.models, "7-museum-point_animatedcube-25-20.glb"), args.coat)
        if not args.keep_controls:
            # the control stand (table, two buttons, the panel above them) is the only part out past x -1 on the
            # operator's side; Palle, 3 Nov: "can we remove the interface with buttons"
            def centre_x(o):
                xs = [(o.matrix_world @ Vector(c)).x for c in o.bound_box]
                return (min(xs) + max(xs)) / 2
            stand = [o for o in line if centre_x(o) < -1.0]
            for o in stand:
                bpy.data.objects.remove(o, do_unlink=True)
            line = [o for o in line if o not in stand]
            print(f"[cartons] control stand left out ({len(stand)} meshes)", flush=True)
        for o in line:   # the belt and its frame stop the cartons
            bpy.context.view_layer.objects.active = o
            for x in bpy.context.selected_objects:
                x.select_set(False)
            o.select_set(True)
            bpy.ops.rigidbody.object_add()
            o.rigid_body.type = "PASSIVE"
            o.rigid_body.collision_shape = "MESH"
            o.rigid_body.friction = 0.8
            # a mesh shape's default 4 cm margin is added OUTSIDE it: the belt's top would stand above the slats
            # and hold the cartons still
            o.rigid_body.use_margin = True
            o.rigid_body.collision_margin = 0.002
        # the large shelf, its long side along the belt, its worktable turned toward it
        import_glb(os.path.join(args.models, "12-hall-ReturnToTheBoxLibrary.glb"), args.coat, at=(args.shelf_x, -0.6, 0.0),
                   yaw_deg=-90.0 if args.shelf_x > 0 else 90.0)
        if args.wall:
            # an L of 1 m walls around the belt's working end, across its front and along the operator's side, open
            # toward the baskets: the spill is held in the corner and has to rise instead of spreading. Palle, 3 Nov:
            # "maybe L shaped 1 m wall around the work front of the conveyor"
            wm = bpy.data.materials.new("Wall lacquer"); wm.use_nodes = True
            wb = wm.node_tree.nodes["Principled BSDF"]
            wb.inputs["Base Color"].default_value = (0.3, 0.31, 0.33, 1)
            wb.inputs["Roughness"].default_value = 0.3
            wb.inputs["Coat Weight"].default_value = 0.6 * args.coat
            wb.inputs["Coat Roughness"].default_value = 0.04
            t, h = 0.12, 1.0
            x0, x1, y0, y1 = -1.6, 2.4, -4.4, -1.0   # the corner at (x0, y0); the belt's end is at y -2.6
            for name, at, size in (("Wall front", ((x0 + x1) / 2, y0 - t / 2, h / 2), (x1 - x0 + t, t, h)),
                                   ("Wall side", (x0 - t / 2, (y0 + y1) / 2, h / 2), (t, y1 - y0, h))):
                bpy.ops.mesh.primitive_cube_add(size=1.0, location=at)
                w = bpy.context.active_object
                w.name = name
                w.scale = size
                w.data.materials.append(wm)
                bpy.ops.rigidbody.object_add()
                w.rigid_body.type = "PASSIVE"
                w.rigid_body.collision_shape = "BOX"
                w.rigid_body.friction = 0.8
        heap_at = Vector((0.0, -3.45))
        top = 0.955 + args.edge / 2 + 0.01
        if args.fill:
            args.count = 0
            args.belt = 0
        # a failed line: spaced near the feeder, closing up toward the end, two riding on their neighbours, one over the edge
        ys = [1.55, 0.85, 0.2, -0.38, -0.9, -1.27, -1.62, -1.98, -2.36, -2.62, -1.1, -2.15][:args.belt]
        for k, y in enumerate(ys):
            ride = k >= 10
            belt_spots.append(((rng.uniform(-0.05, 0.05), y, top + (args.edge * 1.02 if ride else 0.0)),
                               (rng.uniform(-0.2, 0.2) if ride else 0.0, 0.0, math.radians(rng.uniform(-28, 28)))))

    # the cartons: dropped from a column, as the line's backlog tips its unsorted cartons out
    me = carton_mesh(args.edge)
    cartons = []
    for i in range(args.count + len(belt_spots)):
        kind = 1 if rng.random() < args.yet else 0
        o = bpy.data.objects.new(f"carton_{i:03d}_{EDITIONS[kind][0]}", me.copy())
        o.data.materials.append(mats[kind])
        scene.collection.objects.link(o)
        if i < len(belt_spots):
            o.location, rot = belt_spots[i]
            o.rotation_euler = Euler(rot)
        else:
            # a loose block of cartons just above one spot: it collapses into a heap instead of raining far apart
            j = i - len(belt_spots)
            per = args.column; layer, cell = divmod(j, per * per); gx, gy = divmod(cell, per)
            sp = args.edge * 1.25
            o.location = (heap_at.x + (gx - (per - 1) / 2) * sp + rng.uniform(-0.04, 0.04),
                          heap_at.y + (gy - (per - 1) / 2) * sp + rng.uniform(-0.04, 0.04),
                          args.edge * 0.75 + layer * sp + rng.uniform(0, 0.05))
            o.rotation_euler = Euler((rng.uniform(0, math.tau), rng.uniform(0, math.tau), rng.uniform(0, math.tau)))
        bpy.context.view_layer.objects.active = o
        for s in bpy.context.selected_objects: s.select_set(False)
        o.select_set(True)
        bpy.ops.rigidbody.object_add()
        o.rigid_body.collision_shape = "BOX"
        o.rigid_body.mass = 0.4
        o.rigid_body.friction = 0.85
        o.rigid_body.restitution = 0.05
        o.rigid_body.linear_damping = 0.25
        o.rigid_body.angular_damping = 0.45
        bev = o.modifiers.new("bevel", "BEVEL"); bev.width = args.edge * 0.03; bev.segments = 3; bev.limit_method = "NONE"
        cartons.append(o)
    stream = []
    if args.fill:
        args.frames = args.fill
        scene.render.fps = args.fps
        # the belt itself: a loop of slats (kinematic, unrendered) running along its top toward -y and back
        # underneath. A carton rides them by FRICTION, as on a real conveyor, so a blocked carton slips instead of
        # being driven on: carrying the cartons as kinematic bodies gave them infinite force, and once the pile
        # reached the belt every arrival ploughed into it and flung cartons over the wall
        half, z_top, z_bot, drop = 2.6, 0.957, 0.80, 0.157
        loop = 4 * half + 2 * drop
        n_slats = 41
        period = loop / args.speed * args.fps

        def on_loop(u):   # path distance -> (y, z), starting at the feeder end on top
            u %= loop
            if u < 2 * half:
                return half - u, z_top
            u -= 2 * half
            if u < drop:
                return -half, z_top - u
            u -= drop
            if u < 2 * half:
                return -half + u, z_bot
            return half, z_bot + (u - 2 * half)
        corners = [0.0, 2 * half, 2 * half + drop, 4 * half + drop]
        for i in range(n_slats):
            s0 = i * loop / n_slats
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            sl = bpy.context.active_object
            sl.name = f"belt_slat_{i:02d}"
            sl.scale = (0.46, loop / n_slats - 0.008, 0.012)
            sl.hide_render = True
            bpy.ops.rigidbody.object_add()
            sl.rigid_body.kinematic = True
            sl.rigid_body.collision_shape = "BOX"
            sl.rigid_body.friction = 1.0
            sl.rigid_body.use_margin = True
            sl.rigid_body.collision_margin = 0.002   # a 1.2 cm slat cannot hold the default 4 cm margin inside it
            us = sorted({s0, s0 + loop} | {c + k * loop for c in corners for k in (0, 1) if s0 < c + k * loop < s0 + loop})
            for u in us:
                y, z = on_loop(u) if u < s0 + loop else on_loop(s0)
                sl.location = (0.0, y, z)
                sl.keyframe_insert("location", frame=1 + (u - s0) / args.speed * args.fps)
            for fc in sl.animation_data.action.fcurves:
                for kp in fc.keyframe_points:
                    kp.interpolation = "LINEAR"
                fc.modifiers.new("CYCLES")
        drop_z = z_top + 0.006 + args.edge / 2 + 0.38   # the feeder lets go a little above the belt, as the game's does
        spawn_y = 0.6   # just past the feeder's gantry
        for k in range(args.fill // args.every):
            kind = 1 if rng.random() < args.yet else 0
            o = bpy.data.objects.new(f"stream_{k:03d}_{EDITIONS[kind][0]}", me.copy())
            o.data.materials.append(mats[kind])
            scene.collection.objects.link(o)
            o.rotation_euler = Euler((0.0, 0.0, math.radians(rng.uniform(-6, 6))))
            bpy.context.view_layer.objects.active = o
            for x in bpy.context.selected_objects:
                x.select_set(False)
            o.select_set(True)
            bpy.ops.rigidbody.object_add()
            rb = o.rigid_body
            rb.collision_shape = "BOX"; rb.mass = 0.4; rb.friction = 0.85; rb.restitution = 0.05
            rb.linear_damping = 0.25; rb.angular_damping = 0.45
            bev = o.modifiers.new("bevel", "BEVEL"); bev.width = args.edge * 0.03; bev.segments = 3; bev.limit_method = "NONE"
            # parked far below the floor, kinematic and unrendered, until the feeder takes it (in the film's loop).
            # Its curves exist from the start; the feeder only adds a key to them. Setting location from Python
            # mid-simulation does not move a kinematic body (only the first carton ever arrived that way), and
            # creating animation mid-simulation would change the scene's relations
            o.location = (40.0 + k * 0.5, 0.0, -30.0); o.keyframe_insert("location", frame=1)
            rb.kinematic = True; rb.keyframe_insert("kinematic", frame=1)
            o.hide_render = True; o.keyframe_insert("hide_render", frame=1)
            for fc in o.animation_data.action.fcurves:
                fc.keyframe_points[0].interpolation = "CONSTANT"
            stream.append(o)
        cartons += stream
        print(f"[cartons] {len(stream)} cartons for the feeder, at most one every {args.every} frames, on a belt of "
              f"{n_slats} slats at {args.speed} m/s (one loop {period:.0f} frames)", flush=True)
    scene.frame_start = 1
    scene.frame_end = args.frames
    scene.rigidbody_world.point_cache.frame_end = args.frames
    for fr in range(1, 0 if args.fill else args.frames + 1):   # step in order: the heap is what gravity left
        scene.frame_set(fr)
    tops = [o.matrix_world.translation for o in cartons[len(belt_spots):] if o.matrix_world.translation.z > -1.0] or [Vector((0, 0, 0))]
    if args.fill:   # nothing has fallen yet: aim the focus where the spill will be
        tops = [Vector((0.0, -3.3, 0.0)), Vector((0.0, -3.3, 1.6))]
    cx = sum(p.x for p in tops) / len(tops); cy = sum(p.y for p in tops) / len(tops)
    hmax = max(p.z for p in tops)
    up = sum(1 for o in cartons[:len(belt_spots)] if o.matrix_world.translation.z > 0.9)
    print(f"[cartons] {len(cartons)} settled after {args.frames} frames ({len(belt_spots)} on the belt, {up} still up there); "
          f"heap centre ({cx:.2f}, {cy:.2f}), top {hmax:.2f} m", flush=True)

    # the studio: one big softbox, two coloured rims, a low camera with a shallow focus
    ctr = Vector((cx, cy, hmax * 0.38))
    if args.line:   # a bigger studio: the aisle between belt and shelf is about 10 m long
        side = 1.0 if args.shelf_x > 0 else -1.0   # the shelf's side; the key light stands on the other, with the camera
        mid = Vector((side * 2.4, -0.8, 1.2))
        # behind the camera: in front of it, the mirror floor shows the softbox as a white slab
        area("Softbox", (mid.x - side * 10.9, mid.y - 7.2, 5.0), mid, (5.0, 3.0), 16000.0, (1.0, 0.97, 0.92))
        area("Top", (mid.x, mid.y, 7.5), mid, (7.0, 5.0), 9000.0, (0.9, 0.92, 1.0))
        area("Fill", (mid.x - side * 8.0, mid.y - 7.0, 4.5), mid, (3.0, 2.0), 3000.0, (0.95, 0.97, 1.0))
        area("Rim teal", (mid.x + 5.0, mid.y + 6.5, 3.0), mid, (1.0, 4.0), 6000.0, (0.25, 0.95, 0.85))
        area("Rim pink", (mid.x - 6.0, mid.y + 7.5, 4.0), mid, (1.0, 3.0), 6000.0, (1.0, 0.35, 0.55))   # high and back: lower, the floor mirrored it into the frame
    else:
        area("Softbox", (cx - 2.4, cy - 3.0, 3.2), ctr, (3.0, 2.0), 3600.0, (1.0, 0.97, 0.92))
        area("Fill", (cx + 3.0, cy - 2.6, 1.4), ctr, (2.0, 1.4), 900.0, (0.95, 0.97, 1.0))
        area("Rim teal", (cx + 3.2, cy + 2.4, 1.6), ctr, (0.6, 2.4), 1400.0, (0.25, 0.95, 0.85))
        area("Rim pink", (cx - 3.4, cy + 2.6, 1.3), ctr, (0.6, 2.0), 1200.0, (1.0, 0.35, 0.55))
        area("Top", (cx, cy, 5.0), ctr, (2.4, 2.4), 1100.0, (0.9, 0.92, 1.0))
    world = scene.world or bpy.data.worlds.new("Studio"); scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.006, 0.007, 0.01, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    cam_d = bpy.data.cameras.new("Carton camera")
    cam_d.lens = args.lens or (26.0 if args.line else 70.0)
    cam_d.dof.use_dof = True
    cam_d.dof.aperture_fstop = 5.6 if args.line else 2.2
    cam = bpy.data.objects.new("Carton camera", cam_d)
    scene.collection.objects.link(cam)
    vec = lambda t: Vector(tuple(float(v) for v in t.split(",")))
    if args.line:
        # the works side: where the operator stands to reach across the belt, the baskets and shelf behind it
        cam.location = vec(args.cam) if args.cam else Vector((-5.4, -5.8, 3.8))   # raised: the belt top and the heap both read
        aim = vec(args.look) if args.look else Vector((0.4, -1.5, 0.8))
    else:
        cam.location = vec(args.cam) if args.cam else Vector((cx + args.dist * 0.23, cy - args.dist, max(0.9, hmax * 0.72) * args.dist / 4.4))
        aim = vec(args.look) if args.look else ctr
    cam.rotation_euler = (aim - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam_d.dof.focus_distance = (ctr - cam.location).length
    scene.camera = cam

    rx, ry = (int(v) for v in args.res.lower().split("x"))
    scene.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    for dev in ("OPTIX", "CUDA"):
        try:
            prefs.compute_device_type = dev
            prefs.get_devices()
            if any(d.type == dev for d in prefs.devices):
                for d in prefs.devices: d.use = d.type == dev
                scene.cycles.device = "GPU"
                break
        except TypeError:
            continue
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.use_adaptive_sampling = True
    scene.render.resolution_x, scene.render.resolution_y = rx, ry
    scene.render.resolution_percentage = 100
    vt = [i.identifier for i in scene.view_settings.bl_rna.properties["view_transform"].enum_items]
    scene.view_settings.view_transform = "AgX" if "AgX" in vt else "Filmic"
    looks = [i.identifier for i in scene.view_settings.bl_rna.properties["look"].enum_items]
    if "AgX - High Contrast" in looks:
        scene.view_settings.look = "AgX - High Contrast"
    scene.view_settings.exposure = args.exposure
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.blend:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.blend))
    scene.render.image_settings.file_format = "PNG"
    if not args.fill:
        scene.render.filepath = os.path.abspath(args.out)
        bpy.ops.render.render(write_still=True)
        print(f"[cartons] done {os.path.abspath(args.out)} on {scene.cycles.device}", flush=True)
        return 0
    # the film: the step grows linearly from step-start to step-end, so the filling speeds up as it goes
    frames, f = [], 1
    while f <= args.fill:
        frames.append(f)
        u = (f - 1) / max(1, args.fill - 1)
        f += max(1, round(args.step_start + (args.step_end - args.step_start) * u))
    if args.render_limit:
        frames = frames[:args.render_limit]
    shots = os.path.splitext(os.path.abspath(args.out))[0] + "_frames"
    os.makedirs(shots, exist_ok=True)
    t_r = time.time()
    want = {fr: n for n, fr in enumerate(frames)}
    # ONE pass, in order, filmed on the way: a jump of more than one frame without a cache does not simulate (the
    # first films showed only keyframed cartons). The feeder works in this loop: it takes the next parked carton,
    # holds it still above the belt for a frame (a kinematic body keeps the speed of its last move: released at once
    # after the jump from the parking place it flew kilometres) and lets it go - but only while the spot under it is
    # clear. Placing a carton into a queue that has backed up to the feeder blasted the queue into the air; the game's
    # line holds production the same way (active_limit).
    waiting, last, placed, holds = list(stream), -10 ** 9, 0, 0

    def key(o, path, index, frame, value):
        fc = o.animation_data.action.fcurves.find(path, index=index)
        kp = fc.keyframe_points.insert(frame, value)
        kp.interpolation = "CONSTANT"
    for fr in range(1, frames[-1] + 1):
        if waiting and fr - last >= args.every:
            busy = any(abs(c.matrix_world.translation.x) < 0.4 and abs(c.matrix_world.translation.y - spawn_y) < 0.36
                       and c.matrix_world.translation.z > z_top for c in stream[:placed])
            if busy:
                holds += 1
            else:
                o = waiting.pop(0)
                for i, v in enumerate((rng.uniform(-0.03, 0.03), spawn_y, drop_z)):
                    key(o, "location", i, fr, v)
                key(o, "hide_render", 0, fr, 0.0)
                key(o, "rigid_body.kinematic", 0, fr + 3, 0.0)   # still for two frames above the belt, then free
                last, placed = fr, placed + 1
        scene.frame_set(fr)
        if fr % 600 == 0:
            print(f"[cartons] simulated {fr}/{frames[-1]}: {placed} placed, the feeder held {holds} times "
                  f"({round(time.time() - t_r)} s)", flush=True)
        n = want.get(fr)
        if n is None:
            continue
        scene.render.filepath = os.path.join(shots, f"f{n:04d}.png")
        bpy.ops.render.render(write_still=True)
        if n % 25 == 0:
            print(f"[cartons] film frame {n + 1}/{len(frames)} (sim {fr}, {round(time.time() - t_r)} s)", flush=True)
    out_of_scene = [c.name for c in stream[:placed] if c.matrix_world.translation.length > 15.0]
    print(f"[cartons] the feeder placed {placed} cartons and held {holds} times; {len(out_of_scene)} ended more than 15 m "
          f"from the line{': ' + ', '.join(out_of_scene[:8]) if out_of_scene else ''}", flush=True)
    # encode with the ffmpeg inside Blender: a second scene holding the frames as one image strip
    enc = bpy.data.scenes.new("Encode")
    enc.render.resolution_x, enc.render.resolution_y = rx, ry
    enc.render.resolution_percentage = 100
    enc.render.fps = args.fps
    enc.sequence_editor_create()
    names = sorted(os.listdir(shots))
    strip = enc.sequence_editor.sequences.new_image("film", os.path.join(shots, names[0]), 1, 1)
    for nm in names[1:]:
        strip.elements.append(nm)
    enc.frame_start, enc.frame_end = 1, len(names)
    enc.render.image_settings.file_format = "FFMPEG"
    enc.render.ffmpeg.format = "MPEG4"
    enc.render.ffmpeg.codec = "H264"
    enc.render.ffmpeg.constant_rate_factor = "HIGH"
    enc.render.filepath = os.path.abspath(args.out)
    with bpy.context.temp_override(scene=enc):
        bpy.ops.render.render(animation=True, scene=enc.name)
    print(f"[cartons] done {os.path.abspath(args.out)}: {len(frames)} film frames of {args.fill} simulated, "
          f"{len(frames) / args.fps:.1f} s at {args.fps} fps", flush=True)
    return 0


if __name__ == "__main__":
    try:
        code = main()
    except Exception:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        code = 1
    sys.stdout.flush()
    os._exit(code)
