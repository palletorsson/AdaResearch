"""desire_timeline.py — the forward transform (L-011).

Space as desire over a timeline: the walk is time; at each step the body has
two channels — the EYE (visual desire: angular presence of what stands ahead)
and the HAND (hand desire: operable things within reach). This tool reads an
existing map into that timeline by parsing the real gaze_ride log.

  python tools/desire_timeline.py --map Point_Lines
  python tools/desire_timeline.py --chapter doc/book/look_scripts/primitives.json

The --chapter form transforms every map in the script file, in all variants
that exist on disk (composed, Script_, Grown_), and writes JSON + an index to
ada_encyclopedia/public/desire-timelines/ for the 2D editor (/desire-timeline).

Hand classification is a stated heuristic (name-based) until the interaction
DNA is wired in: grab/slider/button/puzzle/builder/draw/edit/snap/interactive/
catalyst/toss/pad/writing/crank → hand; everything else → visual only.
"""
import argparse
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
OUT_DIR = os.path.normpath(os.path.join(
    ROOT, "..", "ada_encyclopedia", "public", "desire-timelines"))

HAND_RE = re.compile(
    r"grab|slider|button|puzzle|builder|draw|edit|snap|interactive|catalyst"
    r"|toss|pad|writing|crank|placer|dice|toy", re.I)
REACH_M = 2.5


def base_of(token):
    return token.split(":")[0].split("#")[0]


def is_hand(base):
    return bool(HAND_RE.search(base))


def ride_log(map_name):
    r = subprocess.run([sys.executable, "tools/gaze_ride.py", map_name],
                       capture_output=True, text=True, cwd=ROOT, timeout=180)
    if r.returncode != 0:
        return None
    return r.stdout


STEP_RE = re.compile(r"step (\d+)\s+@\((\d+),(\d+)\)(.*?)(?=step \d+|\Z)", re.S)
VIEW_RE = re.compile(r"^\s+(\S+)\s+\w+\s+(\d+)deg\s+(\S+)\s+([\d.]+)m", re.M)


def transform(map_name):
    log = ride_log(map_name)
    if not log:
        return None
    steps = []
    classes = {}
    for sm in STEP_RE.finditer(log):
        step = int(sm.group(1))
        x, z = int(sm.group(2)), int(sm.group(3))
        visual = axis = hand = 0.0
        seen = []
        for vm in VIEW_RE.finditer(sm.group(4)):
            b = base_of(vm.group(1))
            deg = int(vm.group(2))
            pos = vm.group(3)
            dist = float(vm.group(4))
            classes.setdefault(b, "hand" if is_hand(b) else "visual")
            visual += deg
            if pos == "CENTER":
                axis = max(axis, deg)
            if dist <= REACH_M and is_hand(b):
                hand += deg
            seen.append(b)
        visit = None
        vm2 = re.search(r"-> (\S+)", sm.group(4))
        if vm2:
            visit = base_of(vm2.group(1))
        steps.append({"step": step, "x": x, "z": z,
                      "visual": round(visual, 1), "axis": round(axis, 1),
                      "hand": round(hand, 1), "visit": visit, "seen": seen})
    return {"map": map_name, "steps": steps, "classes": classes,
            "channels": {
                "visual": "sum of angular sizes in view (deg) — the eye's field",
                "axis": "largest CENTER angular size (deg) — the promise on the reading line",
                "hand": "angular size of hand-class artifacts within reach (deg) — the operable now",
            }}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map")
    ap.add_argument("--chapter", help="script file; transforms every map x every variant on disk")
    args = ap.parse_args()
    os.makedirs(OUT_DIR, exist_ok=True)
    targets = []
    if args.map:
        targets = [args.map]
    elif args.chapter:
        scripts = json.load(open(os.path.join(ROOT, args.chapter), encoding="utf-8"))
        for m in scripts["maps"]:
            for prefix in ("", "Script_", "Grown_"):
                name = prefix + m
                if os.path.isfile(os.path.join(MAPS_DIR, name, "map_data.json")):
                    targets.append(name)
    else:
        ap.error("--map or --chapter required")
    index = []
    idx_path = os.path.join(OUT_DIR, "index.json")
    if os.path.isfile(idx_path):
        index = json.load(open(idx_path, encoding="utf-8"))
    for name in targets:
        t = transform(name)
        if t is None:
            print(f"SKIP {name} (gaze_ride failed)")
            continue
        with open(os.path.join(OUT_DIR, f"{name}.json"), "w", encoding="utf-8") as f:
            json.dump(t, f, indent=1)
        if name not in index:
            index.append(name)
        v = max((s["visual"] for s in t["steps"]), default=0)
        h = max((s["hand"] for s in t["steps"]), default=0)
        print(f"OK   {name}: {len(t['steps'])} steps, peak visual {v}, peak hand {h}")
    with open(idx_path, "w", encoding="utf-8") as f:
        json.dump(sorted(index), f, indent=1)
    print(f"index: {len(index)} timelines -> {OUT_DIR}")


if __name__ == "__main__":
    main()
