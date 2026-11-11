"""arrival.py — floors of The Void photographed from where the player lands, in one Blender process.

    blender -b -P tools/blender/ada_void/arrival.py -- --floors 85,87,90 --out ada_run/blender/arrival \
        [--samples 16] [--res 1280x800] [--no-ceiling] [--no-labels] [--enc http://localhost:3003]

THE ARRIVAL RULE (doc/WORLD_UNITS.md; Palle, 2026-11-11): 176 of the tower's 199 spawn points are one spot, (0, 7.8),
looking north, so a floor is curated from there. tools/void_arrival_shots.py takes that picture in the game - the
truth, about two minutes a floor. This takes it from the exported models and the live layout (GET /api/void-layout,
as the panel and tower.py do) in a few seconds a floor: the eye at the floor's spawn point from
commons/void/layout.json, 1.6 m up, looking at the middle of the floor, then turned 40 degrees to each side.

    <out>/f<floor>/view_1.png  straight ahead      view_2.png  40 degrees left      view_3.png  40 degrees right
    <out>/arrival.json         per floor: map, works, props, models missing, seconds

The slab of the floor above is imported as the ceiling (structure only) unless --no-ceiling. It shows what has been
EXPORTED: after new placements, new prop kinds or a re-configured work, run `python tools/void_export_sync.py` first.
It cannot tell whether a body can walk or what a work looks like while it runs - the game is the judge of those.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))

# tower.py registers THIS folder's add-on (not an installed copy) and owns the helpers for stacking a floor
_spec = importlib.util.spec_from_file_location("ada_void_tower", os.path.join(HERE, "tower.py"))
tower = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tower)

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402
from ada_void import chain, floor_import, frames, render_setup  # noqa: E402

EYE = 1.6
TURNS = (0.0, -40.0, 40.0)      # view_1 straight, view_2 left, view_3 right - as tools/void_arrival_shots.py


def clear(keep: set) -> None:
    for o in list(bpy.data.objects):
        if o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)


def add_walls(record: dict) -> int:
    """The floor's `walls` (commons/void/rooms.json: from, to, height, base, finish) as boxes. The game builds them from
    the record (commons/void/floor_content.gd); neither the model export nor floor_import carries them, and a staged
    floor without its walls is a different picture (floor 85: twelve walls)."""
    made = 0
    for wall in record.get("walls") or []:
        (x1, z1), (x2, z2) = wall["from"], wall["to"]
        height = float(wall.get("height", 2.4))
        base = float(wall.get("base", 0.0))
        centre = Vector(frames.godot_to_blender_point([(x1 + x2) / 2.0, base + height / 2.0, (z1 + z2) / 2.0]))
        size = (max(abs(x2 - x1), 0.18), max(abs(z2 - z1), 0.18), height)      # Godot x, z, y = Blender x, y, z
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=centre)
        o = bpy.context.active_object
        o.name = "wall-" + str(wall.get("id", made))
        o.scale = size
        name = "Void wall " + str(wall.get("finish", "concrete"))
        mat = bpy.data.materials.get(name)
        if mat is None:
            mat = bpy.data.materials.new(name)
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            colour = (0.60, 0.58, 0.53, 1.0) if wall.get("finish") == "unfinished" else (0.72, 0.71, 0.68, 1.0)
            bsdf.inputs["Base Color"].default_value = colour
            bsdf.inputs["Roughness"].default_value = 0.9
        o.data.materials.append(mat)
        made += 1
    return made


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--floors", default="85")
    ap.add_argument("--out", default=os.path.join(ROOT, "ada_run", "blender", "arrival"))
    ap.add_argument("--samples", type=int, default=16)
    ap.add_argument("--res", default="1280x800")
    ap.add_argument("--exposure", type=float, default=0.9)
    ap.add_argument("--no-ceiling", action="store_true")
    ap.add_argument("--no-labels", action="store_true", help="skip the text labels: faster, for layout only")
    ap.add_argument("--enc", default="")
    args = ap.parse_args(argv)
    if args.enc:
        os.environ["ADA_ENC_URL"] = args.enc
    t0 = time.time()
    tower.ada_void.register()
    scene = bpy.context.scene
    spec = json.load(open(os.path.join(ROOT, "commons", "void", "layout.json"), encoding="utf-8"))
    storey = float(spec.get("storey_height", 6.0))
    spawns = spec.get("spawn_points") or {}
    clear(set())

    rx, ry = (int(v) for v in args.res.lower().split("x"))
    scene.render.engine = "CYCLES"
    device = render_setup._gpu(scene)
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.max_bounces = 4
    scene.render.resolution_x, scene.render.resolution_y = rx, ry
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    vt = [i.identifier for i in scene.view_settings.bl_rna.properties["view_transform"].enum_items]
    scene.view_settings.view_transform = "AgX" if "AgX" in vt else "Filmic"
    scene.view_settings.exposure = args.exposure

    layout = chain.get_layout(floor_import.enc_url(), "")
    manifest = floor_import.load_manifest(layout.get("models") or "/void-models/manifest.json")
    cache = floor_import.GlbCache()
    cam_data = bpy.data.cameras.new("Arrival eye")
    cam_data.sensor_fit = "VERTICAL"
    cam_data.angle_y = math.radians(60.0)      # the game probe's vertical field of view
    cam_data.clip_start = 0.05
    cam_data.clip_end = 400.0
    cam = bpy.data.objects.new("Arrival eye", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    keep = {cam.name}
    report = {"device": device, "samples": args.samples, "floors": []}
    rigged = False
    for i in tower.floor_range(args.floors):
        t = time.time()
        clear(keep)
        st = floor_import.build_floor(bpy.context, i, labels=not args.no_labels)
        records = layout["rooms"].get("floors", [])
        walls = add_walls(records[i]) if i < len(records) else 0
        if not args.no_ceiling and i > 0:
            tower.structure_only(i - 1, manifest, cache)
            tower.stack(i - 1, storey)
        if not rigged:      # world and sun once, from the export's own lighting
            lighting = json.loads(scene.get("ada_void_lighting", "{}") or "{}")
            rig = bpy.data.collections.new("Arrival render")
            scene.collection.children.link(rig)
            before = {o.name for o in bpy.data.objects}
            render_setup.setup_world(scene, lighting, False)
            render_setup.setup_sun(scene, lighting, rig)
            keep |= {o.name for o in bpy.data.objects} - before
            rigged = True
        bpy.context.view_layer.update()
        x, _y, z = spawns.get(str(i), [0, 0.06, 7.8])
        folder = os.path.join(os.path.abspath(args.out), "f%d" % i)
        os.makedirs(folder, exist_ok=True)
        dx, dz = -float(x), -float(z)
        n = math.hypot(dx, dz) or 1.0
        for k, turn in enumerate(TURNS):
            a = math.radians(turn)
            rxx, rzz = (dx * math.cos(a) - dz * math.sin(a)) / n, (dx * math.sin(a) + dz * math.cos(a)) / n
            eye = Vector(frames.godot_to_blender_point([float(x), EYE, float(z)]))
            aim = Vector(frames.godot_to_blender_point([float(x) + rxx * 8.0, 1.2, float(z) + rzz * 8.0]))
            cam.location = eye
            cam.rotation_euler = (aim - eye).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(folder, "view_%d.png" % (k + 1))
            bpy.ops.render.render(write_still=True)
        row = {"floor": i, "map": st.get("map"), "artifacts": st.get("artifacts"), "props": st.get("props"), "walls": walls,
               "models_missing": len(st.get("models_missing") or []), "spawn": [x, z], "seconds": round(time.time() - t, 1)}
        report["floors"].append(row)
        print("[arrival]", json.dumps(row), flush=True)
    report["seconds"] = round(time.time() - t0, 1)
    os.makedirs(os.path.abspath(args.out), exist_ok=True)
    with open(os.path.join(os.path.abspath(args.out), "arrival.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=1)
    print("[arrival] done", json.dumps({"floors": len(report["floors"]), "seconds": report["seconds"], "device": device}), flush=True)
    return 0


if __name__ == "__main__":
    try:
        code = main()
    except Exception:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        code = 1
    sys.exit(code)
