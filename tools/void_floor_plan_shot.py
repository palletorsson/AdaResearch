"""Photograph one floor of the main Void tower from above (or obliquely) and close.

Usage: python tools/void_floor_plan_shot.py --floor 8 [--height 28] [--oblique] [--walk x0,z0,x1,z1]
With --walk the walker is driven from a start to a target first; eye.png and plan.json's walk record show it.
Writes ada_run/floor-plans/floor-<n>-<id>/plan.png and plan.json. Holds the native slot while it runs.
"""
import argparse, os, subprocess, uuid
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--floor", type=int, required=True)
    parser.add_argument("--height", type=float, default=28.0)
    parser.add_argument("--oblique", action="store_true")
    parser.add_argument("--walk", help="x0,z0,x1,z1: drive the walker from a start to a target first (floor-local m)")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = root / "ada_run/floor-plans" / ("floor-%d-%s" % (args.floor, uuid.uuid4().hex[:8]))
    out.mkdir(parents=True)
    print("Plan folder:", out, flush=True)
    acquire_native_slot("floor plan shot of floor %d" % args.floor, timeout=120)
    stage = stage_runtime()
    with (out / "game.log").open("w", encoding="utf-8") as log:
        code = subprocess.run([os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
                               "--windowed", "--resolution", "1600x800", "--rendering-method", "gl_compatibility", "--xr-mode", "off",
                               "--path", str(stage), "--script", "res://tools/probes/void_floor_plan_shot.gd", "--", "--no-bridges",
                               "--void-start-floor=%d" % args.floor, "--plan-output=%s" % out, "--plan-height=%s" % args.height,
                               *(["--plan-oblique"] if args.oblique else []), *(["--walk=" + args.walk] if args.walk else [])],
                              cwd=root, stdout=log, stderr=subprocess.STDOUT, timeout=600).returncode
    print("exit", code, "->", out / "plan.png")


if __name__ == "__main__":
    main()
