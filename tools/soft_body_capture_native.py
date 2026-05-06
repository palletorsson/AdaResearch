#!/usr/bin/env python
"""
soft_body_capture_native.py — Capture existing softbody artifacts into the gallery.

Unlike soft_body_research.py (custom Verlet sim), this track shells out to the
existing capture_multi_angle.gd pipeline to render the 15+ registered soft body
artifacts already in commons/artifacts/registry/soft_bodies.json.

Uses the 'front' angle from the standard multi-angle capture, copies it into
ada_encyclopedia/public/soft-body-gallery/ with a 'sbX_' prefix, and appends
to the manifest entries so the gallery shows both Verlet and native tracks.
"""
from __future__ import annotations
import argparse, json, os, subprocess, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GODOT_EXE = os.environ.get(
    "GODOT_EXE",
    "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
)
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "soft-body-gallery"

# Registered softbody artifacts to capture — lookup_name -> (gallery_id, layout, notes)
NATIVE_ARTIFACTS = [
    ("jelly_cube",             "sbX01_jelly_cube",             "native_jelly",    "Canonical VR jelly cube — deformable, grab-interactive. QFEP: low stiffness = high λ territory."),
    ("flagdancer",             "sbX02_flagdancer",             "native_cloth",    "Animated soft body flag with wind forces — the gallery's dancing waveform."),
    ("cloth_simulation",       "sbX03_cloth_simulation",       "native_cloth",    "Core cloth simulation artifact — spring-mass + pressure on a grid mesh."),
    ("squishy_ball_pit",       "sbX04_squishy_ball_pit",       "native_balloon",  "Glass container full of glowing squishy soft-body spheres."),
    ("soft_trampoline",        "sbX05_soft_trampoline",        "native_cloth",    "Edge-pinned bouncy sheet — ballistic platform with soft rebound."),
    ("breathing_room",         "sbX06_breathing_room",         "native_balloon",  "Corridor with soft-body walls rhythmically expanding and contracting."),
    ("soft_mushrooms",         "sbX07_soft_mushrooms",         "native_shader",   "Procedural mushrooms with wobbly shader-driven soft caps."),
    ("cloth_straps",           "sbX08_cloth_straps",           "native_cloth",    "Hanging cloth straps the player walks through — proximity-reactive drape."),
    ("revolving_joy_ride",     "sbX09_revolving_joy_ride",     "native_jelly",    "Rotating ride with hanging soft bodies colliding with obstacles."),
    ("pendulum_slap",          "sbX10_pendulum_slap",          "native_jelly",    "Double pendulum slapping soft bodies — energy transfer demo."),
    ("rounded_softbody_test",  "sbX11_rounded_softbody_test",  "native_jelly",    "Rounded cube with strain-energy heatmap, force arrows, volume preservation. VR squeeze interactive."),
    ("softbody3d",             "sbX12_softbody3d",             "native_cloth",    "Core Godot SoftBody3D node demo — the reference implementation."),
    ("softbody_gallery_part1", "sbX13_gallery_part1",          "native_gallery",  "Part 1 of the 36-config softbody test grid — sphere-vs-collider variations."),
    ("softbody_gallery_part2", "sbX14_gallery_part2",          "native_gallery",  "Part 2 — pressure, deflation, drag, mass variants."),
    ("softbody_gallery_part3", "sbX15_gallery_part3",          "native_gallery",  "Part 3 — caving, collapse, stability edge cases."),
]

ANGLE = "front"   # which of the 4 standard capture angles to use for gallery thumbnail


def _find_multi_shots_dir() -> Path | None:
    appdata = os.environ.get("APPDATA", "")
    if not appdata: return None
    ud = Path(appdata) / "Godot" / "app_userdata"
    if not ud.exists(): return None
    for d in ud.iterdir():
        ms = d / "multi_shots"
        if ms.exists(): return ms
    return None


def capture_one(lookup_name: str, gallery_id: str, layout: str, notes: str,
                force: bool) -> bool:
    out_png = OUTPUT_DIR / f"{gallery_id}.png"
    out_meta = OUTPUT_DIR / f"{gallery_id}.json"
    if out_png.exists() and out_meta.exists() and not force:
        print(f"  skip  {gallery_id}")
        return True

    print(f"  capture {gallery_id} ({lookup_name}) ...")
    args = [
        GODOT_EXE, "--path", str(REPO_ROOT), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/capture_multi_angle.gd", "--",
        "--mode=artifact", f"--target={lookup_name}",
        "--out=user://multi_shots",
    ]
    proc = subprocess.run(args, capture_output=True, text=True, timeout=180)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})  stderr: {proc.stderr[-300:]}")
        return False

    ms = _find_multi_shots_dir()
    if ms is None:
        print("    multi_shots dir not found")
        return False
    src = ms / lookup_name / f"{ANGLE}.png"
    if not src.exists():
        # try any angle as fallback
        for alt in ("front", "left", "right", "top"):
            cand = ms / lookup_name / f"{alt}.png"
            if cand.exists():
                src = cand; break
        else:
            print(f"    no angle png found in {ms / lookup_name}")
            return False

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_png.write_bytes(src.read_bytes())
    out_meta.write_text(json.dumps({
        "id": gallery_id,
        "source": "native_softbody_artifact",
        "lookup_name": lookup_name,
        "scene_path": f"see commons/artifacts/registry/soft_bodies.json",
        "angle": ANGLE,
        "layout": layout,
        "notes": notes,
    }, indent=2))
    print(f"    -> public/soft-body-gallery/{gallery_id}.png")
    return True


def rebuild_manifest() -> None:
    """Merge verlet configs + native captures into one manifest."""
    entries = []

    # Verlet track — from research_configs.json
    cfg_path = REPO_ROOT / "commons" / "soft_body" / "research_configs.json"
    if cfg_path.exists():
        lib = json.loads(cfg_path.read_text())
        for cfg in lib["configs"]:
            png = OUTPUT_DIR / f"{cfg['id']}.png"
            if not png.exists(): continue
            entries.append({
                "id": cfg["id"],
                "notes": cfg.get("notes", ""),
                "layout": cfg.get("layout", ""),
                "image": f"/soft-body-gallery/{cfg['id']}.png",
                "config": f"/soft-body-gallery/{cfg['id']}.json",
            })

    # Native track — from captured artifacts
    for lookup, gid, layout, notes in NATIVE_ARTIFACTS:
        png = OUTPUT_DIR / f"{gid}.png"
        if not png.exists(): continue
        entries.append({
            "id": gid,
            "notes": notes,
            "layout": layout,
            "image": f"/soft-body-gallery/{gid}.png",
            "config": f"/soft-body-gallery/{gid}.json",
        })

    manifest = {
        "version": 2,
        "description": "Soft body gallery — two tracks. Verlet track: deterministic headless spring-mass sims with config-as-DNA. Native track: captures of existing SoftBody3D artifacts from the softbodies sequence.",
        "entries": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"Manifest: {len(entries)} entries")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="Capture only one gallery_id")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    targets = NATIVE_ARTIFACTS
    if args.id:
        targets = [t for t in NATIVE_ARTIFACTS if t[1] == args.id or t[0] == args.id]
        if not targets: print(f"No artifact for id={args.id}"); return 1

    print(f"Native softbody capture: {len(targets)} artifacts -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    ok, fail = [], []
    for lookup, gid, layout, notes in targets:
        if capture_one(lookup, gid, layout, notes, args.force):
            ok.append(gid)
        else:
            fail.append(gid)

    rebuild_manifest()
    print(f"\nOK: {len(ok)}  Fail: {len(fail)}")
    if fail:
        for f in fail: print(f"  - {f}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
