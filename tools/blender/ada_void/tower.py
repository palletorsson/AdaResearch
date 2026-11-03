"""tower.py — several floors of The Void stacked at their storeys and photographed from outside.

    blender -b -P tools/blender/ada_void/tower.py -- --floors 0-4 --out ada_run/blender/void_tower_0-4.png \
        [--samples 128] [--res 1920x1080] [--blend ada_run/blender/void_tower_0-4.blend] [--enc http://localhost:3003]

To move only the camera (no import), open the saved scene and reframe it:

    blender -b ada_run/blender/void_tower_0-9.blend -P tools/blender/ada_void/tower.py -- --reframe         --out ada_run/blender/void_tower_0-9.png --res 1440x2560 --azimuth -62 --elevation 12

Each floor is imported with floor_import.build_floor — the same import as the panel, from GET /api/void-layout and the
glTF export — and everything of that floor is hung under an empty `tower-floor-<i>` at the floor's level from
commons/void/layout.json (`levels[i]`, Godot y, which is Blender z). World and sun come from the export's lighting;
one camera stands outside, raised, three-quarter, framing the stacked floors. Palle, 3 Nov 2026: "render five floor
void tower outside view in blender".
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
if os.path.dirname(HERE) not in sys.path:
    sys.path.insert(0, os.path.dirname(HERE))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

# as headless.py: run THIS folder's add-on, not an installed copy
if "ada_void" in sys.modules:
    try:
        sys.modules["ada_void"].unregister()
    except Exception as e:  # noqa: BLE001
        print("[tower] installed add-on unregister:", repr(e))
    for k in [k for k in sys.modules if k == "ada_void" or k.startswith("ada_void.")]:
        del sys.modules[k]

import ada_void  # noqa: E402
from ada_void import floor_import, render_setup  # noqa: E402


def floor_range(text: str) -> list[int]:
    out: list[int] = []
    for part in text.split(","):
        a, _, b = part.partition("-")
        out += list(range(int(a), int(b) + 1)) if b else [int(a)]
    return out


def all_objects(coll) -> list:
    objs = list(coll.objects)
    for c in coll.children:
        objs += all_objects(c)
    return objs


def stack(index: int, level: float) -> bpy.types.Object:
    """hang every top-level object of floor `index` under an empty at the floor's level"""
    root = floor_import.floor_collection(index)
    holder = bpy.data.objects.new(f"tower-floor-{index}", None)
    holder.empty_display_type = "ARROWS"
    holder.location = (0.0, 0.0, level)
    root.objects.link(holder)
    for o in all_objects(root):
        if o is not holder and o.parent is None:
            o.parent = holder
    return holder


def world_bounds(objs) -> tuple[Vector, Vector]:
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    return lo, hi


def outside_camera(scene, lo: Vector, hi: Vector, lens: float, azimuth: float, elevation: float, margin: float):
    """raised, three-quarter, far enough that the whole box fits the narrower field of view"""
    centre = (lo + hi) / 2
    radius = (hi - lo).length / 2
    cam = bpy.data.cameras.new("Tower camera")
    cam.lens = lens
    cam.clip_end = 2000.0
    rx, ry = scene.render.resolution_x, scene.render.resolution_y
    sensor = cam.sensor_width
    fov_w = 2 * math.atan(sensor / (2 * lens))
    fov_h = 2 * math.atan(sensor * ry / rx / (2 * lens))
    dist = radius * margin / math.sin(min(fov_w, fov_h) / 2)
    d = Vector((math.cos(elevation) * math.cos(azimuth), math.cos(elevation) * math.sin(azimuth), math.sin(elevation)))
    o = bpy.data.objects.new("Tower camera", cam)
    scene.collection.objects.link(o)
    o.location = centre + d * dist
    o.rotation_euler = (centre - o.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = o
    return o, centre, dist


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--floors", default="0-4")
    ap.add_argument("--out", default=os.path.join(ROOT, "ada_run", "blender", "void_tower.png"))
    ap.add_argument("--blend", default="")
    ap.add_argument("--samples", type=int, default=128)
    ap.add_argument("--res", default="1920x1080")
    ap.add_argument("--lens", type=float, default=35.0)
    ap.add_argument("--azimuth", type=float, default=-38.0, help="degrees about Blender +Z, from +X")
    ap.add_argument("--elevation", type=float, default=24.0)
    ap.add_argument("--margin", type=float, default=1.02)
    ap.add_argument("--exposure", type=float, default=0.9)
    ap.add_argument("--enc", default="")
    ap.add_argument("--reframe", action="store_true", help="the floors are already in the open .blend: only camera and render")
    ap.add_argument("--append", action="store_true", help="import --floors into the open .blend and keep the floors already there")
    ap.add_argument("--frame-floors", default="", help="frame only these floors (the others may run out of the picture)")
    args = ap.parse_args(argv)
    if args.enc:
        os.environ["ADA_ENC_URL"] = args.enc
    t0 = time.time()
    ada_void.register()
    scene = bpy.context.scene
    spec = json.load(open(os.path.join(ROOT, "commons", "void", "layout.json"), encoding="utf-8"))
    levels = spec.get("levels") or []
    storey = float(spec.get("storey_height", 6.0))
    floors = [] if args.reframe else floor_range(args.floors)
    keep = args.reframe or args.append   # the floors (and world and sun) already in the open .blend stay
    report = {"floors": [], "storey_height": storey, "reframe": args.reframe, "append": args.append}
    for o in list(bpy.data.objects):   # a fresh start: the start-up cube, camera and lamp; otherwise only the old camera
        if not keep or o.name.startswith("Tower camera"):
            bpy.data.objects.remove(o, do_unlink=True)
    for i in floors:
        t = time.time()
        st = floor_import.build_floor(bpy.context, i, labels=True)
        level = float(levels[i]) if i < len(levels) else -storey * i
        stack(i, level)
        report["floors"].append({"index": i, "map": st.get("map"), "level": level, "artifacts": st.get("artifacts"),
                                 "props": st.get("props"), "missing": len(st.get("models_missing") or []), "seconds": round(time.time() - t, 1)})
        print(f"[tower] floor {i} {st.get('map')} at {level} m: {st.get('artifacts')} artifacts, {st.get('props')} props", flush=True)
    bpy.context.view_layer.update()

    rx, ry = (int(v) for v in args.res.lower().split("x"))
    scene.render.engine = "CYCLES"
    report["device"] = render_setup._gpu(scene)
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.max_bounces = 8
    scene.render.resolution_x, scene.render.resolution_y = rx, ry
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    vt = [i.identifier for i in scene.view_settings.bl_rna.properties["view_transform"].enum_items]
    scene.view_settings.view_transform = "AgX" if "AgX" in vt else "Filmic"
    scene.view_settings.exposure = args.exposure
    if not keep:   # a reframe or an append keeps the world and sun the scene was saved with
        lighting = json.loads(scene.get("ada_void_lighting", "{}") or "{}")
        rig = bpy.data.collections.new("Tower render")
        scene.collection.children.link(rig)
        report["world"] = render_setup.setup_world(scene, lighting, False)
        render_setup.setup_sun(scene, lighting, rig)

    framed = list(bpy.data.objects)
    if args.frame_floors:   # only these floors' things: the rest of the tower may run past the edge
        framed = []
        for i in floor_range(args.frame_floors):
            h = bpy.data.objects.get(f"tower-floor-{i}")
            if h is not None:
                framed += [h] + list(h.children_recursive)
        report["framed_floors"] = args.frame_floors
    lo, hi = world_bounds(framed)
    cam, centre, dist = outside_camera(scene, lo, hi, args.lens, math.radians(args.azimuth), math.radians(args.elevation), args.margin)
    report.update({"bounds": [list(lo), list(hi)], "centre": list(centre), "camera_distance": round(dist, 1)})
    print(f"[tower] bounds {tuple(round(v, 1) for v in lo)} .. {tuple(round(v, 1) for v in hi)}; camera at {round(dist, 1)} m", flush=True)

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.blend:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.blend))
    t = time.time()
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.abspath(args.out)
    bpy.ops.render.render(write_still=True)
    report.update({"out": os.path.abspath(args.out), "render_seconds": round(time.time() - t, 1), "seconds": round(time.time() - t0, 1)})
    with open(os.path.splitext(os.path.abspath(args.out))[0] + ".json", "w", encoding="utf-8") as f:
        json.dump(report, f, indent=1)
    print("[tower] done", json.dumps({k: report[k] for k in ("out", "device", "render_seconds", "seconds")}), flush=True)
    return 0


if __name__ == "__main__":
    try:
        code = main()
    except Exception as e:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        code = 1
    sys.stdout.flush()
    os._exit(code)
