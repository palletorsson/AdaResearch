#!/usr/bin/env python3
"""deck_dresser.py — THE BOUNDARY IS THE BUILDING.

Palle, looking at KitBash3D's Cyber District: "can we use wang tiles to make
these kind of platform structures from the grid?"

The observation that made this tool: in every one of those renders the deck
itself is FLAT. Nothing about the floorplan carries the look. What carries it is
what happens where the deck STOPS — the yellow-capped railing at the drop, the
stair run down to the lower plate, the pylons in the undercroft. All of it is a
function of the HEIGHT FIELD ALONE. So it needs no solver: one boundary scan
derives it.

This is gen_wanghall's sealing rule generalised from binary to graded. There:

    a cell gets a wall on a side  iff  the neighbour on that side is void.

Here the neighbour is not void-or-floor but a HEIGHT, and the rule forks by how
far it falls — which is exactly the pathfinder's own movement contract:

    fall of 0      shared deck        nothing
    fall of 1      a step down        nothing (a curb, not a cliff)
    fall of 2+     needs a transport  RAILING
    void / edge    the drop           RAILING
    climb up       needs a walkway    STAIR (wp), where connectivity demands

The railing appears at precisely the places the player cannot walk off — the
guard rail IS the traversal rule made visible. That is the whole trick, and it
is why this reads as architecture rather than as decoration.

Traversal repair is not cosmetic. Heights alone can strand a deck: climbing
requires a `wp` walkway on either cell, so a generator that invents a height
field without walkways invents an unwalkable map. The dresser closes that gap
greedily — it adds the FEWEST walkways that reconnect the plate, so stairs land
where the composition actually needs them instead of on every transition.

Writes a SIBLING map by default (nothing existing is clobbered), in the house
style of place_artifacts.py.

Usage:
  python tools/deck_dresser.py --map=Archetype_Stacks
  python tools/deck_dresser.py --map=Archetype_Stacks --out=Stacks_Dressed
  python tools/deck_dresser.py --map=X --in-place --railing-height=1.05
  python tools/deck_dresser.py --map=X --dry-run
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# n/e/s/w in (drow, dcol). row = z, col = x — the pathfinder's convention.
SIDES = {"n": (-1, 0), "s": (1, 0), "w": (0, -1), "e": (0, 1)}
OPPOSITE = {"n": "s", "s": "n", "w": "e", "e": "w"}

RAILING_HEIGHT = 1.05     # guard height, not wall height
RAILING_THICKNESS = 0.08
RAILING_COLOR = [0.85, 0.72, 0.18]   # the yellow cap


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def flag(name):
    return f"--{name}" in sys.argv


# ── the height field ─────────────────────────────────────────────────────────
def height_of(cell) -> int:
    """Structure token -> integer height. '' / ' ' / '0' = void.

    Tokens can carry suffixes (e.g. '2s' podium slot), so lead-digit wins.
    """
    s = str(cell).strip()
    if not s:
        return 0
    digits = ""
    for ch in s:
        if ch.isdigit():
            digits += ch
        else:
            break
    return int(digits) if digits else 0


def load_layers(map_name: str):
    path = ROOT / "commons" / "maps" / map_name / "map_data.json"
    if not path.exists():
        sys.exit(f"no such map: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    layers = data.get("layers")
    if not isinstance(layers, dict) or "structure" not in layers:
        sys.exit(f"{map_name}: no layers.structure")
    return data, layers, path


def grid_of(layers, key, rows, cols, fill=" "):
    g = layers.get(key)
    if not isinstance(g, list) or not g:
        return [[fill] * cols for _ in range(rows)]
    out = []
    for r in range(rows):
        row = g[r] if r < len(g) and isinstance(g[r], list) else []
        out.append([str(row[c]) if c < len(row) else fill for c in range(cols)])
    return out


# ── rule 1: the fall edges become railings ───────────────────────────────────
def derive_railings(H, rows, cols):
    """Every side of every deck cell where the player would FALL.

    Declared from the higher cell only, so each physical edge is written once
    (the component dedupes shared edges, but writing one side keeps the data
    honest about which deck owns the guard).
    """
    walls = [["" for _ in range(cols)] for _ in range(rows)]
    stats = {"void": 0, "cliff": 0, "border": 0}
    for r in range(rows):
        for c in range(cols):
            h = H[r][c]
            if h <= 0:
                continue                      # void owns no railing
            for side, (dr, dc) in SIDES.items():
                nr, nc = r + dr, c + dc
                if not (0 <= nr < rows and 0 <= nc < cols):
                    walls[r][c] += side       # the map edge is a drop
                    stats["border"] += 1
                    continue
                nh = H[nr][nc]
                if nh == 0:
                    walls[r][c] += side
                    stats["void"] += 1
                elif h - nh >= 2:
                    walls[r][c] += side       # 2+ drop: unwalkable, so guard it
                    stats["cliff"] += 1
    return walls, stats


# ── rule 2: stairs where connectivity demands ────────────────────────────────
def walkable_set(H, rows, cols):
    return {(r, c) for r in range(rows) for c in range(cols) if H[r][c] > 0}


def step_ok(H, a, b, wp):
    """The pathfinder's movement contract, one direction: a -> b."""
    ha, hb = H[a[0]][a[1]], H[b[0]][b[1]]
    if hb == ha:
        return True
    if hb < ha:
        return ha - hb == 1          # drop 1 fine; 2+ needs tc, not our job
    return a in wp or b in wp        # climbing needs a walkway on either cell


def reachable(H, walk, wp, roots):
    """Cells reachable FROM the roots — directed, exactly as the pathfinder
    walks it. Reachability is not symmetric here: a wp lets you climb 2 levels
    but the drop back needs a transport cube, so a one-way deck is a real
    (and reportable) condition, not a modelling error."""
    seen = set(r for r in roots if r in walk)
    stack = list(seen)
    while stack:
        p = stack.pop()
        for dr, dc in SIDES.values():
            q = (p[0] + dr, p[1] + dc)
            if q in walk and q not in seen and step_ok(H, p, q, wp):
                seen.add(q)
                stack.append(q)
    return seen


def repair_traversal(H, rows, cols, wp_existing, roots, max_stairs=40):
    """Add the FEWEST walkways that make the whole plate reachable from spawn.

    Greedy: each round place the one walkway that unlocks the most new cells,
    then recompute. Stairs land where the composition actually needs them
    rather than on every height change. Stops the moment a round buys nothing,
    so an honest failure reports instead of looping.
    """
    walk = walkable_set(H, rows, cols)
    wp = set(wp_existing)
    added = []
    seen = reachable(H, walk, wp, roots)
    before = len(walk) - len(seen)

    for _ in range(max_stairs):
        if len(seen) >= len(walk):
            break
        best = None
        for p in sorted(seen):
            for dr, dc in SIDES.values():
                q = (p[0] + dr, p[1] + dc)
                if q not in walk or q in seen:
                    continue
                hp, hq = H[p[0]][p[1]], H[q[0]][q[1]]
                if hq <= hp or hq - hp > 3:
                    continue          # only climbs need one; >3 reads as a cliff
                if p in wp:
                    continue                  # already has a walkway
                gain = len(reachable(H, walk, wp | {p}, roots)) - len(seen)
                key = (-gain, hq - hp, p)
                if gain > 0 and (best is None or key < best[0]):
                    best = (key, p)
        if best is None:
            break                     # remaining splits need tc / br, not wp
        wp.add(best[1])
        added.append(best[1])
        seen = reachable(H, walk, wp, roots)

    return added, before, len(walk) - len(seen)


# ── the guarantee: the pathfinder is the judge ───────────────────────────────
def _reach_sets(data):
    """(reached, walkable) as SETS, measured by the pathfinder's own graph."""
    sys.path.insert(0, str(ROOT / "tools"))
    import map_pathfinder as mp
    g = mp.MapGraph(data)
    start = getattr(g, "spawn", None)
    if start is None or start not in g.walkable:
        return set(), g.walkable
    seen, stack = {start}, [start]
    while stack:
        p = stack.pop()
        for q in g.neighbors(p):
            if q not in seen:
                seen.add(q)
                stack.append(q)
    return seen, g.walkable


def _reach(data):
    """Reachable-from-spawn count, measured by the pathfinder's own graph."""
    seen, walk = _reach_sets(data)
    return len(seen), len(walk)


# ── crossing the void ────────────────────────────────────────────────────────
MAX_SPAN = 7        # beyond this a crossing reads as a leap, not a bridge


def repair_void(data, layers, struct, utilities, H, rows, cols):
    """Span void gaps that no walkway can close — by BUILDING the crossing.

    The walkway pass only knows how to climb. Once the kit could put a moat
    between two decks — a causeway's void, an unbuilt block — whole regions went
    unreachable with no height change anywhere to repair.

    The first version closed those gaps with a `tc` transport cube. It worked,
    and it was wrong: the player crossed but the eye saw nothing cross. A
    transport cube is a link, not a bridge. So the span is now real floor —
    deck cells written into the STRUCTURE layer at the height of the side it
    leaves from, which is why this pass has to run before the railings are
    derived rather than after. A bridge that appears after the guard rails have
    been decided is a bridge with no guard rails.

    (`br` was the other candidate and is still wrong: bridge cells sit at height
    1, so stepping off one onto a deck is a climb, and every crossing would need
    walkways bolted on both ends.)

    Shortest spans first, so a crossing lands where the gap is narrowest —
    where a bridge would honestly be built.
    """
    def probe(st, u):
        return _reach_sets({**data, "layers": {**layers,
                                               "structure": st, "utilities": u}})

    placed = []
    reached, walk = probe(struct, utilities)
    for _ in range(24):
        if len(reached) >= len(walk):
            break
        cands = []
        for p in reached:
            r, c = p
            for dr, dc, axis in ((1, 0, "z"), (-1, 0, "z"),
                                 (0, 1, "x"), (0, -1, "x")):
                for d in range(2, MAX_SPAN + 1):
                    q = (r + dr * d, c + dc * d)
                    if not (0 <= q[0] < rows and 0 <= q[1] < cols):
                        break
                    mid = (r + dr * (d - 1), c + dc * (d - 1))
                    if H[mid[0]][mid[1]] != 0:
                        break            # the span must be void all the way
                    if q in walk and q not in reached:
                        cands.append((d, p, (dr, dc), axis))
                        break
        if not cands:
            break                        # nothing left that a span can reach
        best = None
        for d, p, (dr, dc), axis in sorted(cands, key=lambda t: (t[0], t[1])):
            r, c = p
            hb = H[r][c]                 # the deck carries its own height over
            if hb <= 0:
                continue
            st = [row[:] for row in struct]
            u = [row[:] for row in utilities]
            deck = [(r + dr * k, c + dc * k) for k in range(1, d)]
            q = (r + dr * d, c + dc * d)

            # WIDEN to two planks. The causeway's own deck is the two GATE
            # columns, so a one-wide span pinches at the joint where it meets
            # one. Prefer the side whose abutments are already deck at this
            # height — a wide bridge wants a wide landing, not just a wide
            # middle. If neither side is clear the span stays one wide rather
            # than carving new void.
            lane2, best_side = [], None
            for pdr, pdc in ((dc, dr), (-dc, -dr)):
                cells = [(br_ + pdr, bc_ + pdc) for br_, bc_ in deck]
                if any(not (0 <= rr < rows and 0 <= cc < cols) or H[rr][cc] != 0
                       for rr, cc in cells):
                    continue             # occupied or off-map: cannot widen here
                score = sum(1 for end in (p, q)
                            if 0 <= end[0] + pdr < rows and 0 <= end[1] + pdc < cols
                            and H[end[0] + pdr][end[1] + pdc] == hb)
                if best_side is None or score > best_side[0]:
                    best_side, lane2 = (score, (pdr, pdc)), cells

            for (br_, bc_) in deck + lane2:
                st[br_][bc_] = str(hb)
                u[br_][bc_] = " "        # the span is floor, nothing else

            # the far abutment: same height or a single step down needs nothing,
            # anything else needs a walkway on the last plank of each lane
            for lane, far in ((deck, q),
                              (lane2, (q[0] + best_side[1][0],
                                       q[1] + best_side[1][1]) if lane2 else None)):
                if not lane or far is None:
                    continue
                if not (0 <= far[0] < rows and 0 <= far[1] < cols):
                    continue
                hq = H[far[0]][far[1]]
                if hq > 0 and hq != hb and hb - hq != 1 \
                        and not u[lane[-1][0]][lane[-1][1]].strip():
                    u[lane[-1][0]][lane[-1][1]] = "wp"

            got, _ = probe(st, u)
            if len(got) > len(reached):
                best = (st, u, deck + lane2, hb, d, axis, got, 2 if lane2 else 1)
                break                    # shortest span that buys reach wins
        if best is None:
            break
        struct, utilities, deck, hb, d, axis, reached, wide = best
        for (br_, bc_) in deck:          # keep the height field in step
            H[br_][bc_] = hb
        placed.append((deck[0], f"deck h{hb} {d - 1}x{wide} {axis}"))
    return struct, utilities, placed, len(reached), len(walk)


def _drop_sealing_railings(data, layers, walls, utilities):
    """Remove the fewest railings that restore full reachability.

    Measured against the map as it stands WITHOUT railings — that is the
    ceiling the dressed map must not fall below. Greedy by cell: try dropping
    each railed cell's guard and keep the drop if it buys reach back.
    """
    probe = json.loads(json.dumps(data))
    probe["layers"] = dict(layers)
    probe["layers"]["utilities"] = utilities
    probe["layers"].pop("walls", None)
    target, _ = _reach(probe)

    probe["layers"]["walls"] = walls
    got, _ = _reach(probe)
    if got >= target:
        return walls, 0

    walls = [list(row) for row in walls]
    dropped = 0
    for r in range(len(walls)):
        for c in range(len(walls[r])):
            if got >= target:
                break
            if not walls[r][c]:
                continue
            keep = walls[r][c]
            walls[r][c] = ""
            probe["layers"]["walls"] = walls
            now, _ = _reach(probe)
            if now > got:
                got, dropped = now, dropped + 1
            else:
                walls[r][c] = keep       # that guard was innocent — put it back
    return walls, dropped


# ── write ────────────────────────────────────────────────────────────────────
def main():
    map_name = arg("map")
    if not map_name:
        sys.exit(__doc__)
    data, layers, src_path = load_layers(map_name)

    structure = layers["structure"]
    rows = len(structure)
    cols = max(len(r) for r in structure if isinstance(r, list))
    H = [[height_of(structure[r][c]) if c < len(structure[r]) else 0
          for c in range(cols)] for r in range(rows)]

    utilities = grid_of(layers, "utilities", rows, cols)
    prior_walls = grid_of(layers, "walls", rows, cols, fill="")
    had_walls = any(str(c).strip() for row in prior_walls for c in row)

    wp_existing = {(r, c) for r in range(rows) for c in range(cols)
                   if utilities[r][c].strip().split(":")[0] == "wp"}

    roots = [(r, c) for r in range(rows) for c in range(cols)
             if utilities[r][c].strip().split(":")[0] == "sp"]
    if not roots:   # no spawn declared — judge from the largest deck instead
        walk = walkable_set(H, rows, cols)
        roots = [max(walk, key=lambda p: (H[p[0]][p[1]], -p[0], -p[1]))] if walk else []

    added, before, after = repair_traversal(H, rows, cols, wp_existing, roots)

    for (r, c) in added:
        if not utilities[r][c].strip():
            utilities[r][c] = "wp"

    # climbs first, then the gaps no climb can close — BUILDING the crossings,
    # so the height field is FINAL before any guard rail is decided
    norm = [[str(structure[r][c]) if c < len(structure[r]) else "0"
             for c in range(cols)] for r in range(rows)]
    norm, utilities, spans, span_reach, span_walk = repair_void(
        data, layers, norm, utilities, H, rows, cols)
    if spans:
        layers["structure"] = norm

    # NOW the boundary scan — it reads the height field the bridges left behind,
    # so a new span is guarded like any other deck. Deriving railings before the
    # spans were built would have left every crossing with open sides.
    railings, stats = derive_railings(H, rows, cols)

    # merge railings onto any pre-existing interior walls (never clobber)
    merged = [["" for _ in range(cols)] for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            letters = str(prior_walls[r][c]).strip()
            for side in railings[r][c]:
                # do not downgrade an existing doorway/wall on that edge
                if side not in letters and OPPOSITE[side].upper() not in letters \
                        and side.upper() not in letters:
                    letters += side
            merged[r][c] = letters

    # ── the guarantee ────────────────────────────────────────────────────────
    # A railing is a WALL to the pathfinder, so a guard placed on the only way
    # out of a cell seals it. (It cost a whole map once: spawn sat in a corner
    # whose single exit got railed, and reachability went 134 -> 1.) Rather than
    # trust this file's re-reading of the movement rules, ask the pathfinder
    # itself: any railing that costs reachability is dropped. The look yields to
    # the walk, every time.
    merged, dropped = _drop_sealing_railings(data, layers, merged, utilities)

    seg_count = sum(len([ch for ch in cell if ch in SIDES]) for row in merged for cell in row)
    reach_now, walk_now = _reach({**data, "layers": {**layers, "walls": merged,
                                                    "utilities": utilities}})
    deck_cells = sum(1 for r in range(rows) for c in range(cols) if H[r][c] > 0)
    heights = sorted({H[r][c] for r in range(rows) for c in range(cols)})

    print(f"— deck_dresser: {map_name} ({rows}x{cols}) —")
    print(f"  heights present     {heights}")
    print(f"  deck cells          {deck_cells}")
    print(f"  railing edges       {seg_count}"
          f"  (void {stats['void']}, cliff2+ {stats['cliff']}, border {stats['border']})")
    print(f"  walkways existing   {len(wp_existing)}")
    print(f"  walkways added      {len(added)}  {added[:8]}{' …' if len(added) > 8 else ''}")
    print(f"  void spans added    {len(spans)}  "
          f"{[f'{p}{t}' for p, t in spans[:4]]}{' …' if len(spans) > 4 else ''}")
    print(f"  railings dropped    {dropped}  (would have sealed a cell)")
    print(f"  pathfinder reach    {reach_now}/{walk_now} walkable cells"
          f"{'  ✓' if reach_now >= walk_now else '  ✗'}")
    print(f"  spawn roots         {roots[:3]}{' …' if len(roots) > 3 else ''}")
    # the climb pass's own bookkeeping — a progress note, NOT the verdict. It
    # cannot see the spans placed after it, so it will happily report cells
    # stranded that the void pass went on to connect. The pathfinder line above
    # is the one that decides.
    print(f"  (climb pass alone   {before} -> {after} unreached"
          f"{', closed by spans' if after and reach_now >= walk_now else ''})")
    if had_walls:
        print("  ! map already had interior walls — merged, and railing height NOT")
        print("    applied (settings.wall_segments is global; it would shorten them)")

    if flag("dry-run"):
        return

    layers["walls"] = merged
    layers["utilities"] = utilities
    if not had_walls:
        settings = data.setdefault("settings", {})
        ws = settings.setdefault("wall_segments", {})
        ws["height"] = float(arg("railing-height", RAILING_HEIGHT))
        ws["thickness"] = float(arg("railing-thickness", RAILING_THICKNESS))
        ws.setdefault("color", RAILING_COLOR)

    if flag("in-place"):
        out_name, out_path = map_name, src_path
    else:
        out_name = arg("out", f"{map_name}_Dressed")
        out_path = ROOT / "commons" / "maps" / out_name / "map_data.json"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        info = data.setdefault("map_info", {})
        info["name"] = out_name
        info["dressed_from"] = map_name

    out_path.write_text(json.dumps(data, indent=1), encoding="utf-8")
    print(f"  wrote               {out_path.relative_to(ROOT)}")
    print(f"  check               python tools/map_pathfinder.py check {out_name} --verbose")


if __name__ == "__main__":
    main()
