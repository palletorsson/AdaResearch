"""Does the seam match the rooms it joins?

TWO ALPHABETS AND AN OFF-BY-ONE, and the first version of this file had both.
The engine's `cells` grid is the WALK grid: "#" is not-floor, everything else
("." , "b", "p", "s", "x") is floor, and it carries one skin column left of the
hall (cell_x0 = -1). The recorded `first_row` is the TILE: "1" floor, "4"/"0"
wall/void. Comparing them character by character reported 51 of 51 mismatches
while every crossing I checked by hand was correct — a fact about the instrument.

So both sides are projected to FLOOR / NOT-FLOOR and the skin column is cut, and
the comparison is the only thing the rule actually claims: the crossing begins
with this hall's floor line and ends with the next hall's.
"""
import json, pathlib, sys
from collections import deque
R = pathlib.Path(r'C:\Users\palle\Documents\GitHub\AdaResearch_46')
walk = json.loads((R / 'ada_run/em_layout_walk.json').read_text())['halls']

def walk_floor(row):
    return ''.join('.' if c != '#' else '#' for c in row)

def tile_floor(cells, w):
    out = []
    for x in range(w):
        c = str(cells[x]) if x < len(cells) else '4'
        out.append('.' if c in ('1', '1s') else '#')
    return ''.join(out)

ok = bad = skipped = 0
rows = []
for key, v in walk.items():
    p = v.get('passage')
    if not p or int(p) < 3:
        skipped += 1
        continue
    cells = v.get('cells') or []
    vest = int(v.get('vestibule', 4))
    skin = -int(v.get('cell_x0', -1))
    porch, court = int(v.get('porch', 0)), int(v.get('court', 0))
    tile = [str(r)[skin:] for r in cells[vest:]]        # cut the skin column
    if court or porch:
        tile = tile[:len(tile) - court - porch]
    if len(tile) < int(p) + 1:
        skipped += 1
        continue
    nfr = (walk.get(str(v.get('next', ''))) or {}).get('first_row')
    if not isinstance(nfr, list):
        skipped += 1
        continue
    w = len(tile[-1])
    lead_ok = walk_floor(tile[-int(p)]) == walk_floor(tile[-int(p) - 1])
    tail_ok = walk_floor(tile[-1]) == tile_floor(nfr, w)
    if lead_ok and tail_ok:
        ok += 1
    else:
        bad += 1
        rows.append((key, int(p), lead_ok, tail_ok,
                     walk_floor(tile[-int(p) - 1]), walk_floor(tile[-int(p)]),
                     walk_floor(tile[-1]), tile_floor(nfr, w)))

# AND THE CORRIDOR MUST STILL BE WALKABLE. The seam widens a crossing past the
# hall it leaves — Palle's service corridor — and a corridor that reads well and
# seals is the worst of both. Every hall is flooded from its first row; every open
# cell of its last row must be reachable.
sealed = []
for key, v in walk.items():
    cells = v.get('cells') or []
    if not cells:
        continue
    vest = int(v.get('vestibule', 4)); skin = -int(v.get('cell_x0', -1))
    porch, court = int(v.get('porch', 0)), int(v.get('court', 0))
    g = [str(r)[skin:] for r in cells[vest:]]
    if court or porch:
        g = g[:len(g) - court - porch]
    if not g:
        continue
    H = len(g)
    free = lambda z, x: 0 <= z < H and 0 <= x < len(g[z]) and g[z][x] != '#'
    seen = set((0, x) for x in range(len(g[0])) if free(0, x))
    q = deque(seen)
    while q:
        z, x = q.popleft()
        for dz, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (z + dz, x + dx)
            if n not in seen and free(*n):
                seen.add(n); q.append(n)
    ex = [x for x in range(len(g[-1])) if free(H - 1, x)]
    if ex and any((H - 1, x) not in seen for x in ex):
        sealed.append(key)

print("crossings carrying a seam: %d" % (ok + bad))
print("  BOTH ends match the rooms they touch : %d" % ok)
print("  mismatch                             : %d" % bad)
print("  skipped (no seam, or no successor recorded): %d" % skipped)
for k, p, l, t, hl, sf, sl, nf in rows[:6]:
    print("\n  %s  depth %d  lead=%s tail=%s" % (k, p, l, t))
    print("     hall's last row  : %s" % hl)
    print("     seam's first row : %s" % sf)
    print("     seam's last row  : %s" % sl)
    print("     next hall's first: %s" % nf)
print()
print("halls sealed between their first and last row: %d" % len(sealed))
for s in sealed[:8]:
    print("   %s" % s)
sys.exit(1 if (bad or sealed) else 0)
