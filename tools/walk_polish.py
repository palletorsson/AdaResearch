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
import json, math, argparse, pathlib, sys
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
    # MEASURED 2026-07-31, and the measurement disqualified two of them AS
    # COMPANIONS. step_base is 2.00 x 2.04 m and needs a 3x3 clearing; fence is
    # 4.42 m and needs five cells in a row. A companion stands BESIDE a body, so
    # its clearing always contains that body — these two can never satisfy the
    # rule they are named in, and the corpus confirms it: zero placements over
    # 40 maps. They are room-scale furniture, not body-scale. Kept, not deleted:
    # the preference is still the right answer, and if placement ever gains an
    # offset (stand the step in FRONT of the platform, not beside it) they
    # become placeable. Deleting them would hide that.
    "platform": "hangar_step_base",     # a staged body — a step to come up to it
    "monument": "hangar_barrier_fence",  # architecture — stand back from it
    "floor": None,                      # the ground itself: leave it clear
    "float": None,                      # hovering: furniture underneath is noise
    "pit": "hangar_barrier_fence",      # an edge — protect it
    "wall": None,                       # already against a surface
}
CORNER_CYCLE = ("hangar_supply_pile", "hangar_cabinet_cluster")


def is_furniture(tok):
    """The pass's own vocabulary. Furniture ANSWERS findings; it must never
    generate them. Left unguarded the pass furnishes its own furniture: after
    the standing gate was promoted it still wanted two things, and both were
    about props it had placed itself — a podium beside a supply pile, a beacon
    over a cabinet. That is not convergence, only deceleration. A prop is still
    something to LOOK at (it counts for the vista check); it is simply not a
    body that can be lonely or overlooked."""
    return tok.startswith("hangar_")

# THE BODY THE PASS WALKS AS. These were private numbers until the museum line
# wrote commons/data/museum_principles.json, whose Vitruvian block collects the
# constants the pipeline already measures — and cites capture_eye_stations.gd,
# this pass's own camera, as the source of two of them. Four tools each holding
# their own copy of the same body is how they drift, so the pass reads the table.
#
# The two models turn out to describe the same body. The canon carries a fixed
# PROMISE_M = 8 m (desire at distance); this pass asks whether a body fills
# MIN_DEG = 8 deg of the view, which is the same promise scaled by size —
# r* = 7.15 x size — and the two agree exactly at a 1.12 m body, the corpus's
# metre scale. gaze_ride states the law they share: viewing distance scales
# with size. Neither was derived from the other; keep both and note when they
# stop agreeing, because that disagreement would be a finding.
def body_constants():
    try:
        v = json.loads((ROOT / "commons/data/museum_principles.json")
                       .read_text(encoding="utf-8")).get("vitruvian", {})
        val = lambda k, d: float((v.get(k) or {}).get("value", d))
        return val("fov_deg", 90.0) / 2.0, val("eye_height_m", 1.65), val("promise_m", 8.0)
    except Exception:
        return 45.0, 1.65, 8.0


CONE, EYE_M, PROMISE_M = body_constants()   # half-angle of the forward view; eye; promise
MIN_DEG = 8.0        # smaller than this in the cone and the eye does not count it
VISTA = 5            # consecutive blank stations before the walk is dull


def measured_sizes():
    """Real body sizes from the probe floor — the same source gaze_ride trusts."""
    try:
        el = json.loads((ROOT / "commons/data/artifact_elements.json").read_text(encoding="utf-8"))
        out = {}
        for k, a in el.get("artifacts", {}).items():
            s = (a.get("union_aabb") or {}).get("size") or [1.0, 1.0, 1.0]
            out[k] = max(0.2, max(float(s[0]), float(s[2])))
        return out
    except Exception:
        return {}


def prop_extent(tok):
    """(width, depth) of a prop in metres, or None if it was never measured.

    Palle's ruling 2026-07-31, after looking at four furnished versions of the
    gate: probe the props and block unmeasured ones. The pass judged ARTIFACTS
    by their probed size all along — that is how the beacon check works — but
    had never measured the things it places itself, so it could not know a
    barrier fence is 4.4 m wide and was dropping it into a one-metre cell.
    """
    try:
        el = json.loads((ROOT / "commons/data/artifact_elements.json")
                        .read_text(encoding="utf-8")).get("artifacts", {})
    except Exception:
        return None
    a = el.get(tok)
    s = (a or {}).get("union_aabb", {}).get("size")
    if not s or len(s) < 3:
        return None
    return (max(0.2, float(s[0])), max(0.2, float(s[2])))


_EXTENTS = {}


def prop_cells(tok, rot=0):
    """How far a prop reaches from its own cell, in cells each side."""
    if tok not in _EXTENTS:
        _EXTENTS[tok] = prop_extent(tok)
    e = _EXTENTS[tok]
    if e is None:
        return None
    w, d = e
    if rot in (90, 270):
        w, d = d, w
    # A cell is 1 m and props sit centred in it. Demanding a whole extra cell
    # for a four-centimetre overhang is not the FIT law, it is arithmetic with
    # no eye: the first run of this rejected hangar_supply_pile (1.09 m deep)
    # everywhere. Anything up to a cell plus SLACK stands in one cell.
    SLACK = 0.2
    return (int(math.ceil(max(0.0, w - 1.0 - SLACK) / 2.0 - 1e-9)),
            int(math.ceil(max(0.0, d - 1.0 - SLACK) / 2.0 - 1e-9)))


def prop_fits(tok, cell, rot, ok):
    """FIT, for furniture. The law the rooms already obey, applied to what we
    put in them: a prop that overhangs its cell must have the cells it needs,
    or it does not go in. Unmeasured is never placed."""
    span = prop_cells(tok, rot)
    if span is None:
        return False
    ex, ez = span
    for dx in range(-ex, ex + 1):
        for dz in range(-ez, ez + 1):
            if (dx or dz) and not ok((cell[0] + dx, cell[1] + dz)):
                return False
    return True


def seen_from(cell, facing, bodies_xy, sizes, solid, limit=14):
    """Biggest angular size in the forward cone, and the wall the walk faces."""
    fx, fz = facing
    best_deg, blocked_at = 0.0, None
    for step in range(1, limit + 1):
        cx, cz = cell[0] + fx * step, cell[1] + fz * step
        if solid((cx, cz)):
            blocked_at = (cx, cz)
            limit = step                      # the wall ends the vista
            break
    for (bx, bz), tok in bodies_xy.items():
        dx, dz = bx - cell[0], bz - cell[1]
        dist = math.hypot(dx, dz)
        if dist < 0.5 or dist > limit: continue
        dot = (dx * fx + dz * fz) / dist
        if dot < math.cos(math.radians(CONE)): continue
        size = sizes.get(tok, 1.0)
        deg = math.degrees(2 * math.atan2(size / 2.0, dist))
        best_deg = max(best_deg, deg)
    return best_deg, blocked_at


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
    order, dist, parent = [], {spawn: 0}, {}
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
            parent[nb] = c
            dq.append(nb)
    # THE ROUTE: BFS order is a frontier, not a walk — a vista only means
    # something along a real path, so reconstruct spawn -> exit (or the
    # farthest station if the map has no teleporter landing).
    goal = None
    for z, row in enumerate(U):
        for x, cc in enumerate(row):
            if str(cc).strip().startswith("t"):
                for d in DIRS:
                    nb = (x + d[0], z + d[1])
                    if nb in dist and (goal is None or dist[nb] > dist.get(goal, -1)):
                        goal = nb
    if goal is None and dist:
        goal = max(dist, key=lambda k: dist[k])
    route = []
    cur = goal
    while cur is not None:
        route.append(cur)
        cur = parent.get(cur)
    route.reverse()
    return order, floor, dist, route


def inspect(md, name):
    """Stand on every station and note what the position lacks."""
    S, U, I, WL = grids(md)
    D = len(S); W = max((len(r) for r in S), default=0)
    stations, floor, dist, route = walk(md)
    occupied = {(x, z) for z, row in enumerate(I) for x, c in enumerate(row) if str(c).strip()}
    utils = {(x, z): str(c).strip() for z, row in enumerate(U)
             for x, c in enumerate(row) if str(c).strip()}
    lights = [c for c, t in utils.items() if t.startswith("el")]
    bodies = [(x, z) for z, row in enumerate(I) for x, c in enumerate(row)
              if str(c).strip() and not str(c).strip().startswith(PRE)
              and not is_furniture(str(c).strip().split(":")[0])]
    POSTURES = postures()

    def solid(c):                      # a wall face or the world's edge
        return h_at(S, *c) >= 4 or h_at(S, *c) < 0

    def free(c):
        return c in floor and c not in occupied and c not in utils

    SIZES = measured_sizes()
    bodies_xy = {(x, z): str(I[z][x]).strip().split(":")[0]
                 for z, row in enumerate(I) for x, c in enumerate(row)
                 if str(c).strip() and not str(c).strip().startswith(PRE)}
    nxt_of = {route[i]: route[i + 1] for i in range(len(route) - 1)}
    on_route = set(route)
    blank_run = {}

    def route_dir(c):
        """Which way the walk leaves this station — the eye's default heading."""
        n = nxt_of.get(c)
        return (n[0] - c[0], n[1] - c[1]) if n else None

    def back_off(c, facing, k):
        """Step back from what you are judging, so you can see it.

        The finding cell is where the PROP goes — flush against the wall, right
        beside the body. A camera there sees only the thing it is standing on:
        the first wall shots were a single grey plane edge to edge. An occupant
        reads a surface from across the room, so the eye backs up along its own
        heading while the floor allows it.
        """
        cur = c
        for _ in range(k):
            nb = (cur[0] - facing[0], cur[1] - facing[1])
            if nb not in floor or wall_between(WL, cur, nb):
                break
            cur = nb
        return cur

    props = []
    seen_wall_runs = set()
    for c in stations:
        x, z = c
        nbs = [(x + d[0], z + d[1]) for d in DIRS]

        # 1 DEAD CORNER — three sides closed, nothing in it, nothing to do
        closed = sum(1 for nb in nbs if solid(nb) or nb not in floor or wall_between(WL, c, nb))
        if closed >= 3 and free(c) and dist.get(c, 0) > 2:
            opens = [d for d in DIRS if (x + d[0], z + d[1]) in floor
                     and not wall_between(WL, c, (x + d[0], z + d[1]))]
            face = opens[0] if opens else (route_dir(c) or (0, 1))
            corner_pick = CORNER_CYCLE[len([q for q in props if q["kind"] == "corner"]) % 2]
            if not prop_fits(corner_pick, c, 0, free):
                corner_pick = next((w for w in CORNER_CYCLE + (REST,)
                                    if prop_fits(w, c, 0, free)), None)
            if corner_pick is None:
                continue                       # a dead corner too tight to fill
            props.append({"facing": list(face), "eye": list(back_off(c, face, 2)),
                          "cell": list(c), "why": "dead corner (3 sides closed, nothing in it)",
                          "place": corner_pick,
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
                wrot = {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}[d]
                # the panel runs ALONG the wall, so it needs the cells beside
                # it — a 2.4 m panel at the end of a run would hang off it
                if not prop_fits(SURFACE, c, wrot, free):
                    continue
                props.append({"facing": list(d), "eye": list(back_off(c, d, 3)),
                              "cell": list(c), "why": "bare wall (%d cells of blank surface)" % run,
                              "place": SURFACE, "layer": "interactables", "kind": "wall",
                              "rot": {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}[d]})

        # 3 DARK STRETCH — far from the map's OWN lighting idiom.
        #
        # This was `if lights and free(c)`, which reads as caution and is in
        # fact backwards: a map with no placed lights was judged perfectly lit,
        # because the guard skipped it entirely. Promoting the furnished gate
        # exposed it — Thread_Gate v6 had zero `el`, the pass placed the first
        # one, and the next run reported 22 dark stretches. Adding a light made
        # the map look worse, and the pass stopped converging on its own output.
        #
        # You cannot call a stretch dark RELATIVE TO A SCHEME that does not
        # exist. Below three lights there is no scheme to be far from, and the
        # map's legibility belongs to its environment, not to op 10.
        if len(lights) >= 3 and free(c):
            near = min(abs(c[0] - l[0]) + abs(c[1] - l[1]) for l in lights)
            if near >= 9 and dist.get(c, 0) % 5 == 0:
                props.append({"facing": list(route_dir(c) or (0, 1)),
                              "cell": list(c), "why": "dark stretch (%d cells from the nearest light)" % near,
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
                if want is None:
                    break                      # the honest answer is nothing
                # FIT, applied to furniture. The posture says what KIND of
                # companion the body wants; the room says which of them will
                # actually stand there. Preference order first, then whatever
                # fits — and if nothing fits, nothing goes in. A step_base is
                # 2.0 x 2.0 m and needs a 3x3 clearing; a podium needs its own
                # cell. Before the props were measured, all of them were
                # assumed to be cell-sized.
                cand = list(want) if isinstance(want, tuple) else [want]
                if len(cand) > 1:              # stable per artifact, varied per map
                    r = sum(ord(ch) for ch in tok) % len(cand)
                    cand = cand[r:] + cand[:r]
                cand += [w for w in (REST, CORNER) if w not in cand]
                # WHERE it stands, not only what it is. A companion was only
                # ever tried on the walker's own cell, unrotated — which is why
                # step_base and barrier_fence were dead vocabulary: at distance
                # 1 their clearing always contained the body they accompany.
                # Two things fix it. The prop FACES the body, so a long thin
                # thing (the 4.4 m fence) lays its length ACROSS the approach
                # and needs no depth at all; and a prop deeper than one cell
                # STEPS BACK along the approach until the body is clear. A step
                # base two cells out still touches the platform — its near edge
                # is a metre from the body's centre — it is adjacent in metres,
                # not in cells.
                bf = (b[0] - x, b[1] - z)
                rot = {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}[bf]
                want, at = None, None
                for w_tok in cand:
                    span = prop_cells(w_tok, rot)
                    if span is None:
                        continue
                    deep = span[0] if bf[1] == 0 else span[1]
                    for k in range(1, deep + 2):
                        cell = (b[0] - bf[0] * k, b[1] - bf[1] * k)
                        if not free(cell) or cell not in floor:
                            break              # the approach runs out
                        if not prop_fits(w_tok, cell, rot, free):
                            continue
                        ex, ez = span
                        if (abs(b[0] - cell[0]) <= ex and abs(b[1] - cell[1]) <= ez):
                            continue           # it would stand ON the body
                        want, at = w_tok, cell
                        break
                    if want:
                        break
                if want is None:
                    break                      # measured, and none of them fit
                props.append({"facing": list(bf), "eye": list(back_off(at, bf, 2)),
                              "cell": list(at), "rot": rot,
                              "why": "%s is a %s standing alone — wants %s" % (tok, pos, want.replace("hangar_", "")),
                              "place": want, "layer": "interactables", "kind": "rest",
                              "beside": tok, "posture": pos})
            break

    # 5 BLANK VISTA — walked as a WALK, in route order. (The first version
    # incremented its run counter inside the BFS loop, so consecutive steps
    # never formed a run and it reported nothing on ten maps: a walker's
    # question must be asked in walking order.)
    #
    # ONE FINDING PER STRETCH. The second version emitted every VISTA steps and
    # reset its counter, so a long dull walk became a finding every five paces —
    # 85 of them on Auto_Trans_Translation, 71 on Auto_Point_Lines, drowning
    # every other kind. A stretch of dullness is ONE thing wrong with the walk
    # however far it runs; its length belongs in the description, not in the
    # count. Emit when the run ENDS, not while it continues.
    def close_vista(start_i, length, facing, wall_at):
        if length < VISTA:
            return
        c = route[start_i]
        # two cures, and which one depends on whether the view ends on anything.
        # Facing a wall: give the wall a surface. Facing open space: put a light
        # IN the view, something to walk toward.
        if wall_at is not None and not str(I[wall_at[1]][wall_at[0]]).strip():
            rot = {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}[facing]
            props.append({"cell": list(c), "kind": "vista", "facing": list(facing),
                          "eye": list(back_off(c, facing, 3)),
                          "why": "blank vista — %d steps facing a wall, nothing over %d deg in view"
                                 % (length, int(MIN_DEG)),
                          "place": SURFACE, "layer": "interactables",
                          "rot": (rot + 180) % 360, "at_wall": list(wall_at)})
            return
        ahead = route[min(start_i + max(4, length // 2), len(route) - 1)]
        if (ahead in floor and not str(I[ahead[1]][ahead[0]]).strip()
                and not str(U[ahead[1]][ahead[0]]).strip()):
            # the LIGHT goes into the stretch; the EYE stays where the walker
            # first got bored, looking at what the light is meant to fix.
            props.append({"cell": list(ahead), "kind": "vista",
                          "eye": list(c), "facing": list(facing),
                          "why": "blank walk — %d open steps with nothing over %d deg in view"
                                 % (length, int(MIN_DEG)),
                          "place": LIGHT, "layer": "utilities"})

    run_len, run_facing, run_start, run_wall = 0, None, 0, None
    for i in range(len(route) - 1):
        c, nxt = route[i], route[i + 1]
        facing = (nxt[0] - c[0], nxt[1] - c[1])
        blank, wall_at = False, None
        if facing in DIRS:
            deg, wall_at = seen_from(c, facing, bodies_xy, SIZES, solid)
            if wall_at is not None and not (0 <= wall_at[1] < len(I)
                                            and 0 <= wall_at[0] < len(I[wall_at[1]])):
                wall_at = None
            blank = deg < MIN_DEG
        if blank and facing == run_facing:
            run_len += 1
            run_wall = wall_at or run_wall
            continue
        close_vista(run_start, run_len, run_facing, run_wall)
        if blank:
            run_len, run_facing, run_start, run_wall = 1, facing, i, wall_at
        else:
            run_len, run_facing, run_start, run_wall = 0, None, i, None
    close_vista(run_start, run_len, run_facing, run_wall)

    # 6 NEVER ANNOUNCED — a body you only ever meet by arriving at it.
    #
    # The first version of this check asked how big a body READS: angular size
    # over the width of its room, small-in-a-wide-room = lost. An eye shot
    # killed it before it shipped. Archetype_Cathedral's rack scored 0.24 —
    # among the worst in the corpus — and the picture showed it perfectly
    # legible: a small bright thing at the end of a long nave, dead on the
    # axis, the only colour in a grey corridor. Angular size is not presence.
    # Being ON THE WALK is presence, and the pass already knows how to ask
    # that: walk the route and see whether the body ever enters the cone.
    #
    # So the complaint is not "too small" — it is "never seen coming".
    announced = {}
    for i, c in enumerate(route[:-1]):
        nxt = route[i + 1]
        facing = (nxt[0] - c[0], nxt[1] - c[1])
        if facing not in DIRS:
            continue
        fx, fz = facing
        for (bx, bz), tok in bodies_xy.items():
            dx, dz = bx - c[0], bz - c[1]
            d = math.hypot(dx, dz)
            if d < 0.5 or d > 20:
                continue
            if (dx * fx + dz * fz) / d < math.cos(math.radians(CONE)):
                continue
            deg = math.degrees(2 * math.atan2(SIZES.get(tok, 1.0) / 2.0, d))
            if deg > announced.get((bx, bz), 0.0):
                announced[(bx, bz)] = deg
    for (bx, bz), tok in bodies_xy.items():
        if is_furniture(tok):
            continue                       # scenery is found up close, by design
        if announced.get((bx, bz), 0.0) >= MIN_DEG:
            continue                       # you saw it coming: nothing to fix
        # A detail beside a larger body is meant to be discovered up close.
        # Only the biggest thing in its neighbourhood can fail to announce.
        near_big = max((SIZES.get(t, 0.0) for (o, t) in bodies_xy.items()
                        if o != (bx, bz) and abs(o[0] - bx) <= 6 and abs(o[1] - bz) <= 6),
                       default=0.0)
        if SIZES.get(tok, 1.0) < near_big:
            continue
        if str(U[bz][bx]).strip():
            continue                       # already has something over it
        props.append({"cell": [bx, bz], "kind": "beacon", "facing": [0, 1],
                      "eye": list(back_off((bx, bz), (0, 1), 4)),
                      "why": "%s is never seen coming — it never fills %d deg of the walk's "
                             "view, you only meet it by arriving" % (tok, int(MIN_DEG)),
                      "place": LIGHT, "layer": "utilities"})

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
        elif p["kind"] == "vista":
            tgt = ("vista", tuple(p.get("at_wall") or p["cell"]))
        else:
            tgt = ("solo", k)
        cap = 1 if p["kind"] == "rest" else (3 if p["kind"] == "wall" else 2)
        if per_target.get(tgt, 0) >= cap: continue
        per_target[tgt] = per_target.get(tgt, 0) + 1
        seen_cells.add(k); out.append(p)
    return out, len(stations)


def apply(md, props, budget):
    S, U, I, WL = grids(md)
    D = len(S); W = max((len(r) for r in S), default=0)

    # Cells already spoken for by a placed prop's BODY, not just its cell. A
    # grid records one token per cell, so an overhang is invisible to the map
    # itself: the cabinet at (26,14) passed its own check, and the supply pile
    # then landed at (27,14), inside the cabinet. Claims make the footprint real
    # for as long as the pass is running.
    claimed = set()

    def ok(c):
        """A cell this prop may overhang into, judged on the grid AS IT IS NOW."""
        x, z = c
        if not (0 <= x < W and 0 <= z < D):
            return False
        if not (0 < h_at(S, x, z) <= 3):
            return False
        if c in claimed:
            return False
        return not str(I[z][x]).strip() and not str(U[z][x]).strip()

    def claim(tok, cell, rot):
        span = prop_cells(tok, rot)
        if span is None:
            return
        ex, ez = span
        for dx in range(-ex, ex + 1):
            for dz in range(-ez, ez + 1):
                claimed.add((cell[0] + dx, cell[1] + dz))

    placed = []
    for p in props[:budget]:
        # the last gate: a prop nobody measured never enters a map (`el` is a
        # utility token, not an artifact, and has no body to measure)
        if p["layer"] == "interactables" and prop_cells(p["place"]) is None:
            continue
        # FIT again, HERE. Proposals are judged against the map as it was found,
        # so two props proposed apart can still collide once both are placed —
        # the gate shipped a 1.82 m cabinet overhanging the cell where a supply
        # pile had just landed. Only apply() knows the grid as it actually is.
        if p["layer"] == "interactables" and not p.get("at_wall"):
            here = tuple(p["cell"])
            if here in claimed or not prop_fits(p["place"], here, p.get("rot", 0),
                                                lambda c: ok(c) or c == here):
                continue
            claim(p["place"], here, p.get("rot", 0))
        x, z = p["cell"]
        if p.get("kind") == "vista" and p.get("at_wall"):
            wx, wz = p["at_wall"]
            if str(I[wz][wx]).strip(): continue
            I[wz][wx] = p["place"] + ":%d" % p["rot"]
            placed.append(p)
            continue
        if p["layer"] == "utilities":
            # a claim is a claim whichever layer you are writing. Lights were
            # exempt, so an `el` could land in a cell a wall panel's body
            # already occupied — invisible in the data, a light inside a panel
            # in the world.
            if (x, z) in claimed: continue
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
    ap.add_argument("--shots", default="", help="write an eye-station file for "
                    "commons/testing/capture_eye_stations.gd (see it with your own eyes)")
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
    if a.shots:
        # EVERY FINDING IS A CAMERA STATION. The pass reasons about the view;
        # this hands the same positions to Godot so the view can be SEEN
        # (commons/testing/capture_eye_stations.gd stands at eye height there).
        # The station carries the FACING VECTOR, not a yaw. A yaw is only
        # meaningful inside one convention, and the grid's prop rotation and
        # Godot's camera yaw are not the same convention (they differ by 180
        # deg, and each mirrors x differently). Hand over the direction; let
        # the engine that owns the camera do its own trigonometry.
        S, U, I, WL = grids(md)
        stations = []
        for n, pr in enumerate(props):
            cx, cz = pr.get("eye") or pr["cell"]
            face = pr.get("facing")
            if not face and pr.get("at_wall"):
                dx, dz = pr["at_wall"][0] - cx, pr["at_wall"][1] - cz
                face = [0 if dx == 0 else (1 if dx > 0 else -1),
                        0 if dz == 0 else (1 if dz > 0 else -1)]
            stations.append({"cell": [cx, cz], "facing": [int(v) for v in (face or [0, 1])],
                             "y": max(0, h_at(S, cx, cz)),
                             "tag": "%02d_%s" % (n, pr["kind"]), "why": pr["why"]})
        pathlib.Path(a.shots).write_text(json.dumps(
            {"map": a.map, "stations": stations}, indent=1), encoding="utf-8")
        print("wrote %d eye stations -> %s" % (len(stations), a.shots))

    if not a.apply:
        print("\n(dry run — pass --apply to place the first %d)" % a.budget)
        return 0
    placed = apply(md, props, a.budget)
    (MAPS / a.map / "map_data.json").write_text(json.dumps(md), encoding="utf-8")
    print(f"\nplaced {len(placed)} props into {a.map}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
