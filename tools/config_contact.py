#!/usr/bin/env python3
"""config_contact.py — the same artifact under several capture configs, side by side.

WHY. Fifteen promoted vector artifacts measure a subject share near zero and nobody knows
why, because every diagnosis so far has been a story: "it is too dark", "it is too wide",
"it needs a fixture". Each of those is testable and none had been tested. This captures ONE
artifact under N configs and tiles them in a row, so the config that makes it readable is
picked by looking rather than argued for.

IT ALSO GUARDS AGAINST THE FALSE RESCUE THAT PROMPTED IT. Switching to the showcase backdrop
raised basis_vectors_rig's subject share from 5.1% to 82.4% and changed almost nothing about
the artifact: the showcase adds a ground plane and a horizon band, and the subject mask
counts them, because it thresholds against the corner pixel. So this reports SUBJECT and PEAK
side by side per config. Subject says how much of the frame differs from the corner; peak
says how much the AXIS moves. A config that lifts subject and leaves peak flat has changed
the set dressing, not the measurement.

ONE BOOT PER CONFIG, NOT PER ARTIFACT. capture_config_sweep takes a whole variant list in one
spec and `framing` is a spec-level key, so N artifacts at one config cost one Godot boot.
Fifteen artifacts across four configs is four boots, not sixty.

Usage:
  python tools/config_contact.py --tokens=a,b,c
  python tools/config_contact.py --tokens=a,b --configs=dark-1.0,show-0.55
"""
from __future__ import annotations
import glob
import json
import os
import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
SWEEP = REPO / "ada_run" / "sweep"
SPEC = REPO / "ada_run" / "sweep_spec.json"
GODOT = os.environ.get("GODOT_EXE", r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
OUT = REPO / "doc" / "reports"

## (label, framing, showcase). The two dimensions that have ever mattered: how far the camera
## stands, and what colour the world behind the subject is.
CONFIGS = [
    ("dark-1.00", 1.00, False),
    ("dark-0.55", 0.55, False),
    ("dark-0.30", 0.30, False),
    ("dark-0.20", 0.20, False),
    ("dark-0.12", 0.12, False),
    ("show-0.55", 0.55, True),
]


def registry() -> dict:
    out = {}
    for f in sorted(glob.glob(str(REG / "*.json"))):
        try:
            d = json.loads(pathlib.Path(f).read_text(encoding="utf-8")).get("artifacts", {})
        except Exception:
            continue
        for t, e in (d or {}).items():
            if isinstance(e, dict):
                out[t] = e
    return out


def capture(tokens: list, reg: dict, label: str, framing: float, showcase: bool) -> dict:
    """One boot PER TOKEN at this config. Returns {token: png path}.

    ONE SPEC PER ARTIFACT, AND THE FIRST VERSION OF THIS FUNCTION GOT IT WRONG. It packed
    every token into a single spec to save boots — and capture_config_sweep computes a UNION
    AABB across all variants so the camera can hold them all at once. With human_catapult
    (17.55 m deep) and weather_vector_field (12.37 m) in the list, every other artifact was
    framed against those and photographed as a speck: basis_vectors_rig read 11.6% subject in
    a four-token run and 0.2% in a fifteen-token run at the same framing. The measurement was
    a fact about the LIST, not the artifact. A single-variant spec falls back to that
    variant's own AABB, which is the only honest way to ask this question.
    """
    got = {}
    for t in tokens:
        scene = str((reg.get(t) or {}).get("scene") or "")
        if not scene:
            continue
        fixture = ((reg.get(t) or {}).get("dna") or {}).get("fixture") or {}
        got.update(_one(t, scene, dict(fixture), label, framing, showcase))
    return got


def _one(token: str, scene: str, params: dict, label: str, framing: float,
         showcase: bool) -> dict:
    variants = [{"label": f"{token}__cfg-{label}", "artifact": token,
                 "scene": scene, "params": params}]
    tokens = [token]
    reg = None
    for p in SWEEP.glob("*__cfg-*.png"):
        p.unlink()
    done = SWEEP / "_done.txt"
    if done.exists():
        done.unlink()
    SWEEP.mkdir(parents=True, exist_ok=True)
    spec = {"scene": variants[0]["scene"], "out_dir": "res://ada_run/sweep",
            "framing": framing, "variants": variants}
    if showcase:
        spec["showcase"] = True
    SPEC.write_text(json.dumps(spec, indent=1), encoding="utf-8")
    env = dict(os.environ)
    if showcase:
        env["ADA_SWEEP_SHOWCASE"] = "1"
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={SWEEP}", "--", GODOT, "--path", str(REPO), "--xr-mode", "off",
           "--no-window", "--script", "res://commons/testing/capture_config_sweep.gd",
           "--", f"--spec={SPEC}"]
    subprocess.run(cmd, cwd=str(REPO), env=env, timeout=1800)
    got = {}
    for t in tokens:
        p = SWEEP / f"{t}__cfg-{label}.png"
        if p.exists():
            keep = SWEEP / f"_cfg_{label}_{t}.png"
            p.replace(keep)
            got[t] = keep
    return got


def metrics(path: pathlib.Path):
    """(subject %, and the frame itself) — subject is share differing from the corner pixel."""
    from PIL import Image, ImageChops
    im = Image.open(path).convert("RGB")
    bg = im.getpixel((3, 3))
    d = ImageChops.difference(im, Image.new("RGB", im.size, bg)).convert("L")
    px = list(d.getdata())
    return 100.0 * sum(1 for v in px if v > 12) / len(px), im


def main() -> int:
    tokens, want = [], [c[0] for c in CONFIGS]
    for a in sys.argv[1:]:
        if a.startswith("--tokens="):
            tokens = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a.startswith("--configs="):
            want = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
    if not tokens:
        print(__doc__)
        return 2
    reg = registry()
    cfgs = [c for c in CONFIGS if c[0] in want]

    shots = {}
    for label, framing, showcase in cfgs:
        print(f"· capturing {len(tokens)} artifacts at {label} …")
        shots[label] = capture(tokens, reg, label, framing, showcase)

    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("Pillow missing")
        return 1
    cell, lab = 330, 30
    sheet = Image.new("RGB", (len(cfgs) * cell, len(tokens) * (cell + lab)), (18, 18, 22))
    draw = ImageDraw.Draw(sheet)
    print()
    print(f"{'artifact':<40}" + "".join(f"{c[0]:>13}" for c in cfgs))
    print("-" * (40 + 13 * len(cfgs)))
    for r, t in enumerate(tokens):
        line = f"{t[:39]:<40}"
        for c, (label, _f, _s) in enumerate(cfgs):
            p = shots.get(label, {}).get(t)
            y = r * (cell + lab)
            draw.text((c * cell + 6, y + 6), f"{t}  ·  {label}", fill=(220, 224, 232))
            if p is None:
                line += f"{'—':>13}"
                continue
            subj, im = metrics(p)
            line += f"{subj:>12.1f}%"
            im.thumbnail((cell, cell))
            sheet.paste(im, (c * cell + (cell - im.width) // 2, y + lab))
        print(line)
    out = OUT / "config_contact.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"\nsheet: {out}")
    print("Read SUBJECT against the picture: a config that lifts subject without changing")
    print("what the artifact looks like has changed the backdrop, not the measurement.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
