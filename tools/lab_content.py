#!/usr/bin/env python3
"""Per-theme lab CONTENT — the delta on top of the base grammar.

The base grammar (fixtures + a chalkboard) is shared; what varies per lab is
CONTENT: the wall_placard caption and which chalkboard subject hangs on the
west wall. This sets both per lab, in one place.

  - wall_placard.config = {title, meta, body}  (the curatorial caption)
  - the board's lookup swaps generic `chalkboard` -> the theme's *_chalkboard
    (where one exists); position/rotation are kept.

base and point_one are left as-is (already canonical/point-themed).

Usage:
  python tools/lab_content.py           # dry run
  python tools/lab_content.py --apply   # write (.bak each file)
"""
import json, glob, os, sys, shutil

LABS_DIR = os.path.join(os.path.dirname(__file__), "..", "commons", "labs")
APPLY = "--apply" in sys.argv

def is_chalk(n): return n == "chalkboard" or (n or "").endswith("_chalkboard")
def lookup(p): return p.get("lookup_name") or p.get("lookupName")

# lab -> { board: <theme chalkboard or None to keep>, placard: {title, meta, body} }
CONTENT = {
    "point_line": {"board": "line_chalkboard", "placard": {
        "title": "THE LINE", "meta": "PRIMITIVES · 02 · 2036",
        "body": "A line is a point that refused to stay still — the first relation: distance, direction, between."}},
    "point_triangle": {"board": None, "placard": {
        "title": "THE TRIANGLE", "meta": "PRIMITIVES · 04 · 2036",
        "body": "Three points, three lines: the first enclosed plane. Rigidity born from relation."}},
    "primitives_polythedra": {"board": "polyhedra_chalkboard", "placard": {
        "title": "POLYHEDRA", "meta": "PRIMITIVES · 06 · 2036",
        "body": "Points become edges become faces become solids — the Platonic family of closed form."}},
    "primitives_test": {"board": None, "placard": {
        "title": "PRIMITIVES", "meta": "PRIMITIVES · 00 · 2036",
        "body": "The atoms of computation: dimensionless points become lines, planes, worlds."}},
    "simpel_lab": {"board": None, "placard": {
        "title": "THE LAB", "meta": "ADA · 2036",
        "body": "A safe room — state the concept, hold it in the hand, then step out to the grid."}},
    "trace": {"board": "trace_chalkboard", "placard": {
        "title": "THE TRACE", "meta": "PRIMITIVES · 03 · 2036",
        "body": "Duration and residue — geometry as lived process. No original behind the trace, only encodings."}},
    "monte_carlo_room": {"board": None, "placard": {
        "title": "RANDOMNESS", "meta": "ENTROPY · 07 · 2036",
        "body": "Disorder as a creative force. Monte Carlo — approach the truth by sampling chance."}},
    "qfep_phase_chamber": {"board": "qfep_chalkboard", "placard": {
        "title": "QFEP LABORATORY", "meta": "SYNTHESIS · 18 · 2036",
        "body": "The whole formula embodied: form and entropy oscillating across the edge toward synthesis."}},
    "foundations_crisis_hall": {"board": "ignorance_chalkboard", "placard": {
        "title": "THE FOUNDATIONS CRISIS", "meta": "SYNTHESIS · 17 · 2036",
        "body": "Gödel, Russell: any system that can count cannot prove its own consistency. The limit is structural."}},
    "turing_machine_lab": {"board": None, "placard": {
        "title": "THE TURING MACHINE", "meta": "INTEGRATION · 13 · 2036",
        "body": "A tape, a head, a table of rules — the minimal machine that computes anything computable."}},
}

def apply_content(lab, data, spec):
    props = data.get("mounted_props", [])
    changes = []
    # placard caption
    for p in props:
        if lookup(p) == "wall_placard":
            cfg = p.get("config") or {}
            cfg.update(spec["placard"]); cfg["no_collider"] = True
            p["config"] = cfg
            changes.append("placard: %s" % spec["placard"]["title"])
            break
    # chalkboard subject swap
    if spec["board"]:
        for p in props:
            if is_chalk(lookup(p)):
                old = lookup(p)
                if old != spec["board"]:
                    p["lookup_name"] = spec["board"]; p["lookupName"] = spec["board"]
                    p["displayName"] = spec["board"].replace("_", " ").title()
                    changes.append("board: %s -> %s" % (old, spec["board"]))
                break
    # keep the room's generated chalkboard in sync with the mounted board, so a
    # lab never shows two mismatched boards (the mounted prop is the moveable one).
    board_now = next((lookup(p) for p in props if is_chalk(lookup(p))), None)
    room = data.setdefault("lab_room", {})
    if board_now and room.get("chalkboard_lookup") != board_now:
        room["chalkboard_lookup"] = board_now
        changes.append("room.chalkboard_lookup -> %s" % board_now)
    return changes

def main():
    total = 0
    for f in sorted(glob.glob(os.path.join(LABS_DIR, "*.lab.json"))):
        lab = os.path.basename(f).replace(".lab.json", "")
        if lab not in CONTENT:
            continue
        data = json.load(open(f, encoding="utf-8"))
        changes = apply_content(lab, data, CONTENT[lab])
        if not changes:
            print("%-24s  (no change)" % lab); continue
        total += len(changes)
        print("%-24s  %s" % (lab, " | ".join(changes)))
        if APPLY:
            shutil.copyfile(f, f + ".bak")
            json.dump(data, open(f, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print()
    print("%s — %d change(s)%s" % ("APPLIED" if APPLY else "DRY RUN", total,
        "" if APPLY else "  (--apply to write)"))

if __name__ == "__main__":
    main()
