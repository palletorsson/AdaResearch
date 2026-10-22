"""headless.py — the add-on driven from `blender -b -P tools/blender/ada_void/headless.py -- …`.

Used by tools/live_update_blender_test.py, and by hand:

  blender -b -P tools/blender/ada_void/headless.py -- --floor 10 \
      --move museum-primitives_profiles-15-1 1.5 0 --report ada_run/blender_report.json \
      [--render out.png --samples 64] [--blend out.blend] [--no-publish] [--enc http://localhost:3003]

Steps: register the add-on from this folder, import the floor, check the glTF
importer's axis conversion against the raw glb and against a known record, then
(unless --no-publish) move the named mount by (dx, dz) in Godot metres, publish,
wait for the acks, move it back, publish again; optional Cycles setup + render;
a JSON report with every check and every ack.
"""
from __future__ import annotations

import argparse
import json
import os
import struct
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
if os.path.dirname(HERE) not in sys.path:
    sys.path.insert(0, os.path.dirname(HERE))

import bpy  # noqa: E402

# An installed copy of the add-on may already be enabled in this Blender: unregister
# it and run THIS folder's copy, so the test measures the repository, not the install.
if "ada_void" in sys.modules:
    try:
        sys.modules["ada_void"].unregister()
    except Exception as e:  # noqa: BLE001
        print("[headless] installed add-on unregister:", repr(e))
    for k in [k for k in sys.modules if k == "ada_void" or k.startswith("ada_void.")]:
        del sys.modules[k]

import ada_void  # noqa: E402
from ada_void import chain, floor_import, frames, publish, render_setup  # noqa: E402


def glb_first_translation(path: str):
    """The first node translation in a glb's JSON chunk (Godot axes, as exported)."""
    with open(path, "rb") as f:
        magic, _ver, _len = struct.unpack("<III", f.read(12))
        assert magic == 0x46546C67, "not a glb"
        clen, ctype = struct.unpack("<II", f.read(8))
        doc = json.loads(f.read(clen).decode("utf-8"))
    for n in doc.get("nodes", []):
        if "translation" in n and any(abs(v) > 1e-6 for v in n["translation"]):
            return n.get("name", ""), n["translation"]
        if "matrix" in n and any(abs(v) > 1e-6 for v in n["matrix"][12:15]):
            return n.get("name", ""), n["matrix"][12:15]
    return None


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--floor", type=int, default=10)
    ap.add_argument("--trial", default="")
    ap.add_argument("--move", nargs=3, metavar=("ID", "DX", "DZ"), default=None)
    ap.add_argument("--report", default="")
    ap.add_argument("--render", default="")
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--fog", action="store_true")
    ap.add_argument("--camera", default="overview", choices=["arrival", "overview"])
    ap.add_argument("--style", default="evening", choices=["evening", "book"])
    ap.add_argument("--blend", default="")
    ap.add_argument("--no-publish", action="store_true")
    ap.add_argument("--wait", type=float, default=8.0, help="seconds to wait for acks per publish")
    ap.add_argument("--expect", type=int, default=1, help="devices expected to answer")
    ap.add_argument("--enc", default="")
    args = ap.parse_args(argv)
    if args.enc:
        os.environ["ADA_ENC_URL"] = args.enc

    report: dict = {"floor": args.floor, "trial": args.trial, "t0": time.time(), "checks": {}, "publishes": []}
    ok = True

    def check(name: str, passed: bool, detail):
        nonlocal ok
        report["checks"][name] = {"pass": bool(passed), "detail": detail}
        ok = ok and bool(passed)
        print(f"[headless] {'PASS' if passed else 'FAIL'} {name}: {detail}")

    ada_void.register()
    ctx = bpy.context
    scene = ctx.scene
    scene.ada_void.floor = args.floor
    scene.ada_void.trial = args.trial

    t = time.time()
    stats = floor_import.build_floor(ctx, args.floor, args.trial, labels=True)
    report["import"] = {**stats, "seconds": round(time.time() - t, 1)}
    rooms = floor_import.get_rooms()
    rec = rooms["floors"][args.floor]

    # 1. the glTF importer's axis conversion, measured on the floor's structure glb:
    #    raw translation (tx, ty, tz) in the file must land at Blender (tx, -tz, ty)
    manifest = floor_import.load_manifest(scene.ada_void.models)
    structure = (manifest.get("floors") or {}).get(str(args.floor), {}).get("structure") or {}
    if structure.get("url"):
        path = floor_import.resolve_public(structure["url"])
        first = glb_first_translation(path)
        if first:
            name, tr = first
            cands = [o for o in bpy.data.objects if o.name.split(".")[0] == name and o.parent is not None and o.parent.name == f"floor-{args.floor}"]
            if not cands:
                cands = [o for o in bpy.data.objects if o.name.split(".")[0] == name]
            if cands:
                loc = list(cands[0].matrix_basis.to_translation())
                want = frames.godot_to_blender_point(tr)
                err = max(abs(a - b) for a, b in zip(loc, want))
                check("gltf_axis_conversion", err < 1e-4,
                      f"node '{name}' raw {tr} -> blender {[round(v, 4) for v in loc]} (expected (x,-z,y) {[round(v, 4) for v in want]}, err {err:.2e})")
            else:
                check("gltf_axis_conversion", False, f"node '{name}' not found after import")
        else:
            check("gltf_axis_conversion", False, "no translated node in the structure glb")

    # 2. the architecture's extent against the frame (42 x 18 m: x within ±21, Blender y within ±9)
    xs, ys, zs = [], [], []
    arch = bpy.data.objects.get(f"floor-{args.floor}")
    from mathutils import Vector
    for o in bpy.data.objects:
        if o.type == "MESH" and (o.parent is arch or (o.parent and o.parent.parent is arch)):
            for c in o.bound_box:
                w = o.matrix_world @ Vector(c)
                xs.append(w.x); ys.append(w.y); zs.append(w.z)
    if xs:
        ext = (round(min(xs), 2), round(max(xs), 2), round(min(ys), 2), round(max(ys), 2), round(min(zs), 2), round(max(zs), 2))
        check("architecture_extent", max(xs) - min(xs) > max(ys) - min(ys) and max(xs) - min(xs) <= 60 and max(ys) - min(ys) <= 30 and max(zs) - min(zs) <= 12,
              f"x [{ext[0]}, {ext[1]}] y [{ext[2]}, {ext[3]}] z(up) [{ext[4]}, {ext[5]}] — the 42 m width runs along x, the 18 m depth along -y, up is z")

    # 3. a known record: the mount's location is (x, -z, height) of its record
    target_id = args.move[0] if args.move else (rec["artifacts"][-1]["id"] if rec.get("artifacts") else "")
    item = next((a for a in rec.get("artifacts", []) if a.get("id") == target_id), None)
    obj = bpy.data.objects.get(target_id)
    if item and obj:
        want = frames.godot_to_blender_point([item["position"][0], item.get("height", 0), item["position"][1]])
        got = list(obj.location)
        err = max(abs(a - b) for a, b in zip(got, want))
        check("known_record_placement", err < 1e-4,
              f"{target_id} ({item.get('artifact')}) record position {item['position']} height {item.get('height', 0)} facing {item.get('facing', 0)} -> blender {[round(v, 4) for v in got]} rot_z {round(obj.rotation_euler.z, 4)}")
    else:
        check("known_record_placement", False, f"no record/object {target_id!r} on floor {args.floor}")

    # 4. an unchanged scene reads back to the same document
    rooms_rb = json.loads(json.dumps(rooms))
    changes0 = publish.read_back(args.floor, rooms_rb)
    check("read_back_is_identity", not changes0 and rooms_rb == rooms, f"{len(changes0)} change(s) read back from an untouched import" + (": " + "; ".join(changes0) if changes0 else ""))

    # 5. move, publish, move back, publish
    if args.move and not args.no_publish and obj is not None:
        dx, dz = float(args.move[1]), float(args.move[2])
        loc0 = obj.location.copy()
        for step, (ddx, ddz) in enumerate(((dx, dz), (0.0, 0.0)), start=1):
            obj.location = (loc0.x + ddx, loc0.y - ddz, loc0.z)
            t = time.time()
            res = publish.publish(ctx, wait_acks=args.wait, log=print)
            res = {k: v for k, v in res.items() if k != "rooms"}
            res["step"] = step
            res["seconds"] = round(time.time() - t, 1)
            res["moved_to"] = [round(v, 4) for v in obj.location]
            report["publishes"].append(res)
            acks = [a for rid in res.get("acks", {}) for a in res["acks"][rid]]
            applied = [a for a in acks if a.get("status") == "applied"]
            check(f"publish_{step}_saved", res.get("saved"), res.get("status"))
            check(f"publish_{step}_acked", len(applied) >= args.expect,
                  " · ".join(chain.format_ack(a) for a in acks) or "no ack")
            for a in acks:
                print(f"[headless]   ack {chain.format_ack(a)} — {str(a.get('detail', ''))[:120]}")
        # make the scene remember the file it ended on
        report["revision_end"] = scene.ada_void.revision

    # 6. render
    if args.render:
        info = render_setup.setup_render(ctx, samples=args.samples, fog=args.fog, camera=args.camera, style=args.style)
        report["render"] = info
        t = time.time()
        os.makedirs(os.path.dirname(os.path.abspath(args.render)), exist_ok=True)
        render_setup.render_still(ctx, os.path.abspath(args.render))
        report["render"]["file"] = os.path.abspath(args.render)
        report["render"]["seconds"] = round(time.time() - t, 1)
        check("render_written", os.path.exists(args.render) and os.path.getsize(args.render) > 10_000,
              f"{args.render} in {report['render']['seconds']} s on {info['device']}")
    else:
        try:
            info = render_setup.setup_render(ctx, samples=args.samples, fog=args.fog, camera=args.camera, style=args.style)
            report["render"] = info
            check("render_setup", scene.camera is not None and scene.render.engine == "CYCLES", f"camera {info['route']}, {info['world']}, {info['device']}")
        except Exception as e:  # noqa: BLE001
            check("render_setup", False, repr(e))

    if args.blend:
        os.makedirs(os.path.dirname(os.path.abspath(args.blend)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.blend))
        report["blend"] = os.path.abspath(args.blend)

    report["ok"] = ok
    report["seconds"] = round(time.time() - report["t0"], 1)
    if args.report:
        os.makedirs(os.path.dirname(os.path.abspath(args.report)) or ".", exist_ok=True)
        with open(args.report, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
    print("[headless] " + ("PASS" if ok else "FAIL") + f" in {report['seconds']} s")
    return 0 if ok else 1


if __name__ == "__main__":
    code = main()
    sys.exit(code)
