#!/usr/bin/env python3
"""
test_measure_faults.py — the nine negative tests for `_measure_artifact_aabb`.

WHY THIS EXISTS. 72 artifacts were staged and read back against source; 25 of the
measurements described `commons/testing/capture_dressing_room.gd` rather than the
artifact. The patch for the remaining faults is written up in
doc/plans/capture_measure_faults.md. This file is what stops that patch from being
accepted because it reads well.

EVERY TEST MUST FAIL BEFORE THE PATCH AND PASS AFTER. A test suite that is green
on both sides of a fix is measuring nothing — which is precisely the disease the
fix is for. Run it once before touching the capture script and keep the output;
that run is the evidence the tests bite.

    python tools/test_measure_faults.py --baseline    # expect 8 FAIL, 1 PASS
    python tools/test_measure_faults.py               # after the patch: 9 PASS

TEST 9 IS THE ONE THAT MATTERS MOST and it is the boring one. lambda_slider,
origin and platonicsolids already reproduce published featured-grade captures. If
the patch moves any of them it is wrong no matter how good the other eight look.

ONE GODOT AT A TIME. The dressing-room viewer holds an exclusive lock on user://;
a capture launched against it does not error, it silently never writes. This
script refuses to start while that viewer heartbeats.
"""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
CAPS = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata",
                    "Ada Research Zero One", "dressing_room")
SCRATCH = os.path.join(ROOT, "ada_run", "measure_tests")


# (id, artifact, axis, assertion, why) — axis indexes the w/d/h tuple
# assertion is a predicate over (w, d, h, manifest) returning (ok, observed)
def _w(v): return v[0]
def _d(v): return v[1]
def _h(v): return v[2]


# Provenance lives under `measurement` in the manifest, NOT at the top level.
# Three of these tests originally read the top level, scored the repair as three
# failures, and were wrong — the code was already reporting everything they asked
# for, one key down. A test that cannot find the evidence reports the absence of
# evidence, which is the same fault class the tests exist to catch.
def _prov(man): return man.get("measurement") or {}
def _sign(man): return _prov(man).get("signage")


TESTS = [
    dict(id=1, artifact="scale_lines", fault="F1",
         why="the 18 m guard deleted its only long mesh; it is 100 m wide in 22 live maps",
         today="10.0 m wide",
         check=lambda wdh, man: (_w(wdh) > 50.0, f"width {_w(wdh):.2f} m")),
    dict(id=2, artifact="laser_measure", fault="F1+F6",
         why="fifty 12 mm ticks at z=-50 each slipped the per-mesh guard; 50.001 + 0.08 = 50.081",
         today="50.081 m tall",
         check=lambda wdh, man: (_h(wdh) < 5.0, f"height {_h(wdh):.3f} m"),
         needs_fixture=True),
    dict(id=3, artifact="pythagorean_triangle_angles", fault="F2",
         why="1.67 m of depth is seven billboarded Label3D; every real mesh is coplanar at z=0",
         today="depth 1.67 m",
         # The assertion is not merely "smaller" — it is that the 1.67 m REAPPEARS
         # as signage. A body that shrank without the text being accounted for
         # somewhere would mean geometry went missing, not that it was reclassified.
         check=lambda wdh, man: (
             _d(wdh) < 0.5 and _sign(man) is not None and abs(_sign(man)["size"][0] - 1.67) < 0.05,
             f"depth {_d(wdh):.3f} m, signage width "
             f"{_sign(man)['size'][0] if _sign(man) else None}")),
    dict(id=4, artifact="force_field", fault="F2",
         why="its 3.645 m width IS its caption",
         today="3.645 m wide",
         check=lambda wdh, man: (
             _sign(man) is not None and abs(_sign(man)["size"][0] - 3.645) < 0.05
             and _w(wdh) < 3.645,
             f"body {_w(wdh):.3f} m, caption "
             f"{_sign(man)['size'][0] if _sign(man) else None} m moved to signage")),
    dict(id=5, artifact="draw_dot", fault="F3",
         why="a set_as_top_level(true) node pinned at world origin while the seat lifts the artifact 1.52 m",
         today="3.29 m tall",
         check=lambda wdh, man: (_h(wdh) < 1.5, f"height {_h(wdh):.3f} m")),
    dict(id=6, artifact="draw_triangle_faces", fault="F3",
         why="same fault; the AABB floor sits at exactly -0.075 m, the snap sphere's half-height",
         today="3.224 m tall",
         check=lambda wdh, man: (_h(wdh) < 1.5, f"height {_h(wdh):.3f} m")),
    dict(id=7, artifact="edge_core", fault="F4",
         why="0.8 m sphere plus particles; must not regress, and effects must be reported separately",
         today="0.99 m (correct) but particles invisible to the manifest",
         check=lambda wdh, man: (0.8 <= _w(wdh) <= 1.2, f"width {_w(wdh):.3f} m")),
    dict(id=8, artifact="particle_chaos", fault="F5",
         why="[1,1,1] is the fallback; it must announce itself rather than pass as a measurement",
         today="[1,1,1] silently",
         check=lambda wdh, man: (_prov(man).get("fallback") is True,
                                 f"fallback={_prov(man).get('fallback')!r}, "
                                 f"reason={str(_prov(man).get('fallback_reason'))[:44]!r}")),
    dict(id=9, artifact="lambda_slider", fault="REGRESSION",
         why="published featured_aaa capture — if the patch moves this, the patch is wrong",
         today="0.69 x 0.33 x 1.31 (correct)",
         check=lambda wdh, man: (abs(_w(wdh) - 0.69) < 0.03 and abs(_d(wdh) - 0.33) < 0.03
                                 and abs(_h(wdh) - 1.31) < 0.05,
                                 f"{_w(wdh):.2f} x {_d(wdh):.2f} x {_h(wdh):.2f}")),
]


def viewer_alive() -> bool:
    p = os.path.join(ROOT, "ada_run", "dr_viewer_alive.txt")
    if not os.path.exists(p):
        return False
    try:
        return time.time() - float(open(p).read().strip()) < 8.0
    except (ValueError, OSError):
        return False


def capture(artifact: str, oid: str, fixture: bool) -> dict | None:
    os.makedirs(SCRATCH, exist_ok=True)
    cfg = os.path.join(SCRATCH, f"{artifact}.json")
    body = {"artifact": artifact, "staged": True, "studio": "museum", "wait": 2.0}
    if fixture:
        # F6: the registry already declares dna.fixture for this artifact. Pass it
        # explicitly so the test can distinguish "the harness ignores dna.fixture"
        # from "the guard is per-mesh" — they are different faults with one symptom.
        body["apply_dna_fixture"] = True
    json.dump(body, open(cfg, "w", encoding="utf-8"))
    man = os.path.join(CAPS, f"{oid}.json")
    if os.path.exists(man):
        os.remove(man)
    try:
        subprocess.run(
            [GODOT, "--path", ROOT, "--xr-mode", "off", "--no-window", "--script",
             "res://commons/testing/capture_dressing_room.gd", "--",
             f"--config={cfg}", f"--id={oid}", "--wait=2.0"],
            capture_output=True, text=True, timeout=150)
    except subprocess.TimeoutExpired:
        return None
    if not os.path.exists(man):
        return None
    try:
        return json.load(open(man, encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline", action="store_true",
                    help="record the pre-patch run; 8 of 9 are EXPECTED to fail")
    ap.add_argument("--only", type=int, default=0, help="run one test by id")
    a = ap.parse_args()

    if viewer_alive():
        print("REFUSING: the dressing-room viewer is heartbeating.")
        print("  Godot's user:// lock is exclusive — a capture launched now would")
        print("  die silently and never write. Close the float viewer and re-run.")
        return 2
    if not os.path.exists(GODOT):
        print(f"Godot not found at {GODOT}; set GODOT_EXE")
        return 2

    tests = [t for t in TESTS if not a.only or t["id"] == a.only]
    results = []
    for t in tests:
        man = capture(t["artifact"], f"mt_{t['artifact']}", t.get("needs_fixture", False))
        if man is None:
            results.append((t, "ERROR", "capture did not complete"))
            print(f"  [{t['id']}] {t['artifact']:30} ERROR  capture did not complete")
            continue
        s = man["aabb"]["size"]
        wdh = (s[0], s[2], s[1])          # AABB is x,y,z; convention is w,d,h
        ok, observed = t["check"](wdh, man)
        verdict = "PASS" if ok else "FAIL"
        results.append((t, verdict, observed))
        print(f"  [{t['id']}] {t['artifact']:30} {verdict}  {observed:28} {t['fault']}")

    npass = sum(1 for _, v, _ in results if v == "PASS")
    nfail = sum(1 for _, v, _ in results if v == "FAIL")
    print(f"\n{npass} pass · {nfail} fail · {len(results) - npass - nfail} error")

    if a.baseline:
        print("\nBASELINE EXPECTATION: tests 1-8 FAIL, test 9 PASSES.")
        print("A baseline where anything else happens means the test is not measuring")
        print("the fault it names — fix the test before touching the capture script.")
        good = all(v == "FAIL" for t, v, _ in results if t["id"] != 9) and \
            all(v == "PASS" for t, v, _ in results if t["id"] == 9)
        print("baseline is", "as expected" if good else "NOT as expected — investigate")
        out = os.path.join(ROOT, "ada_run", "measure_tests", "baseline.json")
        json.dump([{"id": t["id"], "artifact": t["artifact"], "verdict": v, "observed": o}
                   for t, v, o in results], open(out, "w", encoding="utf-8"), indent=1)
        print("->", os.path.relpath(out, ROOT))
        return 0

    return 0 if nfail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
