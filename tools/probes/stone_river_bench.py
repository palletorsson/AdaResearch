"""stone_river_bench.py - the stepping stones of the floor work `stone_river` (hall GT_Pathfinding), chosen and counted
before it was built. The river is 10 cells wide and 6 deep, a metre a cell (ten, not twelve: the top of the
floor below's evidence wall stands through the slab along x = -4, and became the river's west end). A cell holds a stone when its seeded
number is under SHARE. A body steps from a stone to a stone that shares an edge with it; the south bank touches the
southern row, the north bank the northern row.

  python tools/probes/stone_river_bench.py [seed]

For a seed: the stones, the fewest stones a crossing needs, and what the hall's question asks - after ANY ONE stone of
that shortest crossing has sunk, is there still a way across, and how much longer is it?
"""
import sys
from collections import deque

WIDE, DEEP, SHARE = 10, 6, 0.58


def hash01(key):
    h = 2166136261
    for v in key:
        h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
        h ^= h >> 13
        h = (h * 1274126177) & 0xffffffff
    h ^= h >> 16
    return float(h & 0xffffff) / 16777216.0


def stones(seed):
    return {(x, z) for x in range(WIDE) for z in range(DEEP) if hash01([seed, x, z]) < SHARE}


def crossing(standing):
    """Fewest stones from the south bank (row DEEP-1) to the north bank (row 0); None when there is no way."""
    queue = deque()
    came = {}
    for x in range(WIDE):
        if (x, DEEP - 1) in standing:
            came[(x, DEEP - 1)] = None
            queue.append((x, DEEP - 1))
    while queue:
        cell = queue.popleft()
        if cell[1] == 0:
            path = []
            while cell is not None:
                path.append(cell)
                cell = came[cell]
            return path[::-1]
        x, z = cell
        for nxt in ((x, z - 1), (x + 1, z), (x - 1, z), (x, z + 1)):
            if nxt in standing and nxt not in came:
                came[nxt] = cell
                queue.append(nxt)
    return None


def judge(seed):
    standing = stones(seed)
    first = crossing(standing)
    if first is None:
        return None
    after = []
    for cell in first:
        again = crossing(standing - {cell})
        after.append(None if again is None else len(again))
    return {"seed": seed, "stones": len(standing), "first": len(first), "after": after, "path": first, "standing": standing}


def draw(j):
    on_path = set(j["path"])
    for z in range(DEEP):
        print('   ' + ' '.join(('o' if (x, z) in on_path else '#') if (x, z) in j["standing"] else '.' for x in range(WIDE)))


if __name__ == '__main__':
    if len(sys.argv) > 1:
        j = judge(int(sys.argv[1]))
        print('seed %d: %d stones; a crossing needs %d; after one of its stones sinks: %s' % (j["seed"], j["stones"], j["first"], j["after"]))
        draw(j)
    else:
        good = []
        for seed in range(1, 400):
            j = judge(seed)
            if j and all(a is not None for a in j["after"]) and 7 <= j["first"] <= 9 and max(j["after"]) >= j["first"] + 2:
                good.append(j)
        print('%d seeds of 399 keep a way across after any one stone of the shortest crossing sinks, with a crossing of 7-9 stones and at least one detour of two more' % len(good))
        for j in good[:6]:
            print('seed %d: %d stones; a crossing needs %d; after one of its stones sinks: %s' % (j["seed"], j["stones"], j["first"], j["after"]))
            draw(j)
