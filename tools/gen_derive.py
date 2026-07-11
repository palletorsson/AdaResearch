#!/usr/bin/env python3
"""gen_derive.py — THE DERIVE BRICOLAGE strategy (Palle's principal).

Palle: "Derive bricolage - a wanderer walks, places the artifact out of her
backpack live along the walk, then goes forward, places the new artifact until
done, then goes back again to improve. Try to keep the map tight."

ONE wanderer. Two passes.

  BACKPACK   the mission in teaching order (beats + voltage inserted after their
             spread-out target beats) — the ordered list she carries.
  FORWARD    the derive: she walks 1 cell at a time carving a 3-wide floor, with
             heading momentum + seeded turn noise + a soft pull toward the canvas
             centroid so the walk CIRCLES COMPACTLY (the tight derive). After
             (6 + next footprint) steps she reaches into the backpack and lays a
             TIGHT PLATE beside her, perpendicular to heading; voltage pieces get
             a 1-cell-deep side alcove instead. She does this until the backpack
             is empty.
  RETURN     the bricolage: she retraces end -> start and IMPROVES —
               TIGHTEN   prune floor bulges (>=3 void neighbours, not the spine,
                         not a plate/alcove), to fixpoint, connectivity-verified.
               SHORTCUTS a couple of loops where the walk nearly touches itself.
               STAFF     same-domain benches on the big plates.

Only the FLOOR IDEA is invented here; map_principal.finish() turns it into a
complete Ada map (dimensions, palettes, proximity_lod, spawn/exit, wall runs,
wall props). mission_graph supplies the mission, the size oracle (resolve_cast),
the integration wrapper, and the supporting-cast staffer.

DETERMINISM: one random.Random(seed), consumed only by the walk, in a fixed
order. Same seed -> byte-identical map. Connectivity is guaranteed by
construction (every plate/alcove is carved flush against the corridor body) and
preserved by the tighten pass (a >=3-void cell has <=1 floor neighbour, so it is
a leaf whose removal cannot strand anything — flood-fill re-verified all the
same).

Usage:
  python tools/gen_derive.py --seq=randomness [--seed=7] [--name=MissionDerive_Randomness]
  python tools/gen_derive.py --seq=lsystems
"""
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import map_principal as mp        # THE finisher — must call mp.finish
import mission_graph as mg        # mission / size oracle / integration / staffing
import staging_beds as sb         # the bed a hero stands on

SEA = mg.SEA                      # "2" — the walkable floor height

# ── knobs (tuned for the tightness target: floor < 1600 cells) ───────────────
CANVAS = 56                       # working canvas; cropped honest before finish
BORDER = 2                        # hard-avoided canvas border (cells)
SAFE_LO = BORDER + 1              # centre stays in [SAFE_LO, SAFE_HI] so the
SAFE_HI = CANVAS - 2 - BORDER     #   3-wide body clears the 2-cell border
R_MAX = 14                        # the leash: orbit radius that keeps it compact
P_TURN = 0.15                     # P(a 90-degree turn / step) — the turn noise
P_DRIFT = 0.06                    # P(a strong drift turn straight to the centre)
GAP_BASE = 6                      # walk (GAP_BASE + footprint) steps between drops
RETRY_BACK = 3                    # both sides blocked -> retry in this many steps
COOLDOWN = 5                      # steps walked after the last drop (exit runway)
MAX_STEPS = 2000                  # safety cap on the forward walk
SHORTCUT_MIN_BACK = 18            # a shortcut joins points > this many steps apart
SHORTCUT_MAX_D = 3.0             # ...and within this Euclidean distance
SHORTCUT_MAX = 2                  # at most this many shortcut loops
CENTROID = (CANVAS // 2, CANVAS // 2)


# ── the footprint (plate seed), same oracle read as gen_ants ─────────────────

def _footprint(name):
    """honest footprint cells (min 2x2) from the size oracle."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells") or [2, 2]
    fw = max(2, int(round(float(gc[0]))))
    fh = max(2, int(round(float(gc[1]))))
    return fw, fh


# ── heading algebra ──────────────────────────────────────────────────────────

def _rot_left(h):
    return (-h[1], h[0])


def _rot_right(h):
    return (h[1], -h[0])


def _sign(x):
    return 1 if x > 0 else (-1 if x < 0 else 0)


def _toward_vec(r, c):
    return (CENTROID[0] - r, CENTROID[1] - c)


def _toward_cardinal(r, c, fallback):
    """the cardinal direction that most reduces distance to the centroid."""
    dr, dc = _toward_vec(r, c)
    if dr == 0 and dc == 0:
        return fallback
    if abs(dr) >= abs(dc):
        return (_sign(dr), 0)
    return (0, _sign(dc))


def _in_safe(r, c):
    return SAFE_LO <= r <= SAFE_HI and SAFE_LO <= c <= SAFE_HI


def _perp_dirs(h):
    """the two directions perpendicular to a cardinal heading."""
    if h[1] != 0:              # moving E/W -> perpendicular N/S
        return [(-1, 0), (1, 0)]
    return [(0, -1), (0, 1)]   # moving N/S -> perpendicular E/W


def _choose_heading(r, c, heading, rng):
    """momentum + seeded turn noise + soft centroid pull. Mostly straight; a
    90-degree turn biased toward the centre; occasionally a strong drift turn
    aimed straight at the centre. The ONLY consumer of rng."""
    roll = rng.random()
    if roll < P_TURN:
        left, right = _rot_left(heading), _rot_right(heading)
        tv = _toward_vec(r, c)
        gl = left[0] * tv[0] + left[1] * tv[1]
        gr = right[0] * tv[0] + right[1] * tv[1]
        if gl > gr:
            return left
        if gr > gl:
            return right
        return left if rng.random() < 0.5 else right   # tie -> seeded
    if roll < P_TURN + P_DRIFT:
        return _toward_cardinal(r, c, heading)          # the strong drift
    return heading                                       # straight


def _step(r, c, heading, rng):
    """advance one cell. Applies the leash (stay within R_MAX of the centre) and
    the hard border avoidance, both by turning inward — never with fresh rng, so
    determinism is the walk's turn rolls alone."""
    desired = _choose_heading(r, c, heading, rng)
    nr, nc = r + desired[0], c + desired[1]
    # the leash — do not wander past R_MAX; turn back toward the centre
    d_here = math.hypot(r - CENTROID[0], c - CENTROID[1])
    d_next = math.hypot(nr - CENTROID[0], nc - CENTROID[1])
    if d_next > R_MAX and d_next >= d_here:
        desired = _toward_cardinal(r, c, desired)
        nr, nc = r + desired[0], c + desired[1]
    # the border — never step into the 2-cell margin; try inward alternatives
    if not _in_safe(nr, nc):
        for h in (_toward_cardinal(r, c, desired), _rot_left(desired),
                  _rot_right(desired), (-desired[0], -desired[1]), heading):
            if _in_safe(r + h[0], c + h[1]):
                desired = h
                break
    return desired, (r + desired[0], c + desired[1])


# ── plate / alcove geometry ──────────────────────────────────────────────────

def _plate_rect(r, c, side, fw, fh):
    """a tight plate (footprint + 1-cell aisle all round) laid flush against the
    corridor body on the perpendicular `side`. Returns (x0, y0, pw, ph)."""
    pw, ph = fw + 2, fh + 2
    sr, sc = side
    if sr != 0:                         # N/S side -> stack vertically, centre on c
        x0 = c - pw // 2
        y0 = (r + 2) if sr > 0 else (r - 1 - ph)
    else:                               # E/W side -> lay horizontally, centre on r
        y0 = r - ph // 2
        x0 = (c + 2) if sc > 0 else (c - 1 - pw)
    return x0, y0, pw, ph


def _alcove_rect(r, c, side, fw):
    """a 1-cell-deep niche flush against the corridor body (the voltage pinch)."""
    wa = max(2, fw)
    sr, sc = side
    if sr != 0:                         # N/S side -> one row, wa columns
        x0 = c - wa // 2
        y0 = (r + 2) if sr > 0 else (r - 2)
        return x0, y0, wa, 1
    y0 = r - wa // 2                     # E/W side -> one column, wa rows
    x0 = (c + 2) if sc > 0 else (c - 2)
    return x0, y0, 1, wa


def _rect_ok(rect, placed, pad=1):
    """rect within the border and not overlapping any placed rect (with pad)."""
    x0, y0, w, h = rect
    x1, y1 = x0 + w - 1, y0 + h - 1
    if x0 < BORDER or y0 < BORDER or x1 > CANVAS - 1 - BORDER or y1 > CANVAS - 1 - BORDER:
        return False
    for (px0, py0, pw, ph) in placed:
        px1, py1 = px0 + pw - 1, py0 + ph - 1
        if not (x1 + pad < px0 or px1 + pad < x0 or y1 + pad < py0 or py1 + pad < y0):
            return False
    return True


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_derive: no beats in baseline for {seq}")
        return 1
    n = len(beats)

    # 1. THE BACKPACK — teaching order, voltage inserted after its spread-out
    # target beat (build_rooms' spreading rule), casts size-governed (fp<=6).
    entries = [{"kind": "beat", "i": i, "cast": b["cast"], "alts": b.get("alts", [])}
               for i, b in enumerate(beats)]
    for k, piece in enumerate(volt):
        t = round(k * (n - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n // 2
        for j, e in enumerate(entries):
            if e["kind"] == "beat" and e["i"] == t:
                entries.insert(j + 1, {"kind": "voltage", "i": k, "cast": piece,
                                       "alts": []})
                break
    swaps, backpack = [], []
    for e in entries:
        chosen, swapped = mg.resolve_cast(e["cast"], e["alts"], 6.0, 3.4)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        fw, fh = _footprint(chosen)
        backpack.append({"kind": e["kind"], "i": e["i"], "cast": chosen,
                         "fw": fw, "fh": fh, "fp": max(fw, fh)})

    rng = random.Random(seed)          # the ONLY randomness

    # 2. THE FORWARD PASS — the derive. Carve a 3-wide floor: at each step the
    # 3-cell cross-section perpendicular to the heading (exactly 3 wide on
    # straights). Consecutive trajectory centres are 4-adjacent and every strip
    # contains its centre, so the whole floor is 4-connected via the spine. Drop
    # from the backpack along the way.
    floor, plate_cells, alcove_cells = set(), set(), set()
    path_center = set()
    trajectory = []                    # (r, c, heading) per visited cell
    plates, alcoves, placed_rects = [], [], []

    def carve_strip(r, c, h):
        """the 3-wide cross-section perpendicular to heading h (exactly 3 wide on
        straights); the trajectory centre joins the connected spine, so all floor
        is 4-connected by construction."""
        floor.add((r, c))
        path_center.add((r, c))
        for dr, dc in _perp_dirs(h):
            floor.add((r + dr, c + dc))

    def carve_pad(r, c):
        """a full 3x3 pad — spawn breathing room / exit teleport landing (so the
        row under the teleport always carries floor: pathfinder Rule 2)."""
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                floor.add((r + dr, c + dc))

    def carve_plate(rect, into):
        x0, y0, w, h = rect
        for rr in range(y0, y0 + h):
            for cc in range(x0, x0 + w):
                floor.add((rr, cc))
                into.add((rr, cc))

    def try_place(item, r, c, heading, idx):
        """lay item beside (r, c). Alternate which perpendicular side is tried
        first (so plates spread both sides -> tighter). Returns True on success."""
        perps = _perp_dirs(heading)
        if idx % 2 == 1:
            perps = [perps[1], perps[0]]
        for side in perps:
            if item["kind"] == "voltage":
                rect = _alcove_rect(r, c, side, item["fw"])
                if _rect_ok(rect, placed_rects):
                    carve_plate(rect, alcove_cells)
                    placed_rects.append(rect)
                    x0, y0, w, h = rect
                    # centre cell of the niche (a row for N/S, a column for E/W)
                    cr = y0 if h == 1 else (y0 + (h - 1) // 2)
                    cc = x0 if w == 1 else (x0 + (w - 1) // 2)
                    alcoves.append({"cast": item["cast"], "cr": cr, "cc": cc,
                                    "rect": list(rect)})
                    return True
            else:
                rect = _plate_rect(r, c, side, item["fw"], item["fh"])
                if _rect_ok(rect, placed_rects):
                    carve_plate(rect, plate_cells)
                    placed_rects.append(rect)
                    x0, y0, pw, ph = rect
                    plates.append({"cast": item["cast"], "i": item["i"],
                                   "x0": x0, "y0": y0, "pw": pw, "ph": ph})
                    return True
        return False

    r, c = CANVAS // 2, CANVAS // 4     # near canvas centre-west
    heading = (0, 1)                    # facing the centroid to the east
    carve_strip(r, c, heading)
    carve_pad(r, c)                     # the spawn breathes
    trajectory.append((r, c, heading))
    idx = 0
    steps_since = 0
    gap = GAP_BASE + backpack[0]["fp"]
    total = 0
    while idx < len(backpack) and total < MAX_STEPS:
        heading, (r, c) = _step(r, c, heading, rng)
        carve_strip(r, c, heading)
        trajectory.append((r, c, heading))
        steps_since += 1
        total += 1
        if steps_since >= gap:
            if try_place(backpack[idx], r, c, heading, idx):
                idx += 1
                steps_since = 0
                if idx < len(backpack):
                    gap = GAP_BASE + backpack[idx]["fp"]
            else:
                steps_since = max(0, gap - RETRY_BACK)   # walk on, retry soon

    # fallback: if the walk hit the cap with items unplaced, scan the recorded
    # trajectory for any spot that takes them (keeps the pass complete + honest).
    if idx < len(backpack):
        for (tr, tc, th) in trajectory:
            while idx < len(backpack) and try_place(backpack[idx], tr, tc, th, idx):
                idx += 1
        if idx < len(backpack):
            print(f"gen_derive: could not place {len(backpack) - idx} item(s)")
            return 1

    # exit runway — a few steps past the last drop so the exit gets its own floor
    for _ in range(COOLDOWN):
        if total >= MAX_STEPS:
            break
        heading, (r, c) = _step(r, c, heading, rng)
        carve_strip(r, c, heading)
        trajectory.append((r, c, heading))
        total += 1

    spawn_rc = (trajectory[0][0], trajectory[0][1])
    exit_rc = (trajectory[-1][0], trajectory[-1][1])
    carve_pad(*exit_rc)                 # the exit gets its teleport landing

    # 3. THE RETURN PASS — the bricolage.
    # protect the spine, the plates, the alcoves, and the spawn/exit bodies (the
    # exit body keeps a landing row under the teleport for pathfinder Rule 2).
    protected = set(path_center) | plate_cells | alcove_cells
    for (er, ec) in (spawn_rc, exit_rc):
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if (er + dr, ec + dc) in floor:
                    protected.add((er + dr, ec + dc))

    # 3a. TIGHTEN — peel floor bulges to a fixpoint. A candidate has >=3 void
    # 4-neighbours (so <=1 floor neighbour: a leaf), is not protected, and its
    # removal is flood-verified not to strand the protected set.
    def four_void(cell, fset):
        r0, c0 = cell
        return sum(1 for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))
                   if (r0 + dr, c0 + dc) not in fset)

    def connected(fset):
        if spawn_rc not in fset:
            return False
        seen = {spawn_rc}
        stack = [spawn_rc]
        while stack:
            r0, c0 = stack.pop()
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nb = (r0 + dr, c0 + dc)
                if nb in fset and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
        return protected <= seen

    pruned = 0
    changed = True
    while changed:
        changed = False
        for cell in sorted(c for c in floor if c not in protected):
            if cell not in floor:
                continue
            if four_void(cell, floor) >= 3:
                floor.discard(cell)
                if connected(floor):
                    pruned += 1
                    changed = True
                else:
                    floor.add(cell)          # undo — it broke connectivity

    # 3b. SHORTCUTS — a couple of loops where the walk nearly touches itself.
    shortcuts = []
    pts = [(t[0], t[1]) for t in trajectory]
    last_i = -10 ** 9
    for i in range(len(pts) - 1, -1, -1):
        if len(shortcuts) >= SHORTCUT_MAX:
            break
        if i - last_i < 10:
            continue
        best = None
        for j in range(0, i - SHORTCUT_MIN_BACK):
            d = math.hypot(pts[i][0] - pts[j][0], pts[i][1] - pts[j][1])
            if d <= SHORTCUT_MAX_D and (best is None or d < best[0]):
                best = (d, j)
        if best is None:
            continue
        a, b = pts[i], pts[best[1]]
        for rr, cc in _carve_line2(a, b):
            floor.add((rr, cc))
        shortcuts.append({"from": [a[0], a[1]], "to": [b[0], b[1]]})
        last_i = i

    # 4. CROP to the used cells + 1-cell margin (dimensions honest).
    rows = [p[0] for p in floor]
    cols = [p[1] for p in floor]
    off_r, off_c = min(rows) - 1, min(cols) - 1
    H = (max(rows) - min(rows)) + 3
    W = (max(cols) - min(cols)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (rr, cc) in floor:
        st[rr - off_r][cc - off_c] = SEA

    def tr(rc):
        return rc[0] - off_r, rc[1] - off_c

    spawn_cell = tr(spawn_rc)
    exit_cell = tr(exit_rc)
    for p in plates:
        p["x0"] -= off_c
        p["y0"] -= off_r
    for al in alcoves:
        al["cr"] -= off_r
        al["cc"] -= off_c
        al["rect"][0] -= off_c
        al["rect"][1] -= off_r
    for sc in shortcuts:
        sc["from"] = [sc["from"][0] - off_r, sc["from"][1] - off_c]
        sc["to"] = [sc["to"][0] - off_r, sc["to"][1] - off_c]

    # 5. THE HEROES — each on its plate centre via the integration block (the
    # common wrapper, reused from mission_graph, exactly as gen_ants).
    integ_of = mg._integration()

    def place_hero(cast, cr, cc, north_row):
        integ, cfam = integ_of.get(cast, (None, None))
        if integ in ("self", "field"):
            layers["interactables"][cr][cc] = cast
        elif integ in ("cube", "wrap", "plinth", "frame"):
            fam = cfam if integ in ("cube", "wrap") else integ
            layers["interactables"][cr][cc] = f"sim_cube#family:{fam}#mount:{cast}"
        else:
            bed = sb.select_bed(cast)
            if bed["is_wall"]:
                layers["interactables"][north_row][cc] = f"{bed['bed']}:180#mount:{cast}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{cast}"

    for p in plates:
        cr = p["y0"] + p["ph"] // 2
        cc = p["x0"] + p["pw"] // 2
        place_hero(p["cast"], cr, cc, p["y0"] + 1)
    for al in alcoves:
        place_hero(al["cast"], al["cr"], al["cc"], al["cr"])

    # 6. spawn at the walk START, exit at the walk END. Reserve them before the
    # supporting cast so occupancy is respected (finish re-writes them anyway).
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 6b. STAFF — same-domain benches on the big beat plates (inner F >= 6).
    n_acts = (len([p for p in plates]) + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a >= n_acts - 1 else "work"

    slots = []
    for pi, p in enumerate(plates):
        F = min(p["pw"], p["ph"]) - 2
        if F >= 6:
            slots.append({"act": pi // 3, "kind": "beat", "cast": p["cast"],
                          "oy": p["y0"], "ox": p["x0"], "F": F})
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq),
                                       register_of)
    kept = []
    for s in staffed:
        r0, c0 = s["cell"]
        if layers["structure"][r0][c0] == SEA:
            kept.append(s)
        else:
            layers["interactables"][r0][c0] = " "     # never a bench on void
    staffed = kept

    # 7. WALLS — one boundary pass: a floor cell carries a side code iff the
    # neighbour on that side is void (the same edge contract as gen_wanghall).
    for rr in range(H):
        for cc in range(W):
            if st[rr][cc] != SEA:
                continue
            if rr - 1 < 0 or st[rr - 1][cc] != SEA:
                mp.wall(layers, rr, cc, "n")
            if cc + 1 >= W or st[rr][cc + 1] != SEA:
                mp.wall(layers, rr, cc, "e")
            if rr + 1 >= H or st[rr + 1][cc] != SEA:
                mp.wall(layers, rr, cc, "s")
            if cc - 1 < 0 or st[rr][cc - 1] != SEA:
                mp.wall(layers, rr, cc, "w")

    # 8. palette bands — three horizontal thirds (arrival / work / depth).
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # 9. mission metadata + the finisher contract (spawn/exit written by finish).
    mission = {"beats": n,
               "backpack": [{"cast": b["cast"], "kind": b["kind"]} for b in backpack],
               "path_steps": len(trajectory),
               "plates": [{"cast": p["cast"],
                           "rect": [p["x0"], p["y0"], p["pw"], p["ph"]]} for p in plates],
               "shortcuts": shortcuts,
               "pruned_cells": pruned,
               "seed": seed,
               "swaps": swaps,
               "supporting_cast": staffed}
    mp.finish(name, seq, "derive-bricolage", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # 10. the report.
    floor_n = len(floor)
    print(f"{name}: {n} beats + {len(volt)} voltage -> backpack {len(backpack)}, "
          f"{len(trajectory)} walk steps, {len(plates)} plates + {len(alcoves)} alcoves "
          f"-> {W}x{H} cells (canvas {CANVAS}, cropped)")
    print(f"  floor cells: {floor_n}  (tightness target < 1600)"
          f"{'  [OVER]' if floor_n >= 1600 else ''}")
    print(f"  tighten pruned {pruned} bulge cell(s); {len(shortcuts)} shortcut loop(s)")
    for p in plates:
        print(f"  plate <{p['cast']}>  rect=[x{p['x0']},y{p['y0']},w{p['pw']},h{p['ph']}]")
    for al in alcoves:
        print(f"  alcove <{al['cast']}>  at=({al['cr']},{al['cc']})")
    if swaps:
        print("  size-governed swaps:", ", ".join(swaps))
    if staffed:
        print("  supporting cast:", ", ".join(
            f"{s['name']} (beside {s['beside']})" for s in staffed))
    print(f"view: /map-viewer?map={name}")
    return 0


def _carve_line2(a, b):
    """cells of a 2-wide L-path from a to b (row leg then column leg)."""
    cells = set()

    def brush(r, c):
        for dr in (0, 1):
            for dc in (0, 1):
                cells.add((r + dr, c + dc))

    r, c = a
    brush(r, c)
    while r != b[0]:
        r += 1 if b[0] > r else -1
        brush(r, c)
    while c != b[1]:
        c += 1 if b[1] > c else -1
        brush(r, c)
    return cells


def main():
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    seq = arg("seq", None)
    if not seq:
        print(__doc__)
        return 1
    # the rule box: --set KNOB=value overrides a module constant
    # (pearl_factory.py — the additional parameters we can change)
    for a in sys.argv:
        if a.startswith("--set="):
            k, _, v = a[6:].partition("=")
            if k in globals() and not k.startswith("_"):
                globals()[k] = type(globals()[k])(v)
                print(f"knob {k} = {globals()[k]}")
    seed = int(arg("seed", "7"))
    name = arg("name", f"MissionDerive_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
