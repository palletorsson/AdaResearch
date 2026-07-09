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
import staging_beds as sb

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
    beats = [{"role": b.get("role", f"beat {i}"), "cast": b.get("cast", ""),
              "alts": b.get("alts", [])}
             for i, b in enumerate(d.get("beats", [])) if not b.get("missing")]
    volt = [v.get("piece", "") for v in d.get("voltage", []) if v.get("piece")]
    return beats, volt


# ── cast size governance (the oracle rules the room) ────────────────────────
# runtime-growers: static AABB measures ~0 but the artifact expands while
# running (ribbons, sprawling traces) — treat as oversize in confined rooms
RUNTIME_GROWERS = {"player_trace"}
_SIZES = None

def _sizes():
    global _SIZES
    if _SIZES is None:
        p = ROOT / "commons" / "data" / "artifact_sizes.json"
        _SIZES = json.loads(p.read_text(encoding="utf-8")).get("sizes", {})
    return _SIZES

def _fit(name: str, max_fp: float, max_h: float):
    """(fits, footprint) — None footprint = unmeasured (runtime-growers like
    player_trace measure 0.0; treat as suspect, prefer a measured alt)."""
    s = _sizes().get(name)
    if not s or not s.get("base_m"):
        return None, None
    fp = max(s.get("grid_cells", [1, 1]))
    h = s.get("height_m", 1.0)
    return (fp <= max_fp and h <= max_h), fp

def resolve_cast(cast: str, alts: list, max_fp: float, max_h: float):
    """the cast if it measurably fits; else the smallest measured alt that
    fits; else the smallest measured candidate. Returns (name, swapped_from)."""
    ok, _ = _fit(cast, max_fp, max_h)
    if ok:
        return cast, None
    fitting, measured = [], []
    for a in alts:
        a_ok, a_fp = _fit(a, max_fp, max_h)
        if a_ok:
            fitting.append((a_fp, a))
        if a_fp is not None:
            measured.append((a_fp, a))
    if fitting:
        return min(fitting)[1], cast
    if measured:
        return min(measured)[1], cast
    # nothing measured among the alts. If the cast itself is KNOWN bad —
    # measured-oversize (ok is False) or a runtime-grower on the suspect
    # list — an unmeasured alt (curator's first pick) beats keeping it.
    if (ok is False or cast in RUNTIME_GROWERS) and alts:
        return alts[0], cast
    return cast, None


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
                         "dimensions": {"width": W, "depth": H,
                                        "max_height": 3},
                         "mission_graph": {"seq": seq, "beats": len(beats),
                                           "chapels": len(volt),
                                           "rooms": mission}},
            "settings": {"wall_segments": {"style": "labwall", "height": 3.2,
                                        "thickness": 0.16, "door_width": 2.2}},
            "layers": layers}
    import wall_runs as _wr
    _wr.annotate(data, name)   # marriage 2: runs live in the map
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


# -- act-halls v3: varying hall sizes, features FILL the hall (2m aisles) ----
# Palle (on the sparse 14-cell rings): "different size halls, and the middle
# room fills so the hall wall towards the wall is two m." Each act is ONE hall
# whose depth varies by register; each entry's feature scales to F = depth-4,
# leaving a 2-cell (2m) aisle to every wall. Stations sit at a F+2 pitch.

ACT_DEPTH = {"arrival": 14, "work": 18, "depth": 16}
AISLE = 3        # the inner corridor: feature-to-wall and station-to-station


def _wall(layers, r, c, code):
    if code not in layers["walls"][r][c]:
        layers["walls"][r][c] += code


def draw_feature(layers, feature, oy, ox, F):
    """scaled feature drawn straight into the stitched layers at (oy, ox)."""
    st, ut = layers["structure"], layers["utilities"]
    mid = F // 2
    if feature == "court":
        for r in range(2, F - 2):
            for c in range(2, F - 2):
                st[oy + r][ox + c] = "1"
        ut[oy + mid][ox + 2] = "wp:-90"
        ut[oy + mid][ox + F - 3] = "wp:90"
    elif feature == "ledge":
        d = max(2, F // 3)
        for r in range(1, 1 + d):
            for c in range(2, F - 2):
                st[oy + r][ox + c] = "3"
        ut[oy + 1 + d][ox + mid - 1] = "wp:180"
        ut[oy + 1 + d][ox + mid] = "wp:180"
    elif feature == "street":
        for c in range(F):
            if c not in (mid - 1, mid):
                _wall(layers, oy + mid, ox + c, "n")
    elif feature == "colonnade":
        for (r, c) in ((2, 2), (2, F - 3), (F - 3, 2), (F - 3, F - 3)):
            for code in "nesw":
                _wall(layers, oy + r, ox + c, code)
    elif feature == "pinwheel":
        arm = max(3, F // 2 - 1)
        a0 = (F - arm) // 2
        for c in range(a0, a0 + arm):
            _wall(layers, oy + mid - 2, ox + c, "n")
            _wall(layers, oy + mid + 2, ox + min(c + 1, F - 1), "s")
        for r in range(a0, a0 + arm):
            _wall(layers, oy + r, ox + mid + 2, "e")
            _wall(layers, oy + min(r + 1, F - 1), ox + mid - 2, "w")
    elif feature == "chapel":
        # a real room in the hall: 6x6 hut, one 2-wide door facing the walk
        S = min(6, F - 2)
        h0 = (F - S) // 2
        door = (h0 + S // 2 - 1, h0 + S // 2)
        for c in range(h0, h0 + S):
            if c not in door:
                _wall(layers, oy + h0, ox + c, "n")
            _wall(layers, oy + h0 + S - 1, ox + c, "s")
        for r in range(h0, h0 + S):
            _wall(layers, oy + r, ox + h0, "w")
            _wall(layers, oy + r, ox + h0 + S - 1, "e")
    # field: nothing -- the breathing room


def cast_spot(feature, oy, ox, F):
    mid = F // 2
    if feature == "ledge":
        return oy + 1, ox + mid            # on the overlook
    if feature == "street":
        return oy + mid + 2, ox + mid      # beside the door
    return oy + mid, ox + mid              # court pit / hut / centre


def build_halls(seq, name):
    """acts as single halls of varying size; features fill them (2m aisles);
    voltage chapels the only enclosed rooms; one carved door between acts."""
    beats, volt = load_mission(seq)
    if not beats:
        print(f"no beats in baseline for {seq}")
        return 1
    sizes = chunk_acts(len(beats))
    acts, gi = [], 0
    for sz in sizes:
        row_entries = []
        for j in range(sz):
            b = beats[gi + j]
            row_entries.append({"kind": "beat", "i": gi + j, "role": b["role"],
                                "cast": b["cast"], "alts": b.get("alts", []),
                                "feature": feature_for(b["role"], gi + j)})
        acts.append(row_entries)
        gi += sz
    n = len(beats)
    for k, piece in enumerate(volt):
        t = round(k * (n - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n // 2
        for act in acts:
            for j, e in enumerate(act):
                if e["kind"] == "beat" and e["i"] == t:
                    act.insert(j + 1, {"kind": "chapel", "i": k,
                                       "role": "voltage: " + piece, "cast": piece,
                                       "alts": [], "feature": "chapel"})
                    break
            else:
                continue
            break
    rows = len(acts)

    def register(k):
        if k == 0:
            return "arrival"
        return "depth" if k == rows - 1 else "work"

    depths = [ACT_DEPTH[register(k)] for k in range(rows)]
    Fs = [d - 2 * AISLE for d in depths]
    widths = [AISLE + len(a) * (Fs[k] + AISLE) for k, a in enumerate(acts)]
    W = max(widths)
    H = sum(depths)
    layers = {"structure": [["0"] * W for _ in range(H)],
              "utilities": [[" "] * W for _ in range(H)],
              "walls": [[""] * W for _ in range(H)],
              "interactables": [[" "] * W for _ in range(H)]}
    y = 0
    y0s, swaps = [], []
    for k, act in enumerate(acts):
        D, F, Wk = depths[k], Fs[k], widths[k]
        y0s.append(y)
        for r in range(D):
            for c in range(Wk):
                layers["structure"][y + r][c] = SEA
        for c in range(Wk):
            _wall(layers, y, c, "n")
            _wall(layers, y + D - 1, c, "s")
        for r in range(D):
            _wall(layers, y + r, 0, "w")
            _wall(layers, y + r, Wk - 1, "e")
        entries = act if k % 2 == 0 else list(reversed(act))
        for j, e in enumerate(entries):
            ox = AISLE + j * (F + AISLE)
            oy = y + AISLE
            budget_fp = 4.0 if e["feature"] == "chapel" else float(F - 2)
            budget_h = 3.0 if e["feature"] == "chapel" else 3.4
            chosen, swapped = resolve_cast(e["cast"], e["alts"], budget_fp, budget_h)
            e["cast"] = chosen
            if swapped:
                swaps.append(swapped + "->" + chosen)
            draw_feature(layers, e["feature"], oy, ox, F)
            cr, cc = cast_spot(e["feature"], oy, ox, F)
            # MARRIAGE 1: the bed carries the artifact (staging_beds decides
            # the body — plinth/table/platform/pit/panel/vitrine by measured
            # footprint; same convention as furnish_gallery)
            bed = sb.select_bed(chosen)
            if bed["is_wall"] and e["feature"] != "chapel":
                cr, cc = y + 1, ox + F // 2      # graphics hang on the hall wall
                layers["interactables"][cr][cc] = f"{bed['bed']}:180#mount:{chosen}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{chosen}"
        y += D
    # carve ONE door between consecutive acts, near the walking end
    for k in range(rows - 1):
        yb = y0s[k + 1]
        ov = min(widths[k], widths[k + 1])
        xs = (ov - 4, ov - 3) if k % 2 == 0 else (2, 3)
        for x in xs:
            layers["walls"][yb - 1][x] = layers["walls"][yb - 1][x].replace("s", "")
            layers["walls"][yb][x] = layers["walls"][yb][x].replace("n", "")
    layers["utilities"][2][2] = "sp"
    lr = rows - 1
    tx = widths[lr] - 3 if lr % 2 == 0 else 2
    ty = y0s[lr] + depths[lr] - 3
    layers["utilities"][ty][tx] = "t:restart"
    layers["structure"][ty][tx] = "0"
    PALETTES = {
        "arrival": {"plain": 5, "glass": 3, "whiteboard": 2, "window": 3,
                    "vent": 1, "locker": 1},
        "work":    {"plain": 4, "conduit": 3, "display": 2, "locker": 2,
                    "vent": 2, "window": 1, "beam": 1},
        "depth":   {"plain": 3, "hazard": 2, "rib": 3, "beam": 2, "slit": 2,
                    "conduit": 2, "vent": 1},
    }
    ACCENTS = {"arrival": [1.0, 0.62, 0.18], "work": [0.25, 0.85, 1.0],
               "depth": [1.0, 0.25, 0.15]}
    palettes = [{"act": k, "name": register(k),
                 "rect": [0, y0s[k], W - 1, y0s[k] + depths[k] - 1],
                 "weights": PALETTES[register(k)],
                 "accent": ACCENTS[register(k)]} for k in range(rows)]
    data = {"map_info": {"name": name, "lookup_name": name, "title": name,
                         "dimensions": {"width": W, "depth": H,
                                        "max_height": 3},
                         "mission_graph": {"seq": seq, "mode": "act-halls-v3",
                                           "acts": [len(a) for a in acts],
                                           "depths": depths, "swaps": swaps}},
            "settings": {"wall_segments": {"style": "labwall", "height": 3.2,
                                           "thickness": 0.16, "door_width": 2.2,
                                           "palettes": palettes}},
            "layers": layers}
    import wall_runs as _wr
    _wr.annotate(data, name)   # marriage 2: runs live in the map
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    print(f"{name}: {len(beats)} beats + {len(volt)} voltage -> {rows} act-halls "
          f"depths {depths} ({W}x{H} cells)")
    for k, act in enumerate(acts):
        marks = " - ".join((("[" + e["cast"] + "]") if e["kind"] == "chapel"
                            else e["feature"] + ":" + e["cast"]) for e in act)
        print(f"  act {k+1} D={depths[k]}  {marks}")
    if swaps:
        print("  size-governed swaps:", ", ".join(swaps))
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
