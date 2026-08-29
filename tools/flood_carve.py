"""flood_carve.py — a map carved by water flowing AROUND a selection of artifacts.

2026-08-27, Palle: "imagine the artifact standing on the sand? A flood of water
flows around them, digging out the inbetweens and around them based on a foot
print. That is a minimap based on a selection of artifacts?"

It is. This inverts the placement pipeline: the artifacts come FIRST, scattered
on an untouched sand plane; then a flood of droplet walkers enters from the
south edge and drains to the north, each one carving the cells it crosses. The
footprints are erosion-resistant, so the water concentrates BETWEEN them - the
in-betweens become the deep channels, the artifact feet get hugged by flow, and
sand nobody's water touched stays standing as dunes. The map is the negative of
the collection.

  python tools/flood_carve.py --in req.json      # carve, print layers JSON
  req: { "tokens": [...], "width": 20, "depth": 26, "seed": 3,
         "droplets": 0 (auto), "layers": {...}? }
  - layers given and tokens absent -> the draft's own artifacts are the islands
    (their current positions kept); otherwise tokens are scattered by seeded
    blue-noise honouring footprints.

Output: { ok, layers: {structure, utilities, interactables}, stats: {carved_pct,
  dune_pct, droplets, connected} }. structure bands by carve depth: heavy flow
  "1" (channel floor), light flow "2" (shoulder), untouched "w" (dune). One
  successful droplet's full path is forced to "1", so spawn->exit connectivity
  is carried by construction and then VERIFIED by BFS anyway - stats.connected
  is measured, not assumed.
"""
from __future__ import annotations
import json
import random
import sys
import os
import math
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from place_layers import artifact_any, tokens_in_draft  # noqa: E402


def footprint_side(cells: int) -> int:
    return max(1, math.ceil(math.sqrt(max(1, cells))))


def scatter(tokens: list[str], width: int, depth: int, rng: random.Random):
    """Seeded dart-throwing with spacing: footprints never touch, and every
    island keeps a 1-cell moat so water can always hug its feet."""
    placed = []  # (token, r, c, side)
    occupied: set[tuple[int, int]] = set()
    for tok in tokens:
        a = artifact_any(tok)
        side = footprint_side(a.footprint_cells if a else 1)
        ok_at = None
        for _ in range(600):
            r = rng.randrange(2, max(3, depth - side - 2))
            c = rng.randrange(2, max(3, width - side - 2))
            cells = [(r + dr, c + dc) for dr in range(-1, side + 1) for dc in range(-1, side + 1)]
            if all(cell not in occupied for cell in cells):
                ok_at = (r, c)
                break
        if ok_at is None:
            continue  # reported by caller via skipped list
        r, c = ok_at
        for dr in range(side):
            for dc in range(side):
                occupied.add((r + dr, c + dc))
        placed.append((tok, r, c, side))
    return placed


def carve(width: int, depth: int, hard: set[tuple[int, int]], seed: int,
          droplets: int) -> tuple[list[list[float]], list[tuple[int, int]]]:
    """Droplet walkers south -> north around the hard cells. Returns the carve
    field and one full successful path (the connectivity guarantee)."""
    rng = random.Random(seed)
    # potential: BFS distance to the north edge, walls infinite - water knows
    # where the sea is even before it starts digging
    INF = 10 ** 9
    dist = [[INF] * width for _ in range(depth)]
    q = deque()
    for c in range(width):
        if (0, c) not in hard:
            dist[0][c] = 0
            q.append((0, c))
    while q:
        r, c = q.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nr, nc = r + dr, c + dc
            if 0 <= nr < depth and 0 <= nc < width and (nr, nc) not in hard \
                    and dist[nr][nc] > dist[r][c] + 1:
                dist[nr][nc] = dist[r][c] + 1
                q.append((nr, nc))

    field = [[0.0] * width for _ in range(depth)]
    keeper: list[tuple[int, int]] = []
    for i in range(droplets):
        c = rng.randrange(width)
        r = depth - 1
        if (r, c) in hard or dist[r][c] >= INF:
            continue
        path = [(r, c)]
        last = (0, 0)
        for _ in range(width * depth):
            field[r][c] += 1.0
            if r == 0:
                break
            best = None
            best_key = None
            for dr, dc in ((-1, 0), (0, 1), (0, -1), (1, 0)):
                nr, nc = r + dr, c + dc
                if not (0 <= nr < depth and 0 <= nc < width) or (nr, nc) in hard:
                    continue
                if dist[nr][nc] >= INF:
                    continue
                # downhill toward the sea, with momentum and a braid of noise -
                # identical droplets would dig ONE canal; the noise digs a delta
                key = dist[nr][nc] + rng.random() * 1.8 \
                    - (0.6 if (dr, dc) == last else 0.0)
                if best_key is None or key < best_key:
                    best_key = key
                    best = (nr, nc, dr, dc)
            if best is None:
                break
            r, c, dr, dc = best
            last = (dr, dc)
            path.append((r, c))
        if r == 0 and not keeper:
            keeper = path
    return field, keeper


def main() -> int:
    in_path = None
    for a in sys.argv[1:]:
        if a.startswith("--in="):
            in_path = a.split("=", 1)[1]
    if not in_path:
        print(__doc__)
        return 2
    req = json.load(open(in_path, encoding="utf-8"))
    width = int(req.get("width") or 20)
    depth = int(req.get("depth") or 26)
    seed = int(req.get("seed") or 0)
    rng = random.Random(seed)

    tokens = req.get("tokens") or []
    layers_in = req.get("layers") or {}
    islands = []  # (token, r, c, side)
    if not tokens and layers_in:
        # the draft's own artifacts, at their current anchors
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

    droplets = int(req.get("droplets") or 0) or width * depth * 3
    field, keeper = carve(width, depth, hard, seed, droplets)

    peak = max((max(row) for row in field), default=1.0) or 1.0
    structure = [["w"] * width for _ in range(depth)]
    for r in range(depth):
        for c in range(width):
            u = field[r][c] / peak
            # thresholds tuned by eye on the first delta (seed 11, eight heroes):
            # at 0.10/0.02 the flood ate 71% of the map and the sand lost the
            # argument. The water should WIN the in-betweens, not the map.
            if u > 0.24:
                structure[r][c] = "1"
            elif u > 0.07:
                structure[r][c] = "2"
    for (r, c) in keeper:
        structure[r][c] = "1"
    # the islands: artifacts STAND ON THE SAND - their footprint keeps its dune
    # height as a pedestal ("2", walkable shoulder), anchor cell carries the token
    for _tok, r, c, side in islands:
        for dr in range(side):
            for dc in range(side):
                if 0 <= r + dr < depth and 0 <= c + dc < width:
                    structure[r + dr][c + dc] = "2"

    utilities = [[""] * width for _ in range(depth)]
    interactables = [[""] * width for _ in range(depth)]
    for tok, r, c, _side in islands:
        interactables[r][c] = f"{tok}:0:1"
    # spawn where the flood entered hardest, exit where it drained
    entry = max(range(width), key=lambda c: field[depth - 1][c])
    outlet = max(range(width), key=lambda c: field[0][c])
    utilities[depth - 1][entry] = "s"
    utilities[0][outlet] = "t"

    # measured, not assumed: can you walk the delta?
    walk = {(r, c) for r in range(depth) for c in range(width) if structure[r][c] in ("1", "2")}
    seen = set()
    q = deque([(depth - 1, entry)])
    seen.add((depth - 1, entry))
    while q:
        r, c = q.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (r + dr, c + dc)
            if n in walk and n not in seen:
                seen.add(n)
                q.append(n)
    connected = (0, outlet) in seen
    reach_islands = sum(1 for _t, r, c, _s in islands if (r, c) in seen)

    carved = sum(1 for r in range(depth) for c in range(width) if structure[r][c] == "1")
    dunes = sum(1 for r in range(depth) for c in range(width) if structure[r][c] == "w")
    print(json.dumps({
        "ok": True, "seed": seed,
        "layers": {"structure": structure, "utilities": utilities, "interactables": interactables},
        "stats": {"width": width, "depth": depth, "islands": len(islands),
                  "skipped": skipped, "carved_pct": round(100.0 * carved / (width * depth), 1),
                  "dune_pct": round(100.0 * dunes / (width * depth), 1),
                  "droplets": droplets, "connected": connected,
                  "islands_reachable": reach_islands},
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
