"""walker_carve.py — a map dug by swarms of random walkers with artifact gravity.

2026-08-29, Palle: "Let swarms of random walkers walk on and around the artifact
with artifact gravity and then build the wall around that?"

The flood's sibling, with a different temperament. flood_carve is water draining
THROUGH: one direction, braided channels, dunes where it never went. This is a
crowd wandering TOWARD: walkers leave the spawn edge, each drawn to an artifact
by gravity, orbiting it when they arrive ("walk on and around"), then retargeting
another and wandering on. Dwell halos bloom into plazas around every piece, the
connecting drifts thicken into paths - and the WALL is built around the visited
cloud afterwards: every unvisited cell touching a visited one becomes wall, and
beyond the wall there is simply nothing. The building's outline is the crowd's
outline. Footfall as architecture.

  python tools/walker_carve.py --in req.json
  req: { "tokens": [...], "width": 26, "depth": 34, "seed": 3,
         "walkers": 0 (auto), "layers": {...}? }
  (same contract as flood_carve: layers given + tokens absent -> the draft's own
   artifacts at their positions are the gravity wells)

Output: { ok, layers, stats: { visited_pct, wall_pct, connected,
  islands_reachable } }. Every walker STARTS at the spawn edge, so the visited
  cloud is connected to the entrance by construction - and then verified by BFS
  anyway, because carried claims rot.
"""
from __future__ import annotations
import json
import random
import sys
import os
import math
import heapq
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from flood_carve import footprint_side, scatter  # noqa: E402
from place_layers import artifact_any  # noqa: E402


def walk(width: int, depth: int, islands: list, hard: set, seed: int,
         walkers: int) -> tuple[list[list[float]], tuple[int, int]]:
    """The swarm. Returns the dwell field and the spawn cell."""
    rng = random.Random(seed)
    centers = [(r + side / 2.0, c + side / 2.0, side) for _t, r, c, side in islands]
    field = [[0.0] * width for _ in range(depth)]
    spawn_c = width // 2
    spawn = (depth - 1, spawn_c)

    steps_each = width * depth // 2
    for _ in range(walkers):
        r, c = float(depth - 1), float(spawn_c + rng.randrange(-width // 4, width // 4 + 1))
        c = max(0.0, min(float(width - 1), c))
        target = rng.randrange(len(centers)) if centers else -1
        vr, vc = -0.6, 0.0                      # entering the building
        for _ in range(steps_each):
            ir, ic = int(r), int(c)
            if 0 <= ir < depth and 0 <= ic < width:
                field[ir][ic] += 1.0
            # ARTIFACT GRAVITY: pulled toward the current target, gently toward
            # all the rest - a crowd drifts to what it came for but feels the
            # whole room
            gr = gc = 0.0
            for i, (tr, tc, _side) in enumerate(centers):
                dr, dc = tr - r, tc - c
                d2 = dr * dr + dc * dc + 1.0
                w = (2.6 if i == target else 0.25) / d2
                gr += dr * w * math.sqrt(d2)
                gc += dc * w * math.sqrt(d2)
            n = math.hypot(gr, gc) or 1.0
            gr, gc = gr / n, gc / n
            # momentum + noise: nobody walks a museum in straight lines
            vr = 0.55 * vr + 0.7 * gr + rng.uniform(-0.9, 0.9)
            vc = 0.55 * vc + 0.7 * gc + rng.uniform(-0.9, 0.9)
            vn = math.hypot(vr, vc) or 1.0
            nr, nc = r + vr / vn, c + vc / vn
            # footprints are solid: the walker slides around, which is what
            # digs the orbit halo ("walk on and around")
            if (int(nr), int(nc)) in hard:
                if (int(r), int(nc)) not in hard:
                    nr = r
                elif (int(nr), int(c)) not in hard:
                    nc = c
                else:
                    vr, vc = -vc, vr            # deflect, keep moving
                    continue
            r = max(0.0, min(float(depth - 1), nr))
            c = max(0.0, min(float(width - 1), nc))
            # ARRIVED: orbit done by proximity dwell; retarget so the trails
            # CONNECT the collection instead of star-bursting from the door
            if target >= 0:
                tr, tc, side = centers[target]
                if math.hypot(tr - r, tc - c) < side + 1.5 and rng.random() < 0.06:
                    target = rng.randrange(len(centers))
    return field, spawn


def main() -> int:
    in_path = None
    for a in sys.argv[1:]:
        if a.startswith("--in="):
            in_path = a.split("=", 1)[1]
    if not in_path:
        print(__doc__)
        return 2
    req = json.load(open(in_path, encoding="utf-8"))
    width = int(req.get("width") or 26)
    depth = int(req.get("depth") or 34)
    seed = int(req.get("seed") or 0)
    rng = random.Random(seed)

    tokens = req.get("tokens") or []
    layers_in = req.get("layers") or {}
    islands = []
    if not tokens and layers_in:
        inter = layers_in.get("interactables") or []
        depth = len(layers_in.get("structure") or []) or depth
        width = len((layers_in.get("structure") or [[]])[0]) or width
        for r, row in enumerate(inter):
            for c, cell in enumerate(row):
                cell = str(cell).strip()
                if cell and cell != "0":
                    tok = cell.split(":")[0].split("#")[0]
                    a = artifact_any(tok)
                    islands.append((tok, r, c, footprint_side(a.footprint_cells if a else 1)))
    else:
        islands = scatter(tokens, width, depth, rng)
    skipped = [t for t in tokens if t not in [i[0] for i in islands]] if tokens else []

    hard: set[tuple[int, int]] = set()
    for _tok, r, c, side in islands:
        for dr in range(side):
            for dc in range(side):
                if 0 <= r + dr < depth and 0 <= c + dc < width:
                    hard.add((r + dr, c + dc))

    walkers = int(req.get("walkers") or 0) or max(60, width * depth // 8)
    field, spawn = walk(width, depth, islands, hard, seed, walkers)

    peak = max((max(row) for row in field), default=1.0) or 1.0
    # THE CLOUD: everywhere enough feet fell becomes flat floor; the footprint
    # cells join the cloud as raised plinths ("2") so every island is inside
    # its hall, presented at h2, approached from the floor beside it
    visited = [[False] * width for _ in range(depth)]
    structure = [["0"] * width for _ in range(depth)]
    for r in range(depth):
        for c in range(width):
            u = field[r][c] / peak
            # ONE height for all trodden ground: the engine lets you step DOWN
            # but climbing needs a ramp, so a raised "shoulder" band would be
            # an unclimbable terrace (Flood_Delta ships that: 471/884 cells
            # reachable). The crowd tramples its world flat.
            if u > 0.008:
                structure[r][c] = "1"
                visited[r][c] = True
    for _tok, r, c, side in islands:
        for dr in range(side):
            for dc in range(side):
                if 0 <= r + dr < depth and 0 <= c + dc < width:
                    structure[r + dr][c + dc] = "2"
                    visited[r + dr][c + dc] = True
    # the orbit ring: gravity made the ground AROUND each piece the most
    # trodden of all, so it is floor by right - and forcing it keeps every
    # plinth approachable (h2 is entered by standing BESIDE it, never on it)
    for _tok, r, c, side in islands:
        for dr in range(-1, side + 1):
            for dc in range(-1, side + 1):
                rr, cc = r + dr, c + dc
                if 0 <= rr < depth and 0 <= cc < width and (rr, cc) not in hard:
                    structure[rr][cc] = "1"
                    visited[rr][cc] = True

    utilities = [[""] * width for _ in range(depth)]
    interactables = [[""] * width for _ in range(depth)]
    for tok, r, c, _side in islands:
        interactables[r][c] = f"{tok}:0:1"
    sr, sc = spawn
    if structure[sr][sc] not in ("1", "2"):
        structure[sr][sc] = "1"
        visited[sr][sc] = True
    utilities[sr][sc] = "s"

    def bfs_from_spawn() -> set:
        seen = {spawn}
        q = deque([spawn])
        while q:
            r, c = q.popleft()
            for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (r + dr, c + dc)
                if n not in seen and 0 <= n[0] < depth and 0 <= n[1] < width \
                        and structure[n[0]][n[1]] == "1":
                    seen.add(n)
                    q.append(n)
        return seen

    def moat(r0: int, c0: int, side: int) -> list:
        ring = []
        for dr in range(-1, side + 1):
            for dc in range(-1, side + 1):
                cell = (r0 + dr, c0 + dc)
                if cell not in hard and 0 <= cell[0] < depth and 0 <= cell[1] < width:
                    ring.append(cell)
        return ring

    # THE GUARANTEE, walker-flavoured: where flood forces one keeper path, the
    # swarm repairs by promoting the HIGHEST-DWELL corridor from the door cloud
    # to any island the banding stranded - the trail the most feet made, just
    # under the threshold. Small maps + few walkers band-break otherwise
    # (measured: 20x24, 3 islands, 60 walkers -> 0 reachable before repair).
    seen = bfs_from_spawn()
    for _tok, ir, ic, iside in islands:
        ring = moat(ir, ic, iside)
        if any(cell in seen for cell in ring):
            continue
        best = {cell: 0.0 for cell in seen}
        prev = {}
        pq = [(0.0, cell) for cell in seen]
        heapq.heapify(pq)
        goal = None
        while pq:
            cost, (r, c) = heapq.heappop(pq)
            if cost > best.get((r, c), float("inf")):
                continue
            if (r, c) in ring:
                goal = (r, c)
                break
            for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (r + dr, c + dc)
                if not (0 <= n[0] < depth and 0 <= n[1] < width) or n in hard:
                    continue
                nc_ = cost + 1.05 - min(1.0, field[n[0]][n[1]] / peak)
                if nc_ < best.get(n, float("inf")):
                    best[n] = nc_
                    prev[n] = (r, c)
                    heapq.heappush(pq, (nc_, n))
        if goal is None:
            continue                # walled in by other footprints; stats will say so
        cell = goal
        while cell not in seen:
            structure[cell[0]][cell[1]] = "1"
            visited[cell[0]][cell[1]] = True
            cell = prev[cell]
        seen = bfs_from_spawn()

    # ONE building: footfall pockets the door-cloud never joins (walker start
    # scatter, a stranded halo) are not rooms - prune them to void before the
    # wall goes up, so the silhouette is a single body. Pedestals survive even
    # stranded; the reachable count already says so out loud.
    for r in range(depth):
        for c in range(width):
            if visited[r][c] and (r, c) not in seen and (r, c) not in hard:
                structure[r][c] = "0"
                visited[r][c] = False

    # THE WALL, built around that: the skin of the visited cloud. Outside stays
    # void - the building has the crowd's silhouette, not a rectangle's.
    for r in range(depth):
        for c in range(width):
            if not visited[r][c] and structure[r][c] == "0":
                for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < depth and 0 <= nc < width and visited[nr][nc]:
                        structure[r][c] = "w"
                        break

    # exit at the visited cell farthest from the door: the walk's deepest reach
    far = spawn
    far_d = -1
    dist_seen = {spawn}
    q = deque([(spawn, 0)])
    while q:
        (r, c), d = q.popleft()
        if d > far_d and (r, c) not in hard:
            far, far_d = (r, c), d
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (r + dr, c + dc)
            if n not in dist_seen and 0 <= n[0] < depth and 0 <= n[1] < width \
                    and structure[n[0]][n[1]] in ("1", "2"):
                dist_seen.add(n)
                q.append((n, d + 1))
    utilities[far[0]][far[1]] = "t"

    reach = sum(1 for _t, r, c, s_ in islands
                if any(cell in seen for cell in moat(r, c, s_)))
    connected = reach == len(islands)           # measured, never vacuous
    vis = sum(1 for r in range(depth) for c in range(width) if visited[r][c])
    wall = sum(1 for r in range(depth) for c in range(width) if structure[r][c] == "w")
    print(json.dumps({
        "ok": True, "seed": seed,
        "layers": {"structure": structure, "utilities": utilities, "interactables": interactables},
        "stats": {"width": width, "depth": depth, "islands": len(islands), "skipped": skipped,
                  "visited_pct": round(100.0 * vis / (width * depth), 1),
                  "wall_pct": round(100.0 * wall / (width * depth), 1),
                  "walkers": walkers, "connected": connected,
                  "islands_reachable": reach},
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
