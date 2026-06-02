#!/usr/bin/env python3
"""Normalize every lab to the base grammar.

The lab is base + a small per-lab delta. This makes the base real:
  1. Ensure the four HARD fixtures are present at canonical positions
     (exit_sign above the door, palm_scanner by the door, fire_extinguisher,
     wall_placard on the east wall).
  2. Collapse the fragmented board role into ONE chalkboard per lab:
     whiteboard / info_board / info_screen  ->  chalkboard (generic).
     Existing *_chalkboard (e.g. point_chalkboard) is kept — it's the
     theme's content override of the default board.
  3. Dedupe: at most one board per lab.

Positions/configs come from base.lab.json. wall_placard is added with a
placeholder caption (title = lab name); the per-theme body is a later step.

Usage:
  python tools/normalize_labs.py            # dry run — print the plan
  python tools/normalize_labs.py --apply    # write changes (.bak each file)
"""
import json, glob, os, sys, shutil

LABS_DIR = os.path.join(os.path.dirname(__file__), "..", "commons", "labs")
APPLY = "--apply" in sys.argv

HARD = ["exit_sign", "palm_scanner", "fire_extinguisher", "wall_placard"]
NON_CHALK_BOARDS = {"whiteboard", "info_board", "info_screen"}

def is_chalk(n): return n == "chalkboard" or (n or "").endswith("_chalkboard")
def is_board(n): return n in NON_CHALK_BOARDS or is_chalk(n)
def lookup(p): return p.get("lookup_name") or p.get("lookupName")

# canonical fixture templates (from base.lab.json)
def tmpl(lookup_name, pos, roty, config, display):
    return {
        "id": "base_%s" % lookup_name,
        "lookup_name": lookup_name, "lookupName": lookup_name,
        "position": pos, "rotation_y": roty, "rotationY": roty,
        "config": config, "displayName": display,
    }

def hard_template(name, lab):
    if name == "exit_sign":
        return tmpl("exit_sign", [2.75, 0.45, 3.5], 180, {}, "EXIT (above door)")
    if name == "fire_extinguisher":
        return tmpl("fire_extinguisher", [3.6507272824504993, 0.35, 3.33], 180, {}, "Fire Extinguisher")
    if name == "palm_scanner":
        return tmpl("palm_scanner", [0.8, 0, 2.65], 180,
                    {"scan_active": True, "mounting": "podium", "scan_hold_seconds": 5, "auto_connect_door": True},
                    "Palm Scanner (door entry)")
    if name == "wall_placard":
        return tmpl("wall_placard", [3.92, 1.9395274470779431, 2.139437066008143], -90,
                    {"title": lab.replace("_", " ").upper(), "meta": "", "body": "", "no_collider": True},
                    "Wall placard (curatorial caption)")
    raise ValueError(name)

def normalize(lab, data):
    props = data.get("mounted_props", [])
    names = [lookup(p) for p in props]
    changes = []

    # 1. add missing hard fixtures
    for h in HARD:
        if h not in names:
            props.append(hard_template(h, lab))
            changes.append("+ %s (base fixture)" % h)

    # 2/3. board: keep one chalkboard-family board, convert/dedupe the rest
    board_idx = [i for i, p in enumerate(props) if is_board(lookup(p))]
    if board_idx:
        chalk_idx = [i for i in board_idx if is_chalk(lookup(props[i]))]
        keeper = chalk_idx[0] if chalk_idx else board_idx[0]
        kln = lookup(props[keeper])
        if not is_chalk(kln):
            props[keeper]["lookup_name"] = "chalkboard"
            props[keeper]["lookupName"] = "chalkboard"
            props[keeper]["config"] = {"no_collider": True}
            props[keeper]["displayName"] = "Chalkboard (default board)"
            changes.append("~ %s -> chalkboard" % kln)
        # drop the other boards
        drop = [i for i in board_idx if i != keeper]
        for i in sorted(drop, reverse=True):
            changes.append("- %s (duplicate board)" % lookup(props[i]))
            props.pop(i)

    data["mounted_props"] = props
    return changes

def main():
    files = sorted(glob.glob(os.path.join(LABS_DIR, "*.lab.json")))
    total = 0
    for f in files:
        lab = os.path.basename(f).replace(".lab.json", "")
        if lab == "base":
            continue
        data = json.load(open(f, encoding="utf-8"))
        changes = normalize(lab, data)
        if not changes:
            print("%-24s  ok (already base-complete)" % lab)
            continue
        total += len(changes)
        print("%-24s  %d change(s):" % (lab, len(changes)))
        for c in changes:
            print("    %s" % c)
        if APPLY:
            shutil.copyfile(f, f + ".bak")
            json.dump(data, open(f, "w", encoding="utf-8"), indent=2)
    print()
    print("%s — %d change(s) across labs%s" % (
        "APPLIED" if APPLY else "DRY RUN", total,
        "" if APPLY else "  (re-run with --apply to write, .bak each file)"))

if __name__ == "__main__":
    main()
