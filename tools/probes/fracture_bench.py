"""fracture_bench.py - the bench the fracture work is predicted on. THE RULE, exactly as the work runs it.

CELLS are voxels of a block nx x ny x nz. A BOND is the face two neighbouring cells share. Every bond has a
STRENGTH (the grain, a seeded hash) and carries a LOAD.
  BLOW     a stone lands on a lattice point of the standing block's front; its power is shared among the (up to
           twelve) live bonds round that point: three planes.
  STEP     every live bond whose load is more than its strength breaks. Breaking uses the strength up: the EXCESS goes
           on, in equal shares, to the live bonds AHEAD of it in its own plane (across its four edges); only when none
           is left ahead does it turn the corner, to the live bonds of the other two directions that touch its edges.
           With nothing live in reach the excess is lost.
  PIECES   cells still joined through unbroken bonds. The largest piece that stands on the ground is the stump;
           every other piece leaves, and takes its cells' bonds (and whatever load they carried) with it.
Bond index ((a*nx + i)*ny + j)*nz + k: the face between cell (i,j,k) and its neighbour one step along axis a.

    python fracture_bench.py [power] [-v]     -> the table: per grain, per blow
    python fracture_bench.py --json           -> the predictions the tower probe checks against
"""
import sys, json
from collections import deque

N = (12, 10, 6)
SEED = 7
DEPTH = 1
TARGETS = [(9, 7), (3, 6), (6, 4), (8, 3), (3, 3), (7, 2)]
GRAINS = ['even', 'layered', 'columnar', 'glass', 'knotted']
AX = [(1, 0, 0), (0, 1, 0), (0, 0, 1)]


def hash01(*key):
    h = 2166136261
    for v in key:
        h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
        h ^= h >> 13
        h = (h * 1274126177) & 0xffffffff
    h ^= h >> 16
    return (h & 0xffffff) / 16777216.0


def strength(grain, seed, a, i, j, k):
    h = hash01(seed, a, i, j, k)
    if grain == 'even': return 0.35 + 0.65 * h
    if grain == 'glass': return 0.30 + 0.12 * h
    if grain == 'layered': return (0.16 + 0.1 * h) if (a == 1 and j % 3 == 2) else (0.75 + 0.6 * h)
    if grain == 'columnar': return (0.16 + 0.1 * h) if ((a == 0 and i % 3 == 2) or (a == 2 and k % 3 == 2)) else (0.75 + 0.6 * h)
    if grain == 'knotted': return (1.6 + 0.8 * h) if hash01(seed, 99, i // 3, j // 3, k // 3) > 0.62 else (0.28 + 0.3 * h)
    raise ValueError(grain)


class Block:
    def __init__(self, grain, n=N, seed=SEED):
        self.n = n; self.grain = grain; self.seed = seed
        nx, ny, nz = n
        self.count = 3 * nx * ny * nz
        self.broken = bytearray(self.count)
        self.load = [0.0] * self.count
        self.loaded = set()
        self.strength = [0.0] * self.count
        self.exists = bytearray(self.count)
        for a in range(3):
            for i in range(nx):
                for j in range(ny):
                    for k in range(nz):
                        b = self.bond(a, i, j, k)
                        if self.in_lattice(i + AX[a][0], j + AX[a][1], k + AX[a][2]):
                            self.exists[b] = 1
                            self.strength[b] = strength(grain, seed, a, i, j, k)
        self.steps = 0; self.broke = 0

    def in_lattice(self, i, j, k):
        return 0 <= i < self.n[0] and 0 <= j < self.n[1] and 0 <= k < self.n[2]

    def cell(self, i, j, k): return (i * self.n[1] + j) * self.n[2] + k

    def bond(self, a, i, j, k): return ((a * self.n[0] + i) * self.n[1] + j) * self.n[2] + k

    def live(self, a, i, j, k):
        if not self.in_lattice(i, j, k): return -1
        b = self.bond(a, i, j, k)
        if not self.exists[b] or self.broken[b]: return -1
        return b

    def touching(self, b):
        """the twelve faces that share an edge with face b: (ahead, round), each a list of live bond indices"""
        nx, ny, nz = self.n
        k = b % nz; j = (b // nz) % ny; i = (b // (nz * ny)) % nx; a = b // (nz * ny * nx)
        p = [i, j, k]
        ahead = []; round_ = []
        for t in range(3):
            if t == a: continue
            for s in (1, -1):
                q = list(p); q[t] += s
                x = self.live(a, q[0], q[1], q[2])
                if x >= 0: ahead.append(x)
                base = list(p)
                if s == -1: base[t] -= 1
                x = self.live(t, base[0], base[1], base[2])
                if x >= 0: round_.append(x)
                base[a] += 1
                x = self.live(t, base[0], base[1], base[2])
                if x >= 0: round_.append(x)
        return ahead, round_

    def step(self):
        breaking = sorted(b for b in self.loaded if not self.broken[b] and self.load[b] > self.strength[b])
        if not breaking: return 0
        for b in breaking: self.broken[b] = 1
        gains = {}
        for b in breaking:
            ahead, round_ = self.touching(b)
            heirs = ahead if ahead else round_
            if not heirs: continue
            excess = self.load[b] - self.strength[b]
            for q in heirs: gains[q] = gains.get(q, 0.0) + excess / float(len(heirs))
        for b in breaking:
            self.load[b] = 0.0; self.loaded.discard(b)
        for q, g in gains.items():
            self.load[q] += g; self.loaded.add(q)
        self.steps += 1; self.broke += len(breaking)
        return len(breaking)

    def blow(self, v, power):
        """a stone on lattice point v: its power shared among the live bonds round it. Returns bonds broken."""
        bonds = []
        for a in range(3):
            others = [t for t in range(3) if t != a]
            for da in (-1, 0):
                for db in (-1, 0):
                    c = [v[0], v[1], v[2]]; c[a] -= 1; c[others[0]] += da; c[others[1]] += db
                    x = self.live(a, c[0], c[1], c[2])
                    if x >= 0: bonds.append(x)
        for b in bonds:
            self.load[b] += power / float(max(1, len(bonds))); self.loaded.add(b)
        before = self.broke
        while self.step(): pass
        return self.broke - before

    def components(self):
        nx, ny, nz = self.n
        seen = {}
        out = []
        for i in range(nx):
            for j in range(ny):
                for k in range(nz):
                    c = self.cell(i, j, k)
                    if c in seen: continue
                    comp = [c]; seen[c] = len(out); dq = deque([(i, j, k)])
                    while dq:
                        x = dq.popleft()
                        for a in range(3):
                            for s in (1, -1):
                                y = (x[0] + s * AX[a][0], x[1] + s * AX[a][1], x[2] + s * AX[a][2])
                                if not self.in_lattice(*y): continue
                                cy = self.cell(*y)
                                if cy in seen: continue
                                lo = x if s == 1 else y
                                if self.broken[self.bond(a, lo[0], lo[1], lo[2])]: continue
                                seen[cy] = len(out); comp.append(cy); dq.append(y)
                    out.append(comp)
        return out


def run(grain, power):
    blk = Block(grain)
    rows = []
    for t in TARGETS:
        broke = blk.blow((t[0], t[1], N[2] - DEPTH), power)
        sizes = sorted((len(c) for c in blk.components()), reverse=True)
        rows.append({"broke": broke, "pieces": len(sizes), "largest": sizes[:6], "singles": sum(1 for x in sizes if x == 1), "steps": blk.steps, "sizes": sizes})
    return rows


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    powers = [float(a) for a in args] if args else [120.0]
    if '--json' in sys.argv:
        print(json.dumps({g: [[r["broke"], r["pieces"], r["largest"][:4], r["steps"]] for r in run(g, powers[0])] for g in GRAINS}))
        sys.exit(0)
    for power in powers:
        for g in GRAINS:
            rows = run(g, power)
            print('%-9s P=%4.0f | after six blows: pieces %3d (singles %3d, 2-7: %3d, >=8: %2d) steps %3d | per blow: %s' % (
                g, power, rows[-1]["pieces"], rows[-1]["singles"], sum(1 for x in rows[-1]["sizes"] if 2 <= x < 8), sum(1 for x in rows[-1]["sizes"] if x >= 8), rows[-1]["steps"],
                '  '.join('%d>%d%s' % (r["broke"], r["pieces"], str(r["largest"][:3]).replace(' ', '')) for r in rows)))
