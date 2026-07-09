#!/usr/bin/env python3
"""wall_props.py — the wall-prop pass: props attach to RUN SLOTS.

The runs (settings.wall_runs, tools/wall_runs.py) made walls addressable:
"run 7, module 2" is a place. This pass composes the hospitality layer onto
those places — the momo answer to bare corridors:

  RULES (deterministic, seeded by run key):
    - beside every DOOR module: a fire_extinguisher or exit_sign
      (safety lives at thresholds — and alternates so pairs differ)
    - long runs (>= 7 modules): one register prop at the 1/3 point
        arrival -> info_board          (orientation for the newly arrived)
        work    -> fire_hose_box       (service where the work is)
        depth   -> fire_extinguisher   (danger deepens)
    - never against glazing (glass/window/slit) or displays or doorframes
    - only into a floor cell that is in-bounds and unoccupied; the prop
      faces INTO the room (rotation from which side of the wall it stands)

Placements are recorded in settings.wall_props (legible, undoable) and
materialized as interactables tokens. MAP-LEVEL: works on any map with
compiled wall_runs.

Usage:
  python tools/wall_props.py --map=<Name>
  (generators call annotate(data, name) after wall_runs)
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from wall_runs import fnv

SKIP_VARIANTS = {"glass", "window", "slit", "display", "doorframe"}
DOOR_PROPS = ["fire_extinguisher", "exit_sign"]
REGISTER_PROP = {"arrival": "info_board", "work": "fire_hose_box",
                 "depth": "fire_extinguisher"}
# facing INTO the room (furnish convention: :180 faces south off a north wall)
ROT = {"n": 180, "s": 0, "w": 90, "e": 270}


def _register_at(palettes, x, z):
    for p in palettes:
        c0, r0, c1, r1 = p.get("rect", [0, 0, -1, -1])
        if c0 <= x <= c1 and r0 <= z <= r1:
            return p.get("name", "work")
    return "work"


def _candidates(run, i):
    """the two room-side cells for module i of a run, with the wall's edge
    letter as seen FROM that cell (for facing)."""
    if run["axis"] == "h":
        ex, ez = run["x"] + i, run["z"]
        return [((ex, ez), "n"), ((ex, ez - 1), "s")]
    ex, ez = run["x"], run["z"] + i
    return [((ex, ez), "w"), ((ex - 1, ez), "e")]


def annotate(data: dict, map_name: str) -> dict:
    wr = data.get("settings", {}).get("wall_runs", {})
    runs = wr.get("runs", [])
    if not runs:
        return data
    layers = data["layers"]
    st, inter = layers["structure"], layers["interactables"]
    palettes = data.get("settings", {}).get("wall_segments", {}).get("palettes", [])
    H, W = len(st), max(len(r) for r in st)

    def floor_free(x, z):
        if not (0 <= z < H and 0 <= x < W):
            return False
        s = str(st[z][x]).strip()
        return s not in ("", "0") and not str(inter[z][x]).strip()

    placed = []

    def try_place(run, ri, i, prop):
        m = run["modules"][i]
        if m.get("v") in SKIP_VARIANTS and not m.get("door"):
            return False
        for (x, z), edge in _candidates(run, i):
            if floor_free(x, z):
                inter[z][x] = f"{prop}:{ROT[edge]}"
                placed.append({"run": ri, "module": i, "cell": [x, z],
                               "prop": prop})
                return True
        return False

    for ri, run in enumerate(runs):
        rk = f"{map_name}:props:{run['axis']}:{run['x']}:{run['z']}"
        mods = run["modules"]
        # safety beside doors: the module after (or before) each door
        door_n = 0
        for i, m in enumerate(mods):
            if not m.get("door"):
                continue
            prop = DOOR_PROPS[(fnv(rk) + door_n) % len(DOOR_PROPS)]
            door_n += 1
            for j in (i + 1, i - 2):        # skip the door pair itself
                if 0 <= j < len(mods) and not mods[j].get("door"):
                    if try_place(run, ri, j, prop):
                        break
        # one register prop at the 1/3 point of long runs
        if len(mods) >= 7:
            i = len(mods) // 3
            if not mods[i].get("door"):
                if run["axis"] == "h":
                    cx, cz = run["x"] + i, run["z"]
                else:
                    cx, cz = run["x"], run["z"] + i
                reg = _register_at(palettes, cx, max(0, cz - 1))
                try_place(run, ri, i, REGISTER_PROP.get(reg, "info_board"))

    data.setdefault("settings", {})["wall_props"] = placed
    return data


def main() -> int:
    arg = lambda k: next((a.split("=", 1)[1] for a in sys.argv
                          if a.startswith(f"--{k}=")), None)
    if not arg("map"):
        print(__doc__)
        return 1
    p = ROOT / "commons" / "maps" / arg("map") / "map_data.json"
    data = json.loads(p.read_text(encoding="utf-8"))
    name = data.get("map_info", {}).get("lookup_name", arg("map"))
    annotate(data, name)
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    print(f"{arg('map')}: {len(data['settings'].get('wall_props', []))} wall props placed")
    for pl in data["settings"].get("wall_props", [])[:12]:
        print("  ", pl["prop"], "at", pl["cell"], f"(run {pl['run']} module {pl['module']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
