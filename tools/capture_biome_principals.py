#!/usr/bin/env python3
"""capture_biome_principals.py — one shot per biome principal.

Rewrites the scratch stage map (Biome_Ex_Stage) once per entry in
build_biome_gallery.EXAMPLES, captures it headless (watchdog-wrapped,
strictly serialized — the second Godot dies on the user:// lock), and
copies the iso angle to ada_encyclopedia/public/biome-gallery/ex/<slug>.png.
Then rebuild the manifest:  python tools/build_biome_gallery.py

  python tools/capture_biome_principals.py             # all principals
  python tools/capture_biome_principals.py fungus_ca   # just these slugs
"""
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from build_biome_gallery import EXAMPLES  # noqa: E402

STAGE = "Biome_Ex_Stage"
STAGE_DIR = os.path.join(ROOT, "commons", "maps", STAGE)
EX_IMG_DIR = os.path.normpath(os.path.join(
    ROOT, "..", "ada_encyclopedia", "public", "biome-gallery", "ex"))
SHOTS = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata",
                     "Ada Research Zero One", "multi_shots", STAGE)
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
N = 5  # small stage — the principal fills the frame


def stage_map(example):
    """The scratch stage: bare floor, ONE declared thing on it."""
    structure = [["1"] * N for _ in range(N)]
    utilities = [[""] * N for _ in range(N)]
    # spawn only, at the near corner — the iso camera looks from there, so
    # the marker cube falls out of frame instead of standing over the subject
    utilities[N - 1][N - 1] = "sp"
    biome = [[""] * N for _ in range(N)]
    if example["group"] == "halo":
        biome[0][N // 2] = example["token"]   # rim cell: spills off the top edge
    else:
        biome[N // 2][N // 2] = example["token"]
    return {
        "map_info": {
            "name": STAGE, "title": STAGE,
            "description": "Scratch stage for the biome principals gallery — "
                           "rewritten per shot by tools/capture_biome_principals.py. "
                           "Current occupant: %s. Not spine." % example["slug"],
            "dimensions": {"width": N, "depth": N},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": [[""] * N for _ in range(N)],
            "biome": biome,
        },
        # disable_biome kills the accrual stack + ring (the sequence's own
        # wilderness would flood the shot) — GridBiomeComponent is gated on
        # layers.biome presence, not on this flag, so the ONE declared cell
        # still renders. The principal stands alone.
        "settings": {
            "disable_biome": True,
            "background": {"color": [0.05, 0.06, 0.1], "type": "sky"},
        },
    }


def capture(slug):
    if os.path.isdir(SHOTS):
        shutil.rmtree(SHOTS)
    cmd = [sys.executable, os.path.join(ROOT, "tools", "godot_watchdog.py"),
           "--expect=" + os.path.join(SHOTS, "capture_report.json"), "--",
           GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_multi_angle.gd", "--",
           "--mode=map", "--target=" + STAGE]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=240)
    src = os.path.join(SHOTS, "iso.png")
    if not os.path.isfile(src):
        print(f"  FAIL {slug}: no iso.png (rc={r.returncode})")
        return False
    shutil.copyfile(src, os.path.join(EX_IMG_DIR, f"{slug}.png"))
    return True


def main():
    only = set(sys.argv[1:])
    todo = [e for e in EXAMPLES if not only or e["slug"] in only]
    os.makedirs(EX_IMG_DIR, exist_ok=True)
    os.makedirs(STAGE_DIR, exist_ok=True)
    ok = 0
    for i, e in enumerate(todo, 1):
        with open(os.path.join(STAGE_DIR, "map_data.json"), "w", encoding="utf-8") as f:
            json.dump(stage_map(e), f, indent=1)
        print(f"[{i}/{len(todo)}] {e['slug']}  {e['token']}")
        if capture(e["slug"]):
            ok += 1
            print("  ok -> public/biome-gallery/ex/%s.png" % e["slug"])
    print(f"{ok}/{len(todo)} principals captured. Now: python tools/build_biome_gallery.py")
    return 0 if ok == len(todo) else 1


if __name__ == "__main__":
    raise SystemExit(main())
