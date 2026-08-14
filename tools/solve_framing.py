#!/usr/bin/env python3
"""solve_framing.py — derive each artifact's dna.framing from one capture, not a ladder.

WHY NOT A LADDER. Trying five framings per artifact costs five Godot boots each, and the
answer is arithmetic anyway: at framing f the visible frame is 2 * PAD * radius * f metres
wide, so a subject of fixed width fills a fraction proportional to 1/f. Measure the fraction
once and solve.

    f_target = f_measured * (fraction_measured / fraction_wanted)

ONE SPEC PER ARTIFACT, ALWAYS. capture_config_sweep unions the AABBs of every variant in a
spec so one camera can hold them all; batching artifacts to save boots therefore frames each
one against the biggest in the batch. basis_vectors_rig measured 11.6% subject in a
four-token run and 0.2% in a fifteen-token run at the SAME framing. Everything here runs a
single-variant spec, which falls back to that variant's own box.

WHAT IT MEASURES is the subject BOUNDING BOX as a fraction of frame width, not the subject
share. A row of separated marks has a low share and a wide box — CLAUDE.md's sparse-not-small
rule — and framing should be set from the box, or a sparse artifact gets dragged in until its
ends fall off the frame.

Usage:
  python tools/solve_framing.py --tokens=a,b,c            # report only
  python tools/solve_framing.py --tokens=a,b --apply      # write dna.framing
  python tools/solve_framing.py --tokens=a --target=0.78
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

PROBE_FRAMING = 1.0
## The box should fill this much of frame WIDTH. Not 1.0: the marks at the ends of a wide
## artifact need margin, and the critic crops to the subject box anyway.
DEFAULT_TARGET = 0.78
## Below this a solved framing is refusing to be sensible — the artifact is probably a
## precinct, or its runtime AABB is inflated by something the camera should not be fitting.
MIN_FRAMING = 0.04


def registry_files() -> list:
    return sorted(glob.glob(str(REG / "*.json")))


def load() -> dict:
    out = {}
    for f in registry_files():
        try:
            d = json.loads(pathlib.Path(f).read_text(encoding="utf-8")).get("artifacts", {})
        except Exception:
            continue
        for t, e in (d or {}).items():
            if isinstance(e, dict):
                out[t] = (e, f)
    return out


def shoot(token: str, entry: dict, framing: float):
    scene = str(entry.get("scene") or "")
    if not scene:
        return None
    fixture = ((entry.get("dna") or {}).get("fixture") or {})
    for p in SWEEP.glob("_solve_*.png"):
        p.unlink()
    done = SWEEP / "_done.txt"
    if done.exists():
        done.unlink()
    SWEEP.mkdir(parents=True, exist_ok=True)
    SPEC.write_text(json.dumps({
        "scene": scene, "out_dir": "res://ada_run/sweep", "framing": framing,
        "variants": [{"label": f"_solve_{token}", "artifact": token, "scene": scene,
                      "params": dict(fixture)}],
    }, indent=1), encoding="utf-8")
    subprocess.run([sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
                    f"--expect={SWEEP}", "--", GODOT, "--path", str(REPO), "--xr-mode", "off",
                    "--no-window", "--script",
                    "res://commons/testing/capture_config_sweep.gd", "--", f"--spec={SPEC}"],
                   cwd=str(REPO), timeout=600)
    p = SWEEP / f"_solve_{token}.png"
    return p if p.exists() else None


def box_fraction(path: pathlib.Path):
    """(width fraction, height fraction, subject share) of the subject's bounding box."""
    from PIL import Image, ImageChops
    im = Image.open(path).convert("RGB")
    bg = im.getpixel((3, 3))
    d = ImageChops.difference(im, Image.new("RGB", im.size, bg)).convert("L")
    bbox = d.point(lambda v: 255 if v > 12 else 0).getbbox()
    px = list(d.getdata())
    share = 100.0 * sum(1 for v in px if v > 12) / len(px)
    if not bbox:
        return 0.0, 0.0, share
    w, h = im.size
    return (bbox[2] - bbox[0]) / w, (bbox[3] - bbox[1]) / h, share


def main() -> int:
    tokens, apply, target = [], "--apply" in sys.argv, DEFAULT_TARGET
    for a in sys.argv[1:]:
        if a.startswith("--tokens="):
            tokens = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a.startswith("--target="):
            target = float(a.split("=", 1)[1])
    if not tokens:
        print(__doc__)
        return 2

    reg = load()
    print(f"{'token':<44}{'box W':>8}{'box H':>8}{'subj':>8}{'solved':>9}  note")
    print("-" * 92)
    plan = []
    for t in tokens:
        if t not in reg:
            print(f"{t:<44}{'not in any registry':>33}")
            continue
        entry, path = reg[t]
        shot = shoot(t, entry, PROBE_FRAMING)
        if shot is None:
            print(f"{t:<44}{'CAPTURE FAILED':>33}")
            continue
        fw, fh, share = box_fraction(shot)
        if fw <= 0.0005:
            print(f"{t:<44}{fw*100:>7.1f}%{fh*100:>7.1f}%{share:>7.2f}%{'—':>9}  "
                  f"nothing rendered at all — not a framing fault")
            continue
        # the box grows as 1/f, and the taller dimension must also fit
        f_w = PROBE_FRAMING * fw / target
        f_h = PROBE_FRAMING * fh / target
        solved = round(max(min(f_w, f_h), MIN_FRAMING), 2)
        note = ""
        if f_h < f_w:
            note = "height-dominant, solved on H"
        if solved <= MIN_FRAMING:
            note = "clamped — runtime AABB is inflated, look for a far-flung mesh"
        print(f"{t:<44}{fw*100:>7.1f}%{fh*100:>7.1f}%{share:>7.2f}%{solved:>9.2f}  {note}")
        plan.append((t, path, solved, fw, fh, share))

    if not apply:
        print("\n(report only — pass --apply to write dna.framing)")
        return 0

    touched = {}
    for t, path, solved, fw, fh, share in plan:
        d = json.loads(pathlib.Path(path).read_text(encoding="utf-8"))
        dna = d["artifacts"][t].setdefault("dna", {})
        dna["framing"] = solved
        dna["framing_why"] = (
            "SOLVED, NOT GUESSED, by tools/solve_framing.py. At framing 1.0 this artifact's "
            "subject bounding box filled %.1f%% of frame width and %.1f%% of its height, with "
            "a subject share of %.2f%%. The visible frame is 2 * PAD * radius * framing metres "
            "wide, so the box grows as 1/framing; solving for a target of %.0f%% of the "
            "smaller-headroom dimension gives %.2f. "
            "THE ARTIFACT WAS NEVER DARK, EMPTY OR MISSING A FIXTURE - the camera was between "
            "three and eight times too far away, and the near-zero subject share this token "
            "had on record was a fact about the standpoint rather than about the axis."
            % (fw * 100, fh * 100, share, target * 100, solved))
        pathlib.Path(path).write_text(json.dumps(d, indent="\t", ensure_ascii=True) + "\n",
                                      encoding="utf-8")
        touched.setdefault(path, []).append(t)
    for path, ts in touched.items():
        print(f"  wrote {pathlib.Path(path).name}: {', '.join(ts)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
