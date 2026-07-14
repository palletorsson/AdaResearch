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
PERF_RE = re.compile(
    r"anim|sim|life|flock|swarm|wave|automata|evolut|particle|pendulum|galton"
    r"|clock|counter|walker|running|flow|trace|scene|field", re.I)
TERRAIN_RE = re.compile(r"floor|carpet|mosaic|tiling|ground|terrain", re.I)
REACH_M = 2.5
PROMISE_M = 8.0
INSPECT_M = 4.0
WALK_MPS = 1.4

DWELL_PATH = os.path.join(ROOT, "commons", "data", "artifact_dwell.json")
try:
    _DW = json.load(open(DWELL_PATH, encoding="utf-8"))
except Exception:
    _DW = {"defaults": {}, "artifacts": {}}


TEXT_RE = re.compile(
    r"tutorial_wall|text_screen|info_board|chalk|plaque|sign|board|label"
    r"|wall_text|criticalinfo|code_display|reading|caption", re.I)
PROSE_WPM = 220.0
CODE_WPM = 80.0


def kind_of(base):
    """Desire kind (P-3): stated name-heuristic until interaction DNA is wired."""
    if TEXT_RE.search(base):
        return "tableau"
    if TERRAIN_RE.search(base):
        return "terrain"
    if HAND_RE.search(base):
        return "instrument"
    if PERF_RE.search(base):
        return "performer"
    return "specimen"


def reading_dwell(map_name):
    """P-6: the text is the clock — a map's tutorial.md read time in seconds
    (prose at 220 wpm, fenced code at 80 wpm), clamped to something walkable."""
    p = os.path.join(MAPS_DIR, map_name, "tutorial.md")
    if not os.path.isfile(p):
        return None
    text = open(p, encoding="utf-8", errors="replace").read()
    parts = re.split(r"```", text)
    prose_w = sum(len(seg.split()) for i, seg in enumerate(parts) if i % 2 == 0)
    code_w = sum(len(seg.split()) for i, seg in enumerate(parts) if i % 2 == 1)
    secs = prose_w / PROSE_WPM * 60 + code_w / CODE_WPM * 60
    return max(15, min(240, round(secs)))


def dwell_of(base, map_name=None):
    if base in _DW.get("artifacts", {}):
        return _DW["artifacts"][base]
    kind = kind_of(base)
    if kind == "tableau" and map_name and base.startswith("tutorial_wall"):
        r = reading_dwell(map_name)
        if r is not None:
            return r
    return _DW.get("defaults", {}).get(kind, 5)


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
    # ── the desire cycles (P-3): promise → approach → inspect → consummation,
    #    forking by kind; dwell is per-artifact (L-013). ──
    sightings = {}  # base -> list of (step, dist, pos)
    for sm in STEP_RE.finditer(log):
        step = int(sm.group(1))
        for vm in VIEW_RE.finditer(sm.group(4)):
            sightings.setdefault(base_of(vm.group(1)), []).append(
                (step, float(vm.group(4)), vm.group(3)))
    cycles = []
    dwell_total = 0.0
    for b, hits in sorted(sightings.items()):
        kind = kind_of(b)
        promise = next((s for s, dist, pos in hits
                        if dist >= PROMISE_M and pos == "CENTER"), None)
        if promise is None:
            promise = next((s for s, dist, _ in hits if dist >= PROMISE_M), None)
        min_dist = min(dist for _, dist, _ in hits)
        inspected = min_dist <= INSPECT_M
        dwell = dwell_of(b, map_name)
        if kind == "instrument":
            done = min_dist <= REACH_M
            consummation = "touch" if done else "OUT OF REACH"
        elif kind == "performer":
            done = inspected
            consummation = f"dwell {dwell}s" if done else "PASSED BY"
        elif kind == "terrain":
            done = True
            consummation = "underfoot"
        else:
            done = True
            consummation = "gaze"
        if done:
            dwell_total += dwell
        cycles.append({"artifact": b, "kind": kind,
                       "promise": promise, "inspected": inspected,
                       "consummation": consummation, "dwell_s": dwell,
                       "complete": done})
    # locomotion time from the walk's path length
    path_m = 0.0
    for a, b2 in zip(steps, steps[1:]):
        path_m += ((a["x"] - b2["x"]) ** 2 + (a["z"] - b2["z"]) ** 2) ** 0.5
    runtime = round(path_m / WALK_MPS + dwell_total, 1)
    complete = sum(1 for c in cycles if c["complete"])
    # ── modality alternation (P-6): reading exhausts; only doing/watching
    #    relieve. Flag any continuous reading run over the overload line. ──
    by_base = {c["artifact"]: c for c in cycles}
    visit_seq = []
    for s in steps:
        if s["visit"] and s["visit"] in by_base and s["visit"] not in visit_seq:
            visit_seq.append(s["visit"])
    run, longest_read = 0.0, 0.0
    for b in visit_seq:
        c = by_base[b]
        if c["kind"] == "tableau" and c["complete"]:
            run += c["dwell_s"]
            longest_read = max(longest_read, run)
        elif c["kind"] in ("instrument", "performer"):
            run = 0.0  # modality relief
    overload = longest_read > 90
    return {"map": map_name, "steps": steps, "classes": classes,
            "cycles": cycles,
            "summary": {"cycles": len(cycles), "complete": complete,
                        "incomplete": [c["artifact"] for c in cycles if not c["complete"]],
                        "path_m": round(path_m, 1),
                        "dwell_s": round(dwell_total, 1),
                        "runtime_s": runtime,
                        "longest_reading_run_s": round(longest_read, 1),
                        "reading_overload": overload},
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
