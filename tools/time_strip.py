#!/usr/bin/env python3
"""
time_strip.py — photograph an artifact at N moments and tile them along one row.

The driver for commons/testing/capture_time_strip.gd. Where cabinet_sweep.py varies a
PARAMETER, this varies TIME: same artifact, same camera, six moments. It exists because
the stage-2 loop only ever produced stills, and a still cannot hold a rate — which made
every duration, decay, accumulation and lag in this project unevaluable, and left
tools/artifact_dna_research.py reporting `time_domain_only` as a dead end.

Read the strip left to right. A rate that does nothing looks exactly like the sweep of
identical tiles it always was; the difference is that now that is a FINDING rather than
a limitation of the instrument.

Usage:
  python tools/time_strip.py info_board --frames=6 --window=8
  python tools/time_strip.py galton_board --window=12 --set auto_drop=true
"""
from __future__ import annotations
import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SPEC = REPO / "ada_run" / "time_strip_spec.json"
OUT = REPO / "ada_run" / "time_strip"
SHEETS = REPO / "doc" / "reports"
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"


def resolve_scene(token: str) -> str:
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict) and token in arts and isinstance(arts[token], dict):
            return str(arts[token].get("scene", ""))
    return ""


def coerce(v: str):
    low = v.lower()
    if low in ("true", "false"):
        return low == "true"
    try:
        return int(v) if "." not in v else float(v)
    except ValueError:
        return v


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("artifact")
    ap.add_argument("--frames", type=int, default=6)
    ap.add_argument("--window", type=float, default=8.0)
    ap.add_argument("--set", action="append", default=[], metavar="KEY=VALUE",
                    help="fix an @export before the clock starts (repeatable)")
    a = ap.parse_args()

    scene = resolve_scene(a.artifact)
    if not scene:
        print(f"could not resolve a scene for '{a.artifact}'")
        return 1

    params = {}
    for s in a.set:
        if "=" in s:
            k, _, v = s.partition("=")
            params[k.strip()] = coerce(v.strip())

    if OUT.exists():
        for p in OUT.glob("*.png"):
            p.unlink()
        done = OUT / "_done.txt"
        if done.exists():
            done.unlink()
    OUT.mkdir(parents=True, exist_ok=True)
    SPEC.parent.mkdir(parents=True, exist_ok=True)
    SPEC.write_text(json.dumps({
        "scene": scene,
        "out_dir": "res://ada_run/time_strip",
        "label": a.artifact,
        "frames": a.frames,
        "window_s": a.window,
        "params": params,
    }, indent=1), encoding="utf-8")

    # The window is real elapsed time, so the watchdog stall must exceed it or it will
    # kill a probe that is behaving correctly — the run looks idle precisely while it
    # is doing its job.
    stall = int(a.window) + 20
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={OUT}", f"--grace=60", f"--stall={stall}", "--",
           GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_time_strip.gd",
           "--", f"--spec=res://ada_run/time_strip_spec.json"]
    subprocess.run(cmd, cwd=REPO, timeout=int(a.window) + 240)

    shots = sorted(OUT.glob(f"{a.artifact}__t-*.png"))
    if not shots:
        print("no frames captured — see the Godot log")
        return 1
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print(f"  ({len(shots)} frames in {OUT}; Pillow missing so no strip tiled)")
        return 0

    cw = 420
    sheet = Image.new("RGB", (cw * len(shots), cw + 26), (18, 20, 18))
    dr = ImageDraw.Draw(sheet)
    for i, p in enumerate(shots):
        t = p.stem.split("t-")[-1]
        dr.text((i * cw + 8, 7), f"t = {t}s", fill=(235, 235, 225))
        sheet.paste(Image.open(p).convert("RGB").resize((cw, cw), Image.LANCZOS),
                    (i * cw, 26))
    out = SHEETS / f"strip_{a.artifact}.png"
    sheet.save(out)
    print(f"\n{len(shots)} frames over {a.window:.0f}s -> {out.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
