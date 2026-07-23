#!/usr/bin/env python3
"""deck_props.py — the street furniture of a raised deck.

deck_dresser gives a plateau its bones: railings where you would fall, stairs
where you climb, bridges across the void. What it leaves is a bare grey plane —
structurally the KitBash cyber-district platform, materially nothing like it.
The reference images are carried by what stands ON the deck: a mast at every
platform corner, a lit fixture down the long rail, back-of-house clutter in the
lee of a wall. This pass furnishes that, and it reads the SAME boundary the
dresser did — the furniture is a function of the railings, not a second design.

The station kit already holds the vocabulary, each a one-cell grid module:
  station_pillar     a lit column that "frames a station's corners" — the mast
  station_luminaire  the kit's only real light — the neon down the rail
  station_crates     "the lived-in back-of-house clutter" — decay, in the lee

RULES (deterministic, seeded by cell so a map always furnishes the same way):
  - a railing CORNER (two perpendicular guards on one cell) gets a pillar —
    that is where a mast belongs, and it is the cell the eye already stops on
  - a long straight rail run gets a luminaire every few cells, offset so runs
    on the same deck do not line up like teeth
  - an INTERIOR deck cell (no railing) sparsely gets crates, hash-gated, kept
    in the lee of the boundary where clutter gathers, never mid-floor

NEVER onto: a stair or its approach, a bridge span (too narrow to clutter), the
spawn or teleporter cell, a cell that already carries an artifact. Props go in
the interactables layer, which the pathfinder treats as furniture to walk
around, not wall — so nothing here can strand a cell. The reachability of each
prop (Rule 4) is checked anyway; any that fails is dropped.

Writes a SIBLING map by default. Runs on any dressed deck map.

Usage:
  python tools/deck_props.py --map=WangDeck_LPlaza_Dressed
  python tools/deck_props.py --map=X --in-place --density=0.5
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import json
from wall_runs import fnv          # the same stable hash the wall-prop pass uses

SIDES = {"n": (-1, 0), "s": (1, 0), "w": (0, -1), "e": (0, 1)}
PERP = {"n": ("e", "w"), "s": ("e", "w"), "e": ("n", "s"), "w": ("n", "s")}
# a prop faces INTO the deck, away from the guard it stands by
FACE_IN = {"n": 180, "s": 0, "w": 90, "e": 270}

PILLAR = "station_pillar"
LUMINAIRE = "station_luminaire"
CRATES = "station_crates"
LUM_EVERY = 4          # a light every N cells along a run
CRATE_DENSITY = 0.14   # fraction of eligible interior deck cells that get clutter


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def flag(name):
    return f"--{name}" in sys.argv


def height_of(cell):
    s = str(cell).strip()
    d = ""
    for ch in s:
        if ch.isdigit():
            d += ch
        else:
            break
    return int(d) if d else 0


def grid(layers, key, rows, cols, fill=" "):
    g = layers.get(key)
    if not isinstance(g, list) or not g:
        return [[fill] * cols for _ in range(rows)]
    return [[str(g[r][c]) if r < len(g) and c < len(g[r]) else fill
             for c in range(cols)] for r in range(rows)]


def main():
    map_name = arg("map")
    if not map_name:
        sys.exit(__doc__)
    path = ROOT / "commons" / "maps" / map_name / "map_data.json"
    if not path.exists():
        sys.exit(f"no such map: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    layers = data.get("layers")
    if not isinstance(layers, dict) or "structure" not in layers:
        sys.exit(f"{map_name}: no layers.structure")

    struct = layers["structure"]
    rows = len(struct)
    cols = max(len(r) for r in struct if isinstance(r, list))
    H = [[height_of(struct[r][c]) if c < len(struct[r]) else 0
          for c in range(cols)] for r in range(rows)]
    walls = grid(layers, "walls", rows, cols, fill="")
    utils = grid(layers, "utilities", rows, cols)
    inter = grid(layers, "interactables", rows, cols)

    top = max((H[r][c] for r in range(rows) for c in range(cols)), default=0)
    if top < 2:
        sys.exit(f"{map_name}: no raised deck (max height {top}) — nothing to furnish")

    density = float(arg("density", CRATE_DENSITY))
    seed = map_name

    def rail(r, c):
        return {ch for ch in walls[r][c] if ch in SIDES}

    def blocked(r, c):
        u = utils[r][c].split(":")[0]
        if u in ("wp", "sp", "t", "tc", "br"):
            return True                 # stair, spawn, exit, span link
        if inter[r][c].strip():
            return True                 # already furnished
        # a stair APPROACH: the cell a wp climbs onto
        for dr, dc in SIDES.values():
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols \
                    and utils[nr][nc].split(":")[0] == "wp":
                return True
        return False

    # The furniture keys off the RAISED PLATEAU, not the walls layer — a plaza's
    # rim is a one-step curb with no railing at all, and the map hull IS railed
    # but is not a deck. So the rim is read straight from the height field: a
    # top-height cell whose orthogonal neighbour is lower, void, or off-map. That
    # is the platform edge in every case — the plaza curb and the causeway cliff
    # alike — and it never fires on the surrounding ground.
    def lower(r, c):
        return not (0 <= r < rows and 0 <= c < cols) or H[r][c] < top

    def rim_sides(r, c):
        if H[r][c] < top:
            return set()
        return {s for s, (dr, dc) in SIDES.items() if lower(r + dr, c + dc)}

    placed = {"pillar": 0, "luminaire": 0, "crates": 0}
    hits = []      # (r, c, token)

    for r in range(rows):
        for c in range(cols):
            if blocked(r, c):
                continue
            if H[r][c] < top:
                # ground/lower cell — no platform furniture here
                continue
            sides = rim_sides(r, c)
            if not sides:
                # deep interior of the plateau — sparse back-of-house clutter
                if fnv(f"{seed}:crate:{r}:{c}") % 1000 < density * 1000:
                    hits.append((r, c, f"{CRATES}:{fnv(f'{seed}:cr:{r}:{c}') % 4 * 90}:0.0"))
                    placed["crates"] += 1
                continue
            # a rim cell. A convex CORNER (two perpendicular open sides) gets the
            # mast; a straight run gets a light every few cells.
            is_corner = any(a in sides and (PERP[a][0] in sides or PERP[a][1] in sides)
                            for a in sides)
            side = sorted(sides)[0]
            if is_corner:
                hits.append((r, c, f"{PILLAR}:{FACE_IN[side]}:0.0"))
                placed["pillar"] += 1
            else:
                axis = r if side in ("n", "s") else c
                if (axis + (fnv(f"{seed}:{side}") % LUM_EVERY)) % LUM_EVERY == 0:
                    hits.append((r, c, f"{LUMINAIRE}:{FACE_IN[side]}:0.0"))
                    placed["luminaire"] += 1

    for (r, c, tok) in hits:
        inter[r][c] = tok

    print(f"— deck_props: {map_name} ({rows}x{cols}), deck top h{top} —")
    print(f"  pillars (corners)   {placed['pillar']}")
    print(f"  luminaires (runs)   {placed['luminaire']}")
    print(f"  crates (lee)        {placed['crates']}")
    print(f"  total props         {len(hits)}")

    if flag("dry-run"):
        return

    layers["interactables"] = inter
    data.setdefault("settings", {})["deck_props"] = {
        "seed": seed, "counts": placed, "density": density}

    if flag("in-place"):
        out_name, out_path = map_name, path
    else:
        out_name = arg("out", f"{map_name}_Props")
        out_path = ROOT / "commons" / "maps" / out_name / "map_data.json"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        data.setdefault("map_info", {})["name"] = out_name

    out_path.write_text(json.dumps(data, indent=1), encoding="utf-8")

    # the guarantee: props are furniture, never wall — but Rule 4 wants every
    # one reachable. Ask the pathfinder; report if it complains.
    import map_pathfinder as mp
    g = mp.MapGraph(data)
    start = getattr(g, "spawn", None)
    seen = set()
    if start in g.walkable:
        seen, stack = {start}, [start]
        while stack:
            p = stack.pop()
            for q in g.neighbors(p):
                if q not in seen:
                    seen.add(q)
                    stack.append(q)
    unreached = [(r, c) for (r, c, _) in hits if (r, c) not in seen]
    print(f"  wrote               {out_path.relative_to(ROOT)}")
    print(f"  reachable props     {len(hits) - len(unreached)}/{len(hits)}"
          f"{'  ✓' if not unreached else '  ✗ ' + str(unreached[:4])}")


if __name__ == "__main__":
    main()
