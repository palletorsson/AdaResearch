#!/usr/bin/env python3
"""
temporal_lint.py — does an artifact change when nothing asked it to?

THE GAP THIS FILLS. Every other gate in this project photographs a SINGLE STILL:
cabinet_sweep writes one PNG per variant, artifact_dna_critic diffs two PNGs of different
variants, the galleries publish stills, render_lint measures stills. A defect that lives in
TIME is unmeasurable by all of them, because a still cannot disagree with itself. Two
artifacts were found strobing at refresh rate — one destroying and rebuilding its whole
visualisation 90 times a second — and nothing in the toolchain could have scored either.

Worse, in one of them the sanctioned cure for unseeded randf (a seed export plus
dna.fixture) had been applied to the MEASUREMENT branch only. The bench was pinned clean
and the shipped default kept flickering. An instrument that only looks at the pinned path
cannot see that by construction.

HOW IT WORKS. commons/testing/capture_temporal.gd loads one artifact, settles it, and
photographs it twice with a gap. This drives that per artifact and reports the difference.

THE GAP LENGTH IS THE WHOLE DESIGN, and getting it wrong was measured. At 1.0 s a fixed
artifact still read 5.67% "moved", because a legitimate 2.0 s rebuild cycle fell between the
two frames — the instrument was scoring the DESIGN. The gap must be shorter than any
intended cadence. 0.15 s is ~13 frames at 90 Hz: long enough that a per-frame re-roll is
certain to show, short enough that a deliberate animation usually will not.

READ THE SUBJECT SHARE BEFORE THE VERDICT. A frame with nothing in it reports 0.00% moved
and looks perfectly stable. line_builder_3d rendered 0.39% of frame standalone, so its zero
meant nothing at all and the defect had to be confirmed from source instead.

THIS DOES NOT MEASURE "ANIMATION IS BAD". Plenty here is meant to move — a pendulum swings,
a soft body settles. The question is narrower: in the state an artifact SHIPS in, does its
surface change with nothing asked of it. Read the number beside the artifact, never alone.

Usage:
  python tools/temporal_lint.py --tokens=a,b,c
  python tools/temporal_lint.py --category=hazards --limit=12
  python tools/temporal_lint.py --tokens=... --gap=0.15
"""
from __future__ import annotations
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from check_dna_declarations import registry  # noqa: E402

GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
OUT = REPO / "ada_run" / "temporal"
# STABLE below the first, STROBES above the second. Set from the two measured cases:
# a fixed artifact reads 0.00-0.34%, the worst offender read 6.22%.
STABLE = 0.2
STROBE = 3.0
# HARD-CHANGED PIXEL COUNT, and this exists because frame-fraction alone was WRONG.
# boids_aquarium reported 0.14% of frame moved and was called stable; the boids had in
# fact all moved, and the flock was flocking correctly. Thirty specks a few pixels across
# inside a large glass tank change a tiny FRACTION of the frame while changing completely.
# A small moving part in a large static housing is exactly that shape, and it is common
# here: an instrument in a cabinet, a readout on a rack, a school in a tank.
#
# Max delta separates them. A stable artifact differs by a few levels of noise; anything
# that genuinely moved leaves pixels differing by a lot, however few of them there are.
HARD_DELTA = 60
HARD_MIN = 25
MIN_SUBJECT = 1.0      # below this the frame is too empty for the verdict to mean anything


def measure(label: str):
    from PIL import Image, ImageChops
    a, b = OUT / f"{label}__t0.png", OUT / f"{label}__t1.png"
    if not (a.exists() and b.exists()):
        return None
    ia, ib = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
    d = list(ImageChops.difference(ia, ib).convert("L").getdata())
    moved = 100.0 * sum(1 for v in d if v > 6) / len(d)
    hard = sum(1 for v in d if v > HARD_DELTA)
    bg = ia.getpixel((3, 3))
    m = list(ImageChops.difference(ia, Image.new("RGB", ia.size, bg)).convert("L").getdata())
    subj = 100.0 * sum(1 for v in m if v > 12) / len(m)
    return moved, subj, max(d), hard


def run_one(token: str, scene: str, gap: float) -> bool:
    done = OUT / "_done.txt"
    if done.exists():
        done.unlink()
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={done.as_posix()}", "--",
           GODOT, "--path", str(REPO), "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_temporal.gd", "--",
           f"--scene={scene}", "--out=res://ada_run/temporal",
           f"--label={token}", f"--gap={gap}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=240)
    return "exited 0" in (r.stdout or "")


def main() -> int:
    tokens: list[str] = []
    category, limit, gap = "", 0, 0.15
    for a in sys.argv[1:]:
        if a.startswith("--tokens="):
            tokens = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a.startswith("--category="):
            category = a.split("=", 1)[1]
        elif a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])
        elif a.startswith("--gap="):
            gap = float(a.split("=", 1)[1])
    reg = registry()
    if category:
        tokens = [t for t, (e, _f) in sorted(reg.items())
                  if str(e.get("category", "")).lower() == category.lower()]
    if not tokens:
        print(__doc__)
        return 2
    if limit:
        tokens = tokens[:limit]
    OUT.mkdir(parents=True, exist_ok=True)

    print(f"{'artifact':30s} {'moved':>7s} {'subject':>8s} {'max':>5s} {'hard':>6s}  verdict")
    print("-" * 76)
    rows = []
    for t in tokens:
        e = reg.get(t)
        if not e:
            print(f"{t:30s} {'':>7s} {'':>8s} {'':>5s}  not in any registry")
            continue
        scene = str(e[0].get("scene", "") or "")
        if not scene.endswith(".tscn"):
            print(f"{t:30s} {'':>7s} {'':>8s} {'':>5s}  no scene")
            continue
        if not run_one(t, scene, gap):
            print(f"{t:30s} {'':>7s} {'':>8s} {'':>5s}  CAPTURE FAILED")
            continue
        m = measure(t)
        if m is None:
            print(f"{t:30s} {'':>7s} {'':>8s} {'':>5s}  no frames")
            continue
        moved, subj, mx, hard = m
        if subj < MIN_SUBJECT:
            v = "TOO EMPTY TO JUDGE"
        elif moved >= STROBE:
            v = "STROBES"
        elif moved >= STABLE or hard >= HARD_MIN:
            # `hard` is what catches a small mover in a big housing. Without it
            # boids_aquarium read stable while its whole school had relocated.
            v = "MOVES"
        else:
            v = "stable"
        print(f"{t:30s} {moved:6.2f}% {subj:7.2f}% {mx:5d} {hard:6d}  {v}")
        rows.append({"token": t, "moved_pct": round(moved, 3),
                     "subject_pct": round(subj, 3), "max_delta": mx,
                     "hard_changed_px": hard, "verdict": v})
    rep = REPO / "doc" / "reports" / "temporal_lint.json"
    rep.write_text(json.dumps({
        "_note": "Two frames %.2fs apart with nothing asked to change. The gap must be "
                 "SHORTER than any intended cadence or this measures the design instead of "
                 "the defect. A verdict with subject_pct under %.1f means nothing." % (gap, MIN_SUBJECT),
        "gap": gap, "rows": rows}, indent=1), encoding="utf-8")
    strobes = [r for r in rows if r["verdict"] == "STROBES"]
    empty = [r for r in rows if r["verdict"] == "TOO EMPTY TO JUDGE"]
    print("-" * 68)
    print(f"{len(rows)} measured · {len(strobes)} STROBES · {len(empty)} too empty to judge")
    print(f"-> {rep.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
