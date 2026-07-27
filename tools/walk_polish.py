# -*- coding: utf-8 -*-
"""walk_polish.py — THE OCCUPANT PASS (Palle 2026-07-26: "as a last move when the
map is ready, walk around in the map, imagine the space and try to improve and
make it nice at every position").

Every other operation composes in PLAN: top-down, metric, the map as a shape.
This one composes in FIRST PERSON: it walks the finished map station by station
and asks the questions that only exist while standing somewhere —

    is there anything to look at from here?      (blank view)
    is this corner dead?                          (a cell you pass, never use)
    is that wall bare?                            (a long blank surface)
    can I see where I am?                         (dark stretch)
    is there anywhere to set something down?      (a body with no rest beside it)

and proposes ONE small local edit per finding, from props the project already
has. Structure is never touched: by this point the frame is decided, the walls
stand, the path is verified. Polish adds furniture, light and surface — the
Minecraft impulse to put a block where the space asks for one.

Seeing is delegated to the map itself (heights, walls, tokens); the sibling
tool tools/gaze_ride.py reads the same map as a gaze stream and is the better
instrument for angular size and view order.

  python tools/walk_polish.py <MapName>            # the punch list
  python tools/walk_polish.py <MapName> --apply    # place the safe proposals
  python tools/walk_polish.py <MapName> --apply --budget 12
"""
import json, argparse, pathlib, sys
from collections import deque

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons/maps"
PRE = ("cluster:", "mc:", "gridagent:", "criticalinfo:")

# props the pass may place — all map_ready, all already used by the project
REST = "hangar_podium"          # somewhere to set a thing down / stand a thing on
SURFACE = "hangar_wall_panel"   # a worked back for a bare wall
CORNER = "hangar_supply_pile"   # a dead corner becomes a stored corner
BENCH = "hangar_worktable"      # a body to work at
LIGHT = "el"                    # the cheapest legibility in the grid

# WHAT THE BODY WANTS BESIDE IT, by its staging posture (classify_postures).
# None means the honest answer is nothing: you do not put a crate on terrain you
# walk across, and you do not prop up a thing that floats.
POSTURE_WANTS = {
    "table": "hangar_worktable",        # an instrument — something to work at
    # PEDESTAL is half the corpus (1326 of 2660), so one answer here IS a new
    # uniform. A specimen's companion is chosen per ARTIFACT — stable (the same
    # body always gets the same neighbour) but varied across a map.
    "pedestal": ("hangar_cabinet_cluster", "hangar_podium", "hangar_step_base"),
    "platform": "hangar_step_base",     # a staged body — a step to come up to it
    "monument": "hangar_barrier_fence",  # architecture — stand back from it
    "floor": None,                      # the ground itself: leave it clear
    "float": None,                      # hovering: furniture underneath is noise
    "pit": "hangar_barrier_fence",      # an edge — protect it
    "wall": None,                       # already against a surface
}
CORNER_CYCLE = ("hangar_supply_pile", "hangar_cabinet_cluster")


def postures():
    """token -> posture, from the project's own classifier (measured floor)."""
    try:
        import importlib.util
        sp = importlib.util.spec_from_file_location(
            "classify_postures", ROOT / "tools" / "classify_postures.py")
        cp = importlib.util.module_from_spec(sp); sp.loader.exec_module(cp)
        reg, sizes, ovr = cp.load_registry(), cp.load_sizes(), cp.load_overrides()
        return {k: cp.classify(k, v, sizes.get(k, {}), ovr)[0] for k, v in reg.items()}
    except Exception:
        return {}

DIRS = {(1, 0): ("e", "w"), (-1, 0): ("w", "e"), (0, 1): ("s", "n"), (0, -1): ("n", "s")}


def load(name):
    p = MAPS / name / "map_data.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else None


def grids(md):
    L = md["layers"]
    return (L.get("structure") or [], L.get("utilities") or [],
            L.get("interactables") or [], L.get("walls") or [])


def h_at(S, x, z):
    if not (0 <= z < len(S) and 0 <= x < len(S[z])): return -1
    try: return int(float(str(S[z][x]).strip() or 0))
    except Exception: return -1


def wall_between(WL, a, b):
    d = (b[0] - a[0], b[1] - a[1])
    if d not in DIRS: return False
    ea, eb = DIRS[d]
    for (cx, cz), e in ((a, ea), (b, eb)):
        if cz < len(WL) and cx < len(WL[cz]) and e in (WL[cz][cx] or ""):
            return True
    return False


def walk(md):
    """The stations, in the order a body meets them (BFS from the spawn,
    respecting wall segments and the one-step climb rule)."""
    S, U, I, WL = grids(md)
    D = len(S); W = max((len(r) for r in S), default=0)
    spawn = None
    for z, row in enumerate(U):
        for x, c in enumerate(row):
            if str(c).strip() == "s": spawn = (x, z)
    floor = {(x, z) for z in range(D) for x in range(W) if 0 < h_at(S, x, z) <= 3}
    if spawn is None or spawn not in floor:
        spawn = min(floor) if floor else None
    if spawn is None: return [], floor, {}
    order, dist = [], {spawn: 0}
    dq = deque([spawn])
    while dq:
        c = dq.popleft(); order.append(c)
        for d in DIRS:
            nb = (c[0] + d[0], c[1] + d[1])
            if nb not in floor or nb in dist: continue
            if wall_between(WL, c, nb): continue
            if abs(h_at(S, *nb) - h_at(S, *c)) > 1:
                u = str(U[c[1]][c[0]]).strip() + str(U[nb[1]][nb[0]]).strip()
                if not (u.startswith("wp") or u.startswith("l") or "tc" in u):
                    continue
            dist[nb] = dist[c] + 1
            dq.append(nb)
    return order, floor, dist


def inspect(md, name):
    """Stand on every station and note what the position lacks."""
    S, U, I, WL = grids(md)
    D = len(S); W = max((len(r) for r in S), default=0)
    stations, floor, dist = walk(md)
    occupied = {(x, z) for z, row in enumerate(I) for x, c in enumerate(row) if str(c).strip()}
    utils = {(x, z): str(c).strip() for z, row in enumerate(U)
             for x, c in enumerate(row) if str(c).strip()}
    lights = [c for c, t in utils.items() if t.startswith("el")]
    bodies = [(x, z) for z, row in enumerate(I) for x, c in enumerate(row)
              if str(c).strip() and not str(c).strip().startswith(PRE)]
    POSTURES = postures()

    def solid(c):                      # a wall face or the world's edge
        return h_at(S, *c) >= 4 or h_at(S, *c) < 0

    def free(c):
        return c in floor and c not in occupied and c not in utils

    props = []
    seen_wall_runs = set()
    for c in stations:
        x, z = c
        nbs = [(x + d[0], z + d[1]) for d in DIRS]

        # 1 DEAD CORNER — three sides closed, nothing in it, nothing to do
        closed = sum(1 for nb in nbs if solid(nb) or nb not in floor or wall_between(WL, c, nb))
        if closed >= 3 and free(c) and dist.get(c, 0) > 2:
            props.append({"cell": list(c), "why": "dead corner (3 sides closed, nothing in it)",
                          "place": CORNER_CYCLE[len([q for q in props if q["kind"] == "corner"]) % 2],
                          "layer": "interactables", "kind": "corner"})
            continue

        # 2 BARE WALL — a run of >=4 wall cells with nothing standing against it
        for d, (ea, _eb) in DIRS.items():
            nb = (x + d[0], z + d[1])
            if not solid(nb): continue
            run, cur = 0, c
            perp = (d[1], d[0])
            while free(cur) and solid((cur[0] + d[0], cur[1] + d[1])):
                run += 1; cur = (cur[0] + perp[0], cur[1] + perp[1])
            if run >= 4:
                key = (nb, d)
                if key in seen_wall_runs: continue
                seen_wall_runs.add(key)
                props.append({"cell": list(c), "why": "bare wall (%d cells of blank surface)" % run,
                              "place": SURFACE, "layer": "interactables", "kind": "wall",
                              "rot": {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}[d]})

        # 3 DARK STRETCH — far from any light
        if lights and free(c):
            near = min(abs(c[0] - l[0]) + abs(c[1] - l[1]) for l in lights)
            if near >= 9 and dist.get(c, 0) % 5 == 0:
                props.append({"cell": list(c), "why": "dark stretch (%d cells from the nearest light)" % near,
                              "place": LIGHT, "layer": "utilities", "kind": "light"})

        # 4 NOTHING TO STAND AT — a body with no companion beside it. WHAT it
        # wants is decided by its posture, not by the parity of its coordinates.
        for b in bodies:
            if abs(b[0] - x) + abs(b[1] - z) != 1: continue
            around = [(b[0] + d[0], b[1] + d[1]) for d in DIRS]
            if any(a in occupied for a in around if a != c): continue
            if free(c) and dist.get(c, 0) > 1:
                tok = str(I[b[1]][b[0]]).strip().split(":")[0]
                pos = POSTURES.get(tok, "pedestal")
                want = POSTURE_WANTS.get(pos, REST)
                if isinstance(want, tuple):
                    want = want[sum(ord(ch) for ch in tok) % len(want)]
                if want is None:
                    break                      # the honest answer is nothing
                props.append({"cell": list(c),
                              "why": "%s is a %s standing alone — wants %s" % (tok, pos, want.replace("hangar_", "")),
                              "place": want, "layer": "interactables", "kind": "rest",
                              "beside": tok, "posture": pos})
            break

    # ONE proposal per TARGET, not per cell. The first version offered a bench
    # at every cell around a body and a panel at every cell along a wall — that
    # is a plan-thinker enumerating neighbours, not an occupant standing
    # somewhere. A body gets one rest, on the side you ARRIVE from (smallest
    # walk distance); a wall run gets one panel, and a second only if it is long.
    out, seen_cells = [], set()
    props.sort(key=lambda p: dist.get(tuple(p["cell"]), 10 ** 6))
    per_target = {}
    for p in props:
        k = tuple(p["cell"])
        if k in seen_cells: continue
        if p["kind"] == "rest":
            tgt = ("rest", p.get("beside"))
        elif p["kind"] == "wall":
            # panels must also be SPACED — four in a row is wallpaper, not
            # punctuation. Keep them >= 4 cells apart along the same face.
            c0 = tuple(p["cell"])
            if any(q["kind"] == "wall" and q.get("rot") == p.get("rot")
                   and max(abs(q["cell"][0] - c0[0]), abs(q["cell"][1] - c0[1])) < 4
                   for q in out):
                continue
            tgt = ("wall", p.get("rot"))
        else:
            tgt = ("solo", k)
        cap = 1 if p["kind"] == "rest" else (3 if p["kind"] == "wall" else 2)
        if per_target.get(tgt, 0) >= cap: continue
        per_target[tgt] = per_target.get(tgt, 0) + 1
        seen_cells.add(k); out.append(p)
    return out, len(stations)


def apply(md, props, budget):
    S, U, I, WL = grids(md)
    placed = []
    for p in props[:budget]:
        x, z = p["cell"]
        if p["layer"] == "utilities":
            if str(U[z][x]).strip(): continue
            U[z][x] = p["place"]
        else:
            if str(I[z][x]).strip(): continue
            I[z][x] = p["place"] + (":%d" % p["rot"] if "rot" in p else "")
        placed.append(p)
    return placed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("map")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--budget", type=int, default=14)
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    md = load(a.map)
    if not md:
        print("no such map:", a.map); return 1
    props, n = inspect(md, a.map)
    print(f"{a.map}: walked {n} stations -> {len(props)} positions want something")
    from collections import Counter
    print("  by kind:", dict(Counter(p["kind"] for p in props)))
    for p in props[:20]:
        print(f"  {str(p['cell']):10s} {p['kind']:6s} {p['place']:22s} {p['why']}")
    if not a.apply:
        print("\n(dry run — pass --apply to place the first %d)" % a.budget)
        return 0
    placed = apply(md, props, a.budget)
    (MAPS / a.map / "map_data.json").write_text(json.dumps(md), encoding="utf-8")
    print(f"\nplaced {len(placed)} props into {a.map}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
