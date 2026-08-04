import json, os
from collections import Counter, defaultdict
os.chdir(r"C:/Users/palle/Documents/GitHub/AdaResearch_46")
tp = json.load(open('commons/data/template_patterns.json', encoding='utf-8'))['patterns']
mus = {k: p for k, p in tp.items() if isinstance(p, dict) and p.get('museum')}
print(f"{len(mus)} museum tiles")

# how much of each tile is a REPEATED band? scan horizontal row-signatures
rowsig = Counter()
rows_by_tile = {}
for k, p in mus.items():
    rs = ["|".join(str(c) for c in row) for row in p['tile']]
    rows_by_tile[k] = rs
    for r in set(rs):
        rowsig[r] += 1
shared_rows = {r: n for r, n in rowsig.items() if n >= 3}
print(f"row signatures shared by 3+ museums: {len(shared_rows)}")

# internal repetition: how many rows in a tile are duplicates of another row in the SAME tile
for k, rs in sorted(rows_by_tile.items()):
    c = Counter(rs)
    rep = sum(n - 1 for n in c.values() if n > 1)
    print(f"  {k:38} {len(rs):3} rows, {len(c):3} distinct, {rep:3} repeats ({rep*100//len(rs)}%)")

# recurring kxk patches across DIFFERENT museums
def patches(tile, h, w):
    H, W = len(tile), len(tile[0])
    for y in range(H - h + 1):
        for x in range(W - w + 1):
            yield y, x, "/".join("|".join(str(c) for c in tile[y+dy][x:x+w]) for dy in range(h))

for (ph, pw) in ((3, 3), (4, 5), (5, 7)):
    seen = defaultdict(set)
    counts = Counter()
    for k, p in mus.items():
        for y, x, sig in patches(p['tile'], ph, pw):
            seen[sig].add(k)
            counts[sig] += 1
    cross = {s: seen[s] for s in seen if len(seen[s]) >= 4}
    # only interesting if the patch is not pure floor/pure wall
    def interesting(s):
        cells = set(s.replace("/", "|").split("|"))
        return len(cells) > 1 and ("1s" in cells or "2s" in cells or "3s" in cells or "4" in cells)
    ci = {s: v for s, v in cross.items() if interesting(s)}
    print(f"\n{ph}x{pw} patches shared by 4+ museums (non-trivial): {len(ci)}")
    for s, ms in sorted(ci.items(), key=lambda kv: -len(kv[1]))[:6]:
        print(f"   in {len(ms):2} museums, {counts[s]:4} occurrences: {s}")
