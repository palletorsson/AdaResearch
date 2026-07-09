#!/usr/bin/env python3
"""mission_graph.py — the map generated FROM the teaching arc (Dormans' move).

Mission/space decoupling: generate the MISSION first, then embed it in space.
Ada already has the mission — a chapter's baseline: the beat sequence (the
tutorial spine) + the voltage pieces (the critical charge). This tool turns
that graph into a walkable map built from wall_kit blocks:

  beats     -> rooms on a serpentine spine, one gate to the previous room,
               one to the next — the walk IS the lesson order
  voltage   -> side-chapels hanging off their nearest beat (the branch
               points where the critical trajectory leaves the tutorial)
  cast      -> each beat's artifact standing in its own room
  the rest  -> void; the map's outline is the mission's silhouette

Feature by role (rough semantics): arrive->field, move/trace->pinwheel,
repeat/grid/pattern->street, measure/census->colonnade, build-yourself->court,
voltage chapels alternate ledge (shrine) / court (pit).

Usage:
  python tools/mission_graph.py --seq=primitives [--name=Mission_Primitives]
  python tools/mission_graph.py --seq=randomness --cols=4
"""
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import wall_kit as wk

B, SEA = wk.B, wk.SEA


def feature_for(role: str, i: int) -> str:
    r = role.lower()
    if i == 0 or "arrive" in r or "appears" in r:
        return "field"
    if any(k in r for k in ("move", "trace", "walk", "rotate", "turn")):
        return "pinwheel"
    if any(k in r for k in ("repeat", "grid", "pattern", "tile", "mirror")):
        return "street"
    if any(k in r for k in ("measure", "census", "count", "seventeen", "prove")):
        return "colonnade"
    if any(k in r for k in ("build", "compose", "yourself", "design", "paint")):
        return "court"
    return ("pinwheel", "colonnade", "street", "field")[i % 4]


def load_mission(seq: str):
    p = ROOT / "doc" / "book" / "baselines" / f"{seq}.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    beats = [{"role": b.get("role", f"beat {i}"), "cast": b.get("cast", "")}
             for i, b in enumerate(d.get("beats", [])) if not b.get("missing")]
    volt = [v.get("piece", "") for v in d.get("voltage", []) if v.get("piece")]
    return beats, volt


def embed(beats, volt, cols):
    """serpentine spine + adjacent chapels. Returns rooms dict (r,c)->room."""
    n = len(beats)
    rows = math.ceil(n / cols) + 1          # buffer row for chapels
    order = []
    for r in range(rows):
        cs = range(cols) if r % 2 == 0 else range(cols - 1, -1, -1)
        order += [(r, c) for c in cs]
    spine = order[:n]
    rooms = {}
    for i, cell in enumerate(spine):
        rooms[cell] = {"kind": "beat", "i": i, "role": beats[i]["role"],
                       "cast": beats[i]["cast"],
                       "feature": feature_for(beats[i]["role"], i),
                       "gates": set()}
    for i in range(n - 1):
        a, b = spine[i], spine[i + 1]
        rooms[a]["gates"].add(b)
        rooms[b]["gates"].add(a)
    # chapels: voltage k attaches to its spread-out target beat
    for k, piece in enumerate(volt):
        t = round(k * (n - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n // 2
        target = spine[t]
        placed = False
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb = (target[0] + dr, target[1] + dc)
            if 0 <= nb[0] < rows and 0 <= nb[1] < cols and nb not in rooms:
                rooms[nb] = {"kind": "chapel", "i": k, "role": f"voltage: {piece}",
                             "cast": piece,
                             "feature": "ledge" if k % 2 == 0 else "court",
                             "gates": {target}}
                rooms[target]["gates"].add(nb)
                placed = True
                break
        if not placed:
            # host the piece inside its beat room instead
            rooms[target].setdefault("extra", []).append(piece)
    return rooms, spine, rows


def build(seq, name, cols):
    beats, volt = load_mission(seq)
    if not beats:
        print(f"no beats in baseline for {seq}")
        return 1
    rooms, spine, rows = embed(beats, volt, cols)
    W, H = cols * B, rows * B
    layers = {"structure": [["0"] * W for _ in range(H)],
              "utilities": [[" "] * W for _ in range(H)],
              "walls": [[""] * W for _ in range(H)],
              "interactables": [[" "] * W for _ in range(H)]}
    DIRS = {(-1, 0): 0, (0, 1): 1, (1, 0): 2, (0, -1): 3}   # n e s w
    for (br, bc), room in rooms.items():
        bl = wk.KIT[room["feature"]]()
        sides = ["s", "s", "s", "s"]
        for (dr, dc), i in DIRS.items():
            if (br + dr, bc + dc) in room["gates"]:
                sides[i] = "g"
        wk.perimeter(bl, tuple(sides))
        for r in range(B):
            for c in range(B):
                R, C = br * B + r, bc * B + c
                layers["structure"][R][C] = bl["structure"][r][c]
                layers["utilities"][R][C] = bl["utilities"][r][c]
                layers["walls"][R][C] = bl["walls"][r][c]
        # the cast stands in its room (clear of the sunken/raised centre)
        R0, C0 = br * B, bc * B
        if room.get("cast"):
            layers["interactables"][R0 + 1][C0 + B // 2] = room["cast"]
        for j, piece in enumerate(room.get("extra", [])):
            layers["interactables"][R0 + B - 2][C0 + 2 + j * 2] = piece
    # spawn in the first beat, exit teleporter in the last
    fr, fc = spine[0]
    layers["utilities"][fr * B + 1][fc * B + 1] = "sp"
    lr, lc = spine[-1]
    tr, tc = lr * B + B - 2, lc * B + B - 2
    layers["utilities"][tr][tc] = "t:restart"
    layers["structure"][tr][tc] = "0"
    mission = [{"beat": r["i"], "kind": r["kind"], "role": r["role"],
                "cast": r["cast"], "block": [br, bc]}
               for (br, bc), r in sorted(rooms.items(),
                                         key=lambda kv: (kv[1]["kind"], kv[1]["i"]))]
    data = {"map_info": {"name": name, "lookup_name": name, "title": name,
                         "mission_graph": {"seq": seq, "beats": len(beats),
                                           "chapels": len(volt),
                                           "rooms": mission}},
            "settings": {"wall_segments": {"style": "labwall", "height": 3.2,
                                        "thickness": 0.16, "door_width": 2.2}},
            "layers": layers}
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    print(f"{name}: {len(beats)} beats + {len(volt)} voltage -> "
          f"{len(rooms)} rooms on {cols}x{rows} blocks ({W}x{H} cells)")
    for i, cell in enumerate(spine):
        room = rooms[cell]
        chapels = [f" +[{rooms[g]['cast']}]" for g in room["gates"]
                   if g in rooms and rooms[g]["kind"] == "chapel"]
        print(f"  {i+1:2d}. {room['feature']:9s} {room['role'][:44]:44s} "
              f"<{room['cast']}>{''.join(chapels)}")
    print(f"view: /map-viewer?map={name}")
    return 0


def chunk_acts(n: int) -> list:
    """near-equal act sizes; 3 acts up to 11 beats, 4 beyond."""
    k = 3 if n <= 11 else 4
    base, rem = divmod(n, k)
    return [base + (1 if i < rem else 0) for i in range(k)]


def build_halls(seq, name):
    """ACT-HALLS: beats grouped into acts; each act = one WALL-LESS hall
    (blocks flow into each other, 'o' seams); features stand as stations;
    voltage chapels are the only enclosed rooms, inserted inline (the hall
    flows around the hut); ONE door between consecutive acts."""
    beats, volt = load_mission(seq)
    if not beats:
        print(f"no beats in baseline for {seq}")
        return 1
    sizes = chunk_acts(len(beats))
    # rows of entries: beats in act order, chapels inserted after their beat
    acts, gi = [], 0
    for sz in sizes:
        acts.append([{"kind": "beat", "i": gi + j, "role": beats[gi + j]["role"],
                      "cast": beats[gi + j]["cast"],
                      "feature": feature_for(beats[gi + j]["role"], gi + j)}
                     for j in range(sz)])
        gi += sz
    n = len(beats)
    for k, piece in enumerate(volt):
        t = round(k * (n - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n // 2
        for act in acts:
            for j, e in enumerate(act):
                if e["kind"] == "beat" and e["i"] == t:
                    act.insert(j + 1, {"kind": "chapel", "i": k,
                                       "role": f"voltage: {piece}", "cast": piece,
                                       "feature": "chapel"})
                    break
            else:
                continue
            break
    rows = len(acts)
    lens = [len(a) for a in acts]
    cols = max(lens)
    # walking direction serpentine at ACT level; door col between acts
    def col_of(r, j):                      # entry j of act r -> grid col
        return j if r % 2 == 0 else lens[r] - 1 - j
    grid = {}
    for r, act in enumerate(acts):
        for j, e in enumerate(act):
            grid[(r, col_of(r, j))] = e
    doors = {}                             # (r) -> door col between act r and r+1
    for r in range(rows - 1):
        doors[r] = min(lens[r], lens[r + 1]) - 1 if r % 2 == 0 else 0
    W, H = cols * B, rows * B
    layers = {"structure": [["0"] * W for _ in range(H)],
              "utilities": [[" "] * W for _ in range(H)],
              "walls": [[""] * W for _ in range(H)],
              "interactables": [[" "] * W for _ in range(H)]}
    for (r, c), e in grid.items():
        bl = wk.KIT[e["feature"]]()
        sides = ["s", "s", "s", "s"]       # n e s w
        if (r, c + 1) in grid:
            sides[1] = "o"                 # the hall flows
        if (r, c - 1) in grid:
            sides[3] = "o"
        if (r - 1, c) in grid:
            sides[0] = "g" if doors.get(r - 1) == c else "s"
        if (r + 1, c) in grid:
            sides[2] = "g" if doors.get(r) == c else "s"
        wk.perimeter(bl, tuple(sides))
        R0, C0 = r * B, c * B
        for rr in range(B):
            for cc in range(B):
                layers["structure"][R0 + rr][C0 + cc] = bl["structure"][rr][cc]
                layers["utilities"][R0 + rr][C0 + cc] = bl["utilities"][rr][cc]
                layers["walls"][R0 + rr][C0 + cc] = bl["walls"][rr][cc]
        if e.get("cast"):
            if e["feature"] == "chapel":
                layers["interactables"][R0 + 3][C0 + 3] = e["cast"]   # inside the hut
            else:
                layers["interactables"][R0 + 1][C0 + B // 2] = e["cast"]
    fr, fc = 0, col_of(0, 0)
    layers["utilities"][fr * B + 1][fc * B + 1] = "sp"
    lr = rows - 1
    lc = col_of(lr, lens[lr] - 1)
    tr, tc = lr * B + B - 2, lc * B + B - 2
    layers["utilities"][tr][tc] = "t:restart"
    layers["structure"][tr][tc] = "0"
    # per-act wall palettes: the act arc as a material register — arrival is
    # bright (glass/whiteboard/window), work is serviced (conduit/display/
    # locker), depth is industrial (hazard/rib/slit). Rects in CELL coords;
    # the Three.js viewer seeds each act's walls from its own weight table.
    PALETTES = {
        "arrival": {"plain": 5, "glass": 3, "whiteboard": 2, "window": 3,
                    "vent": 1, "locker": 1},
        "work":    {"plain": 4, "conduit": 3, "display": 2, "locker": 2,
                    "vent": 2, "window": 1, "beam": 1},
        "depth":   {"plain": 3, "hazard": 2, "rib": 3, "beam": 2, "slit": 2,
                    "conduit": 2, "vent": 1},
    }
    def act_palette(k):
        if k == 0:
            return "arrival"
        return "depth" if k == rows - 1 else "work"
    palettes = [{"act": r, "name": act_palette(r),
                 "rect": [0, r * B, W - 1, (r + 1) * B - 1],
                 "weights": PALETTES[act_palette(r)]} for r in range(rows)]
    data = {"map_info": {"name": name, "lookup_name": name, "title": name,
                         "mission_graph": {"seq": seq, "mode": "act-halls",
                                           "acts": lens, "doors": doors}},
            "settings": {"wall_segments": {"style": "labwall", "height": 3.2,
                                        "thickness": 0.16, "door_width": 2.2,
                                        "palettes": palettes}},
            "layers": layers}
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    print(f"{name}: {len(beats)} beats + {len(volt)} voltage -> "
          f"{rows} act-halls {lens} ({W}x{H} cells)")
    for r, act in enumerate(acts):
        marks = " · ".join((f"[{e['cast']}]" if e["kind"] == "chapel"
                            else f"{e['feature']}:{e['cast']}") for e in act)
        arrow = "→" if r % 2 == 0 else "←"
        print(f"  act {r+1} {arrow}  {marks}")
        if r in doors:
            print(f"         door at col {doors[r]}")
    print(f"view: /map-viewer?map={name}")
    return 0


def main() -> int:
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    seq = arg("seq", None)
    if not seq:
        print(__doc__)
        return 1
    mode = arg("mode", "halls")
    if mode == "chain":
        cols = int(arg("cols", "3"))
        name = arg("name", f"Mission_{seq.title().replace('_','')}")
        return build(seq, name, cols)
    name = arg("name", f"MissionHall_{seq.title().replace('_','')}")
    return build_halls(seq, name)


if __name__ == "__main__":
    sys.exit(main())
