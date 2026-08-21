#!/usr/bin/env python3
"""necklace_lab — the placement bake-off for the grid-to-museum transplant.

    python tools/necklace_lab.py            # solve + score every booted hall
    python tools/necklace_lab.py --hall="primitives|point"

Palle, 2026-08-21: "imagine we had all artifacts from the grid on a necklace
string, with some leeway, and we would place or lay that string inside the
halls." The rigid transplant preserved the constellation's global shape and
broke in narrow halls; the string keeps ORDER exactly and neighbor distances
approximately, and lets the global shape fold into the room.

Three solvers compete against the RIGID baseline (the ledger's own finals):

  serpentine  the string laid like text fills a page — boustrophedon rows,
              bead spacing = clamped grid distance. Deterministic, no physics.
  spring      the necklace relaxed: springs along the string (rest = grid
              distance), bead repulsion, wall containment. Verlet-ish, seeded
              by the serpentine, deterministic.
  mesh        the necklace generalized: extra springs between GRID neighbors
              (< 3.5 cells apart in the map), so pairs that faced each other
              across an aisle still do. Preserves neighborhoods, not just
              the chain.

Scored per hall on what the curation actually encoded: order preserved,
neighbor-distance distortion, blocked-cell violations, minimum separation.
Output: ada_run/necklace_lab.json — /transplant renders the contestants.

The string's order is the map's own walk: a nearest-neighbor chain from the
cell nearest the spawn (#sp), which is how the curated map is actually met.
"""
import argparse, json, math
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LEEWAY = (1.5, 4.0)   # a string gap breathes between these, whatever the grid said


def read_json(p):
    try:
        return json.loads(Path(p).read_text(encoding="utf-8"))
    except Exception:
        return None


def load_footprints():
    """(footprints, measures): token -> pearl cells (spatial_needs), and
    token -> [w_m, h_m, d_m, cells_w, cells_d] — the REAL measured body
    (measurements.aabb_size + grid_cells; 2720 tokens carry them). Registry
    files wrap their tokens under a top-level 'artifacts' key."""
    out = {}
    measures = {}
    for f in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        doc = read_json(f)
        if not isinstance(doc, dict):
            continue
        toks = doc.get("artifacts", doc)
        if not isinstance(toks, dict):
            continue
        for tok, e in toks.items():
            if not isinstance(e, dict):
                continue
            fc = (e.get("spatial_needs") or {}).get("footprint_cells")
            if fc:
                try:
                    out[str(tok)] = max(1, int(fc))
                except (TypeError, ValueError):
                    pass
            m = e.get("measurements") or {}
            ab = m.get("aabb_size")
            gc = m.get("grid_cells")
            if isinstance(ab, list) and len(ab) >= 3:
                cw = int(gc[0]) if isinstance(gc, list) and len(gc) >= 2 else max(1, round(float(ab[0])))
                cd = int(gc[1]) if isinstance(gc, list) and len(gc) >= 2 else max(1, round(float(ab[2])))
                measures[str(tok)] = [round(float(ab[0]), 2), round(float(ab[1]), 2),
                                      round(float(ab[2]), 2), max(1, cw), max(1, cd)]
    # the pearl DEFAULT trusts the measured body ("combine portals is very
    # large" — its spatial_needs said small): max of the declared footprint
    # and the measured cells, capped at 8 (the AABB-hog trap inflates a few)
    for tok, m in measures.items():
        out[tok] = min(8, max(out.get(tok, 1), int(m[3]), int(m[4])))
    return out, measures


def load_floor_index():
    floors = {}
    for name in ("em_built_desktop.json", "em_built.json"):
        doc = read_json(REPO / "ada_run" / name)
        if not doc:
            continue
        for seg in doc.get("segments", []):
            for key in ("%s|%s" % (seg.get("chapter", ""), seg.get("pearl", "")), seg.get("pearl", "")):
                if key not in floors:
                    floors[key] = seg
    return floors


def map_bodies(map_name):
    doc = read_json(REPO / "commons" / "maps" / map_name / "map_data.json")
    if not doc:
        return [], None
    L = doc.get("layers", {})
    structure = L.get("structure", [])
    plinths = set()
    for z, row in enumerate(structure):
        for x, c in enumerate(row):
            if str(c).strip() == "2":
                plinths.add((x, z))
    spawn = None
    for z, row in enumerate(L.get("utilities", [])):
        for x, c in enumerate(row):
            if str(c).strip().lstrip("#@").split(":")[0] == "sp":
                spawn = (x, z)
    raw = []
    for z, row in enumerate(L.get("interactables", [])):
        for x, c in enumerate(row):
            cell = str(c).strip()
            if not cell or cell.startswith("#"):
                continue
            tok = cell.split("#")[0].split(":")[0]
            raw.append({"token": tok, "gx": x, "gz": z, "plinth": (x, z) in plinths})
    # THE FOLD (Palle: "many the same did not work") — a straight, evenly
    # spaced run of identical artifacts is ONE bead: the grid's deliberate
    # ROW kept as a row, dragged as one, stamped later via the count lane.
    # Dissolving it into loose beads let the spring spread a composition
    # into mush.
    bodies = []
    used = set()
    by_tok = {}
    for i, b in enumerate(raw):
        by_tok.setdefault(b["token"], []).append(i)
    for tok, idxs in by_tok.items():
        for axis, other in (("gx", "gz"), ("gz", "gx")):
            lanes = {}
            for i in idxs:
                if i not in used:
                    lanes.setdefault(raw[i][other], []).append(i)
            for lane_is in lanes.values():
                if len(lane_is) < 2:
                    continue
                lane_is.sort(key=lambda i: raw[i][axis])
                run = [lane_is[0]]
                for i in lane_is[1:]:
                    gap = raw[i][axis] - raw[run[-1]][axis]
                    ref = (raw[run[1]][axis] - raw[run[0]][axis]) if len(run) > 1 else gap
                    if gap == ref:
                        run.append(i)
                    else:
                        if len(run) >= 2:
                            bodies.append(_fold_run(raw, run, axis))
                            used.update(run)
                        run = [i]
                if len(run) >= 2:
                    bodies.append(_fold_run(raw, run, axis))
                    used.update(run)
    for i, b in enumerate(raw):
        if i not in used:
            b["count"] = 1
            b["spread"] = ""
            b["gap"] = 1
            bodies.append(b)
    bodies.sort(key=lambda b: (b["gz"], b["gx"]))
    return bodies, spawn


def _fold_run(raw, run, axis):
    first = raw[run[0]]
    last = raw[run[-1]]
    gap = raw[run[1]][axis] - raw[run[0]][axis] if len(run) > 1 else 1
    return {"token": first["token"],
            "gx": (first["gx"] + last["gx"]) / 2.0, "gz": (first["gz"] + last["gz"]) / 2.0,
            "plinth": first["plinth"], "count": len(run),
            "spread": "x" if axis == "gx" else "z", "gap": gap}


def string_order(bodies, spawn):
    """Nearest-neighbor chain from the body nearest the spawn — the walk."""
    if not bodies:
        return []
    start = spawn or (0, 0)
    rest = list(range(len(bodies)))
    rest.sort(key=lambda i: (bodies[i]["gx"] - start[0]) ** 2 + (bodies[i]["gz"] - start[1]) ** 2)
    chain = [rest.pop(0)]
    while rest:
        last = bodies[chain[-1]]
        rest.sort(key=lambda i: (bodies[i]["gx"] - last["gx"]) ** 2 + (bodies[i]["gz"] - last["gz"]) ** 2)
        chain.append(rest.pop(0))
    return chain


def grid_dist(a, b):
    return math.hypot(a["gx"] - b["gx"], a["gz"] - b["gz"])


class Hall:
    def __init__(self, meta, floor):
        self.w = int(meta["w"])
        self.h = int(meta["h"])
        self.vest = int(meta.get("vestibule", 4))
        self.cells = floor.get("cells", []) if floor else []
        self.x0 = int(floor.get("cell_x0", 0)) if floor else 0

    def blocked(self, x, z):
        if x < 1 or x > self.w - 2 or z < self.vest + 1 or z > self.vest + self.h - 2:
            return True
        if 0 <= z < len(self.cells):
            col = int(x) - self.x0
            row = self.cells[int(z)]
            if 0 <= col < len(row):
                return row[col] in "#bpx"
        return False

    def nearest_free(self, x, z, taken):
        for r in range(0, 7):
            best = None
            for dx in range(-r, r + 1):
                for dz in range(-r, r + 1):
                    if max(abs(dx), abs(dz)) != r:
                        continue
                    cx, cz = int(x) + dx, int(z) + dz
                    if self.blocked(cx, cz) or (cx, cz) in taken:
                        continue
                    d = (cx - x) ** 2 + (cz - z) ** 2
                    if best is None or d < best[0]:
                        best = (d, cx, cz)
            if best:
                return best[1], best[2]
        return None


def serpentine_path(hall):
    """Boustrophedon over the interior, every 2nd row — an aisle between rows."""
    path = []
    flip = False
    for z in range(hall.vest + 2, hall.vest + hall.h - 2, 2):
        xs = range(2, hall.w - 2) if not flip else range(hall.w - 3, 1, -1)
        row = [(x, z) for x in xs if not hall.blocked(x, z)]
        path.extend(row)
        flip = not flip
    return path


def solve_serpentine(bodies, chain, hall):
    path = serpentine_path(hall)
    if not path:
        return None
    gaps = [0.0]
    for i in range(1, len(chain)):
        gaps.append(max(LEEWAY[0], min(LEEWAY[1], grid_dist(bodies[chain[i - 1]], bodies[chain[i]]))))
    total = sum(gaps)
    scale = min(1.0, (len(path) - 1) / max(total, 1e-6))
    out = {}
    taken = set()
    idx = 0.0
    prev_i = -1
    for k, ci in enumerate(chain):
        idx = idx + gaps[k] * scale
        i = max(prev_i + 1, int(round(idx)))
        while i < len(path) and path[i] in taken:
            i += 1
        if i >= len(path):
            i = len(path) - 1
            while i > 0 and path[i] in taken:
                i -= 1
        taken.add(path[i])
        prev_i = i
        out[ci] = path[i]
    return out


def bead_size(b, footprints):
    """One bead's effective diameter in cells: the registry footprint, or a
    folded run's extent along its axis."""
    fp = footprints.get(b["token"], 1)
    if b.get("count", 1) > 1:
        return max(fp, 1 + (b["count"] - 1) * b.get("gap", 1) * 0.6)
    return fp


def rect_half(b, footprints, measures):
    """Half-extents (hw, hd) in cells of the bead's REAL body — the measured
    w x d rectangle, run-extended along its spread axis."""
    m = measures.get(b["token"]) if measures else None
    cw = float(m[3]) if m else float(footprints.get(b["token"], 1))
    cd = float(m[4]) if m else float(footprints.get(b["token"], 1))
    hw, hd = cw / 2.0, cd / 2.0
    if b.get("count", 1) > 1:
        ext = ((b["count"] - 1) * b.get("gap", 1)) / 2.0
        if b.get("spread") == "x":
            hw += ext
        else:
            hd += ext
    return hw, hd


def relax(bodies, chain, hall, seed_pos, footprints=None, measures=None, mesh=False, iters=260):
    footprints = footprints or {}
    measures = measures or {}
    pos = {i: [float(p[0]) + 0.5, float(p[1]) + 0.5] for i, p in seed_pos.items()}
    halves = {i: rect_half(bodies[i], footprints, measures) for i in seed_pos}
    pairs = [(chain[k - 1], chain[k],
              max(LEEWAY[0], min(LEEWAY[1], grid_dist(bodies[chain[k - 1]], bodies[chain[k]]))), 0.35)
             for k in range(1, len(chain))]
    if mesh:
        for a in range(len(bodies)):
            for b in range(a + 1, len(bodies)):
                d = grid_dist(bodies[a], bodies[b])
                if 0.5 < d <= 3.5:
                    pairs.append((a, b, d, 0.12))
    ids = list(pos.keys())
    # THE KIN PULL (Palle: "cluster artifacts of the same type harder"):
    # scattered beads of the same token attract until their bodies nearly
    # touch — pull-only (the reluctance owns the inside), so kin gather
    # into groups without stacking.
    kin = []
    by_tok = {}
    for i in ids:
        by_tok.setdefault(bodies[i]["token"], []).append(i)
    for tok, members in by_tok.items():
        for a_i in range(len(members)):
            for b_i in range(a_i + 1, len(members)):
                a, b = members[a_i], members[b_i]
                kin.append((a, b, (halves[a][0] + halves[b][0]) + 0.8))

    def sweep(n):
        for _ in range(n):
            _relax_step(bodies, chain, hall, pos, halves, pairs, ids, footprints, kin)

    sweep(iters)
    # THE PIVOT (polymer physics' gift): when two string segments cross, the
    # spring cannot uncross them — gradients only push, never re-thread. A
    # 2-opt pivot can: reverse the POSITIONS of the sub-chain between the
    # crossing segments (bead ORDER is sacred and never changes; the beads
    # exchange places). Position-preserving, so nothing new collides — then
    # a short re-relax re-tensions gaps and re-separates unequal bodies.
    if _pivot_uncross(chain, pos) > 0:
        sweep(60)
        _pivot_uncross(chain, pos)   # a stubborn second knot, rarely
        sweep(30)
    out = {}
    taken = set()
    for i in chain:
        c = (int(pos[i][0]), int(pos[i][1]))
        if hall.blocked(*c) or c in taken:
            nf = hall.nearest_free(pos[i][0], pos[i][1], taken)
            if nf is None:
                continue
            c = nf
        taken.add(c)
        out[i] = c
    return out


def _relax_step(bodies, chain, hall, pos, halves, pairs, ids, footprints, kin=()):
    if True:
        force = {i: [0.0, 0.0] for i in ids}
        for a, b, rest in kin:
            dx = pos[b][0] - pos[a][0]
            dz = pos[b][1] - pos[a][1]
            d = math.hypot(dx, dz) or 1e-6
            if d > rest:
                f = min(0.10 * (d - rest), 0.6) / d
                force[a][0] += f * dx
                force[a][1] += f * dz
                force[b][0] -= f * dx
                force[b][1] -= f * dz
        for a, b, rest, k in pairs:
            dx = pos[b][0] - pos[a][0]
            dz = pos[b][1] - pos[a][1]
            d = math.hypot(dx, dz) or 1e-6
            f = k * (d - rest) / d
            force[a][0] += f * dx
            force[a][1] += f * dz
            force[b][0] -= f * dx
            force[b][1] -= f * dz
        # THE RELUCTANCE (Palle: "reluctant to place on the foot print of
        # another artifact — think separation"): the REAL measured rectangles
        # must not overlap. A rect overlap pushes hard along the axis of
        # least escape; the soft radius keeps polite spacing beyond contact.
        radii = {i: 0.5 * max(1.0, bead_size(bodies[i], footprints)) for i in ids}
        for ai in range(len(ids)):
            for bi in range(ai + 1, len(ids)):
                a, b = ids[ai], ids[bi]
                dx = pos[b][0] - pos[a][0]
                dz = pos[b][1] - pos[a][1]
                ox = halves[a][0] + halves[b][0] + 0.3 - abs(dx)
                oz = halves[a][1] + halves[b][1] + 0.3 - abs(dz)
                if ox > 0 and oz > 0:
                    if ox < oz:
                        push = 0.45 * ox * (1 if dx >= 0 else -1)
                        force[a][0] -= push
                        force[b][0] += push
                    else:
                        push = 0.45 * oz * (1 if dz >= 0 else -1)
                        force[a][1] -= push
                        force[b][1] += push
                d = math.hypot(dx, dz) or 1e-6
                sep = radii[a] + radii[b] + 0.6
                if d < sep:
                    f = 0.25 * (sep - d) / d
                    force[a][0] -= f * dx
                    force[a][1] -= f * dz
                    force[b][0] += f * dx
                    force[b][1] += f * dz
        # THE COMPOSITION LAW (Palle: "the bigger footprint in the middle and
        # 1x1s along the walls, mostly in the flow walk corridors"): a big
        # bead is drawn to the hall's centre axis like a sculpture in a nave;
        # a lone 1x1 drifts to the nearer wall and lines the corridor.
        # gently — the first tuning (0.05/0.06) overpowered the string:
        # distortion tripled and the chain crossed itself. The law shapes
        # the lateral drift; the necklace still owns the walk.
        mid = hall.w / 2.0
        for i in ids:
            size = bead_size(bodies[i], footprints)
            if size >= 2.0:
                force[i][0] += 0.022 * min(size - 1.0, 3.0) * (mid - pos[i][0])
            else:
                # HARDER to the walls (Palle: "push artifacts to the side of
                # the walls") — every small body hugs the nearer wall line
                wall_x = 1.8 if pos[i][0] < mid else hall.w - 2.8
                force[i][0] += 0.05 * (wall_x - pos[i][0])
        for i in ids:
            pos[i][0] = min(max(pos[i][0] + 0.3 * force[i][0], 1.6), hall.w - 2.6)
            pos[i][1] = min(max(pos[i][1] + 0.3 * force[i][1], hall.vest + 1.6), hall.vest + hall.h - 2.6)


def _pivot_uncross(chain, pos, max_passes=40):
    """2-opt on POSITIONS under fixed bead order: if string segments
    (s, s+1) and (t, t+1) cross, the beads between them reverse places.
    The position multiset is preserved, so separation survives; only the
    threading changes. Returns the number of pivots applied."""
    pivots = 0
    for _ in range(max_passes):
        found = False
        for s in range(len(chain) - 1):
            for t in range(s + 2, len(chain) - 1):
                if _segs_cross(pos[chain[s]], pos[chain[s + 1]], pos[chain[t]], pos[chain[t + 1]]):
                    seq = [list(pos[chain[m]]) for m in range(s + 1, t + 1)]
                    seq.reverse()
                    for off, m in enumerate(range(s + 1, t + 1)):
                        pos[chain[m]] = seq[off]
                    pivots += 1
                    found = True
                    break
            if found:
                break
        if not found:
            break
    return pivots


def _segs_cross(a, b, c, d):
    def orient(p, q, r):
        v = (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
        return 0 if abs(v) < 1e-9 else (1 if v > 0 else -1)
    o1, o2 = orient(a, b, c), orient(a, b, d)
    o3, o4 = orient(c, d, a), orient(c, d, b)
    return o1 != o2 and o3 != o4 and 0 not in (o1, o2, o3, o4)


def _los(hall, a, b):
    """Line of sight between two cells, walls occlude (space syntax's atom):
    sample the segment every half-cell; a blocked sample kills the ray."""
    d = math.hypot(b[0] - a[0], b[1] - a[1])
    steps = max(1, int(d * 2))
    for k in range(1, steps):
        t = k / steps
        x = a[0] + (b[0] - a[0]) * t
        z = a[1] + (b[1] - a[1]) * t
        if hall.blocked(int(x), int(z)):
            return False
    return True


def first_sight(chain, hall, sol, view=14.0):
    """Space syntax's question, asked of the string: standing at each bead in
    walk order, which bodies come into view for the first time — and does
    that first-sight order agree with the walk order? 1.0 = the museum
    reveals itself in the order it is walked."""
    placed = [i for i in chain if i in sol]
    if len(placed) < 3:
        return None
    fs = {}
    for k, standing in enumerate(placed):
        sp = sol[standing]
        for j in placed:
            if j in fs:
                continue
            if math.hypot(sol[j][0] - sp[0], sol[j][1] - sp[1]) > view:
                continue
            if _los(hall, sp, sol[j]):
                fs[j] = k
    seq = [fs.get(j, 10 ** 6) for j in placed]
    good = sum(1 for x, y in zip(seq, seq[1:]) if x <= y)
    return round(good / max(1, len(seq) - 1), 3)


def score(bodies, chain, hall, sol, footprints=None, measures=None):
    if not sol:
        return None
    placed = [(i, sol[i]) for i in chain if i in sol]
    if len(placed) < 2:
        return None
    mono = 0
    dist_err = []
    for k in range(1, len(placed)):
        (ia, ca), (ib, cb) = placed[k - 1], placed[k]
        if cb[1] >= ca[1] - 1:
            mono += 1
        want = max(LEEWAY[0], min(LEEWAY[1], grid_dist(bodies[ia], bodies[ib])))
        dist_err.append(abs(math.hypot(cb[0] - ca[0], cb[1] - ca[1]) - want))
    blocked = sum(1 for _, c in placed if hall.blocked(*c))
    min_sep = min((math.hypot(a[1][0] - b[1][0], a[1][1] - b[1][1])
                   for x_i, a in enumerate(placed) for b in placed[x_i + 1:]), default=99)
    # the reluctance, measured: pairs whose REAL rectangles overlap
    overlaps = 0
    if measures or footprints:
        hv = {i: rect_half(bodies[i], footprints or {}, measures or {}) for i, _ in placed}
        for x_i in range(len(placed)):
            for y_i in range(x_i + 1, len(placed)):
                (ia, ca), (ib, cb) = placed[x_i], placed[y_i]
                if abs(cb[0] - ca[0]) < hv[ia][0] + hv[ib][0] and abs(cb[1] - ca[1]) < hv[ia][1] + hv[ib][1]:
                    overlaps += 1
    return {"placed": len(placed), "of": len(chain),
            "order": round(mono / max(1, len(placed) - 1), 3),
            "distortion": round(sum(dist_err) / len(dist_err), 2),
            "blocked": blocked, "min_sep": round(min_sep, 2), "overlaps": overlaps,
            "sight": first_sight(chain, hall, sol)}


def _necklace_bbox(positions, measures, cap=4.5):
    """The necklace's true footprint (w, d) with per-body extents CAPPED at
    the registry's own 9-cell rule — an AABB hog (combine_portals' 87-cell
    reach) must not turn a hall into a courtyard by lying about its body."""
    xs0 = zs0 = 1e9
    xs1 = zs1 = -1e9
    for p in positions:
        m = measures.get(p["token"])
        hw = min(cap, (m[3] if m else p.get("fp", 1)) / 2.0)
        hd = min(cap, (m[4] if m else p.get("fp", 1)) / 2.0)
        if p.get("count", 1) > 1:
            ext = (p["count"] - 1) * p.get("gap", 1) / 2.0
            if p.get("spread") == "x":
                hw += ext
            else:
                hd += ext
        xs0 = min(xs0, p["x"] - hw)
        xs1 = max(xs1, p["x"] + hw)
        zs0 = min(zs0, p["z"] - hd)
        zs1 = max(zs1, p["z"] + hd)
    return (max(0.0, xs1 - xs0), max(0.0, zs1 - zs0))


def propose():
    """The occupancy + join proposer (Palle: "most necklace spaces were less
    than their hall — meaning they could share?" and the ruling: "if the size
    is bigger than hall space it is a courtyard").

    Verdicts, per hall:
      courtyard   the capped necklace exceeds the hall's interior in either
                  dimension — the composition wants open air, not clamping
      fits        it stands, and is a candidate for sharing
    Then a greedy pass over consecutive same-chapter pearls (spine order from
    the plan): strings whose depths stack within one interior with 3 cells of
    air become a JOIN proposal — the book's own `join: true` lane, decided by
    measurement instead of hand-feel. Proposals only; Palle enacts.
    Output: ada_run/necklace_proposals.json + the table below."""
    lab = read_json(REPO / "ada_run" / "necklace_lab.json") or {}
    rep = read_json(REPO / "ada_run" / "em_pack_report.json") or {}
    plan = read_json(REPO / "ada_run" / "em_plan.json") or {}
    measures = lab.get("measures", {})
    order = []
    for row in plan.get("plans", []):
        k = "%s|%s" % (row.get("sequence", ""), row.get("pearl", ""))
        if k in (lab.get("halls") or {}) and k not in [o[0] for o in order]:
            order.append((k, row.get("sequence", ""), int(row.get("pearl_index", 0))))
    order.sort(key=lambda o: (o[1], o[2]))
    verdicts = {}
    for k, chapter, _ in order:
        hall_meta = (rep.get("halls") or {}).get(k)
        strat = (lab["halls"][k].get("strategies") or {})
        sp = strat.get("hand") or strat.get("spring")
        if not hall_meta or not sp:
            continue
        nw, nd = _necklace_bbox(sp["positions"], measures)
        iw = int(hall_meta["w"]) - 2
        idp = int(hall_meta["h"]) - 2
        occ = (nw * nd) / max(1.0, iw * idp)
        court = nw > iw + 0.5 or nd > idp + 0.5
        verdicts[k] = {"chapter": chapter, "nw": round(nw, 1), "nd": round(nd, 1),
                       "iw": iw, "id": idp, "occupancy": round(occ, 2),
                       "verdict": "courtyard" if court else "fits",
                       "stamped": bool((read_json(REPO / "ada_run" / "necklace_hand.json") or {}).get("halls", {}).get(k, {}).get("stamp"))}
    joins = []
    i = 0
    keys = [k for k, _, _ in order if k in verdicts]
    while i < len(keys):
        k = keys[i]
        v = verdicts[k]
        group = [k]
        depth = v["nd"]
        if v["verdict"] == "fits":
            j = i + 1
            while j < len(keys) and len(group) < 3:
                k2 = keys[j]
                v2 = verdicts[k2]
                if v2["chapter"] != v["chapter"] or v2["verdict"] != "fits":
                    break
                if depth + v2["nd"] + 3.0 <= max(v["id"], v2["id"]) and v2["nw"] <= v["iw"]:
                    group.append(k2)
                    depth += v2["nd"] + 3.0
                    j += 1
                else:
                    break
        if len(group) > 1:
            joins.append(group)
            i += len(group)
        else:
            i += 1
    print("%-42s %-11s %12s %9s %s" % ("hall", "verdict", "necklace", "interior", "occupancy"))
    for k in keys:
        v = verdicts[k]
        print("%-42s %-11s %5.1f x %-5.1f %3d x %-3d %5.0f%%%s" % (
            k, v["verdict"].upper() if v["verdict"] == "courtyard" else v["verdict"],
            v["nw"], v["nd"], v["iw"], v["id"], v["occupancy"] * 100,
            "  · STAMPED" if v["stamped"] else ""))
    print()
    for g in joins:
        print("JOIN proposal: %s  (stacked depths fit one hall with air)" % "  +  ".join(g))
    courts = [k for k in keys if verdicts[k]["verdict"] == "courtyard"]
    (REPO / "ada_run" / "necklace_proposals.json").write_text(json.dumps({
        "_readme": "the proposer's verdicts: courtyard = the capped necklace exceeds the hall interior (Palle's ruling); joins = consecutive same-chapter pearls whose strings stack in one hall. Proposals only — enactment is the curator's.",
        "verdicts": verdicts, "joins": joins, "courtyards": courts}, indent=1), encoding="utf-8")
    print("\n%d hall(s): %d fit, %d courtyard, %d join proposal(s) -> ada_run/necklace_proposals.json" % (
        len(verdicts), len(verdicts) - len(courts), len(courts), len(joins)))
    return 0


def stamp_all():
    """Bless every hall's best necklace as its floor plan (Palle: "I do not
    see it inside the endless museum" — only stamped halls build the bench's
    layout; this stamps the lot so the museum shows the FINAL DISTRIBUTION
    everywhere). Merge discipline: a hall already in the hand file keeps its
    beads untouched and merely gains the stamp; missing halls are written
    from the lab's spring solution. Un-stamping any hall is one edit on the
    bench."""
    lab = read_json(REPO / "ada_run" / "necklace_lab.json") or {}
    hand_path = REPO / "ada_run" / "necklace_hand.json"
    hand = read_json(hand_path) or {"_readme": "hand-edited necklaces from /transplant's bench — the lab treats a hall's entry here as its truth", "halls": {}}
    stamped = created = kept = 0
    for key, v in (lab.get("halls") or {}).items():
        entry = hand["halls"].get(key)
        if entry and entry.get("beads"):
            if not entry.get("stamp"):
                entry["stamp"] = True
                stamped += 1
            else:
                kept += 1
            continue
        sp = (v.get("strategies") or {}).get("spring")
        if not sp or not sp.get("positions"):
            continue
        hand["halls"][key] = {"stamp": True, "at": "stamp_all",
            "beads": [{"token": p["token"], "x": p["x"] + 0.5, "z": p["z"] + 0.5,
                       "gx": p.get("gx", 0), "gz": p.get("gz", 0), "fp": p.get("fp", 1),
                       "count": p.get("count", 1), "spread": p.get("spread", ""),
                       "gap": p.get("gap", 1), "plinth": bool(p.get("plinth")),
                       "pinned": False, "added": False} for p in sp["positions"]]}
        created += 1
    hand_path.write_text(json.dumps(hand, indent=1) + "\n", encoding="utf-8")
    print("stamp-all: %d halls newly stamped from spring, %d hand halls stamped, %d already stamped — %d total in the hand file"
          % (created, stamped, kept, len(hand["halls"])))
    print("reload the museum (F6) — every hall now builds its necklace")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hall", default="")
    ap.add_argument("--propose", action="store_true")
    ap.add_argument("--stamp-all", action="store_true")
    args = ap.parse_args()
    if args.propose:
        return propose()
    if args.stamp_all:
        return stamp_all()
    report = read_json(REPO / "ada_run" / "em_pack_report.json")
    if not report:
        print("no em_pack_report.json — boot with grid_pack first (boot_pack_report.gd)")
        return 2
    floors = load_floor_index()
    footprints, measures = load_footprints()
    out = {}
    for key, meta in sorted(report.get("halls", {}).items()):
        if args.hall and key != args.hall:
            continue
        bodies, spawn = map_bodies(meta["map"])
        if not bodies:
            continue
        floor = floors.get(key) or floors.get(meta["pearl"])
        hall = Hall(meta, floor)
        chain = string_order(bodies, spawn)
        sols = {}
        serp = solve_serpentine(bodies, chain, hall)
        if serp:
            sols["serpentine"] = serp
            sols["spring"] = relax(bodies, chain, hall, serp, footprints=footprints, measures=measures, mesh=False)
            sols["mesh"] = relax(bodies, chain, hall, serp, footprints=footprints, measures=measures, mesh=True)
        # the rigid baseline: the ledger's own finals, scored on the same terms
        rigid = {}
        tok_seen = {}
        for i, b in enumerate(bodies):
            for lb in meta.get("bodies", []):
                if lb["token"] == b["token"] and lb.get("final") and id(lb) not in tok_seen:
                    rigid[i] = tuple(lb["final"])
                    tok_seen[id(lb)] = True
                    break
        if rigid:
            sols["rigid"] = rigid
        entry = {"chapter": meta["chapter"], "pearl": meta["pearl"], "map": meta["map"],
                 "chain": [bodies[i]["token"] for i in chain], "strategies": {}}
        for name, sol in sols.items():
            entry["strategies"][name] = {
                "positions": [{"token": bodies[i]["token"], "x": sol[i][0], "z": sol[i][1],
                               "gx": bodies[i]["gx"], "gz": bodies[i]["gz"],
                               "fp": footprints.get(bodies[i]["token"], 1),
                               "count": bodies[i].get("count", 1),
                               "spread": bodies[i].get("spread", ""),
                               "gap": bodies[i].get("gap", 1),
                               "plinth": bodies[i]["plinth"]} for i in chain if i in sol],
                "score": score(bodies, chain, hall, sol, footprints, measures)}
        # THE HAND (2026-08-21, Palle: "make it editable… add and remove
        # beads"): a hall with a saved hand necklace (ada_run/
        # necklace_hand.json, written by the /transplant bench) replaces the
        # derived spring with it verbatim — the bench's own live simulation
        # already relaxed it under the curator's fingers, and re-deriving
        # would undo their adds, removals and pins.
        hand_doc = read_json(REPO / "ada_run" / "necklace_hand.json") or {}
        hand = (hand_doc.get("halls", {}) or {}).get(key)
        if hand and hand.get("beads"):
            hb = hand["beads"]
            hsol = {k2: (float(b["x"]), float(b["z"])) for k2, b in enumerate(hb)}
            hbodies = [{"token": b["token"], "gx": b.get("gx", 0), "gz": b.get("gz", 0),
                        "plinth": bool(b.get("plinth"))} for b in hb]
            hchain = list(range(len(hb)))
            entry["strategies"]["hand"] = {
                "positions": [{"token": hb[k2]["token"], "x": hsol[k2][0], "z": hsol[k2][1],
                               "gx": hb[k2].get("gx", 0), "gz": hb[k2].get("gz", 0),
                               "plinth": bool(hb[k2].get("plinth")),
                               "pinned": bool(hb[k2].get("pinned")),
                               "stamp": bool(hb[k2].get("stamp")),
                               "added": bool(hb[k2].get("added"))} for k2 in hchain],
                "score": score(hbodies, hchain, hall, hsol, footprints, measures)}
        out[key] = entry
        line = "  %-38s" % key
        for name in ("rigid", "serpentine", "spring", "mesh"):
            sc = entry["strategies"].get(name, {}).get("score")
            line += "  %s ord %.2f dist %.2f" % (name[:4], sc["order"], sc["distortion"]) if sc else "  %s —" % name[:4]
        print(line)
    # a --hall run re-scores ONE hall; the others keep their rows (an
    # overwrite here would silently drop seven halls to update one)
    lab_path = REPO / "ada_run" / "necklace_lab.json"
    existing = (read_json(lab_path) or {}).get("halls", {})
    existing.update(out)
    lab_path.write_text(
        json.dumps({"_readme": "the necklace bake-off: per hall, placement strategies with scores. Written by tools/necklace_lab.py; read by /transplant.",
                    "footprints": footprints,
                    "measures": measures,
                    "halls": existing}, indent=1), encoding="utf-8")
    print("-> ada_run/necklace_lab.json (%d hall(s) refreshed, %d total)" % (len(out), len(existing)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
