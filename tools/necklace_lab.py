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
    bodies = []
    for z, row in enumerate(L.get("interactables", [])):
        for x, c in enumerate(row):
            cell = str(c).strip()
            if not cell or cell.startswith("#"):
                continue
            tok = cell.split("#")[0].split(":")[0]
            bodies.append({"token": tok, "gx": x, "gz": z, "plinth": (x, z) in plinths})
    return bodies, spawn


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


def relax(bodies, chain, hall, seed_pos, mesh=False, iters=260):
    pos = {i: [float(p[0]) + 0.5, float(p[1]) + 0.5] for i, p in seed_pos.items()}
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
    for _ in range(iters):
        force = {i: [0.0, 0.0] for i in ids}
        for a, b, rest, k in pairs:
            dx = pos[b][0] - pos[a][0]
            dz = pos[b][1] - pos[a][1]
            d = math.hypot(dx, dz) or 1e-6
            f = k * (d - rest) / d
            force[a][0] += f * dx
            force[a][1] += f * dz
            force[b][0] -= f * dx
            force[b][1] -= f * dz
        for ai in range(len(ids)):
            for bi in range(ai + 1, len(ids)):
                a, b = ids[ai], ids[bi]
                dx = pos[b][0] - pos[a][0]
                dz = pos[b][1] - pos[a][1]
                d = math.hypot(dx, dz) or 1e-6
                if d < 1.6:
                    f = 0.5 * (1.6 - d) / d
                    force[a][0] -= f * dx
                    force[a][1] -= f * dz
                    force[b][0] += f * dx
                    force[b][1] += f * dz
        for i in ids:
            pos[i][0] = min(max(pos[i][0] + 0.3 * force[i][0], 1.6), hall.w - 2.6)
            pos[i][1] = min(max(pos[i][1] + 0.3 * force[i][1], hall.vest + 1.6), hall.vest + hall.h - 2.6)
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


def score(bodies, chain, hall, sol):
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
    return {"placed": len(placed), "of": len(chain),
            "order": round(mono / max(1, len(placed) - 1), 3),
            "distortion": round(sum(dist_err) / len(dist_err), 2),
            "blocked": blocked, "min_sep": round(min_sep, 2)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hall", default="")
    args = ap.parse_args()
    report = read_json(REPO / "ada_run" / "em_pack_report.json")
    if not report:
        print("no em_pack_report.json — boot with grid_pack first (boot_pack_report.gd)")
        return 2
    floors = load_floor_index()
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
            sols["spring"] = relax(bodies, chain, hall, serp, mesh=False)
            sols["mesh"] = relax(bodies, chain, hall, serp, mesh=True)
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
                               "plinth": bodies[i]["plinth"]} for i in chain if i in sol],
                "score": score(bodies, chain, hall, sol)}
        out[key] = entry
        line = "  %-38s" % key
        for name in ("rigid", "serpentine", "spring", "mesh"):
            sc = entry["strategies"].get(name, {}).get("score")
            line += "  %s ord %.2f dist %.2f" % (name[:4], sc["order"], sc["distortion"]) if sc else "  %s —" % name[:4]
        print(line)
    (REPO / "ada_run" / "necklace_lab.json").write_text(
        json.dumps({"_readme": "the necklace bake-off: per hall, four placement strategies with scores. Written by tools/necklace_lab.py; read by /transplant.",
                    "halls": out}, indent=1), encoding="utf-8")
    print("-> ada_run/necklace_lab.json (%d halls)" % len(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
