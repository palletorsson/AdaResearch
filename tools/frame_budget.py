"""What is eating the frame, floor by floor (2026-11-07). Runs tools/probes/frame_budget.gd in the real tower, opened
as desktop play opens it, ONE floor at a time (measurements must not share the machine with each other), and prints
the baseline and the parts that cost most. Output: ada_run/frame-budget/<floor>/budget.json.

    python tools/frame_budget.py --floors=6,20 [--top=15]

A part's cost is measured looking AT it: hide it, measure again. Costs are not additive (the GPU overlaps work) and
other Godot processes on the machine raise every number - compare floors in one run.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ada_run/frame-budget"
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def main() -> int:
    sys.stdout.reconfigure(encoding="utf8")
    floors = [int(x) for x in next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--floors=")), "6").split(",")]
    top = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--top=")), "15"))
    renderer = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--renderer=")), "gl_compatibility")
    stage = stage_runtime()
    for floor in floors:
        out = OUT / f"{floor:03d}"
        out.mkdir(parents=True, exist_ok=True)
        (out / "budget.json").unlink(missing_ok=True)
        with (out / "engine.log").open("w", encoding="utf8") as stream:
            subprocess.run([sys.executable, str(ROOT / "tools/godot_watchdog.py"), "--expect=" + str(out / "budget.json"),
                            "--grace=240", "--stall=180", "--",
                            GODOT, "--log-file", str(out / "godot.log"), "--windowed", "--position", "3200,3200", "--resolution", "1440x900",
                            "--rendering-method", renderer, "--xr-mode", "off", "--path", str(stage),
                            "--script", "res://tools/probes/frame_budget.gd", "--", "--no-bridges",
                            f"--void-start-floor={floor}", "--play-output=" + out.as_posix(),
                            *[a for a in sys.argv if a.startswith("--yaws=") or a in ("--baseline-only", "--bisect")]],
                           stdout=stream, stderr=subprocess.STDOUT, timeout=1800, creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            r = json.loads((out / "budget.json").read_text(encoding="utf8"))
        except (OSError, ValueError):
            print(f"floor {floor}: no report - see {out / 'engine.log'}")
            continue
        print(f"\n=== floor {floor} {r['map']} ({r['renderer']}, {r['gpu']})")
        for yaw, b in r["baseline"].items():
            print(f"  {yaw:>9}: {b['fps']:6.1f} fps  median {b['median_ms']:6.2f} ms  worst {b['worst_ms']:7.1f}  spikes>50ms {b['spikes_over_50ms']:3d}  physics {b['physics_ms']:5.2f}  "
                  f"render cpu {b['render_cpu_ms']:5.2f} gpu {b['render_gpu_ms']:6.2f}  draws {b['draw_calls']:5d}  prims {b['primitives']:8d}  "
                  f"video {b['video_mb']} MB  static {b['static_mb']} MB  nodes {b['nodes']}")
        print(f"  {'part':44s} {'dist':>5} {'frame':>7} {'gpu':>7} {'r.cpu':>6} {'phys':>6} {'draws':>6} {'tris':>8} {'nodes':>6} {'transp':>6} {'proc':>5}")
        for p in r["parts"][:top]:
            c, k = p["census"], p.get("cost", {})
            print(f"  {p['name'][:44]:44s} {p.get('distance_m', 0):5.1f} {k.get('frame_ms', 0):7.2f} {k.get('render_gpu_ms', 0):7.2f} "
                  f"{k.get('render_cpu_ms', 0):6.2f} {k.get('physics_ms', 0):6.2f} {k.get('draw_calls', 0):6d} "
                  f"{c['triangles']:8d} {c['nodes']:6d} {c['transparent_materials']:6d} {c['processing']:5d}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
