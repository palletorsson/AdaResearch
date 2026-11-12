"""colonization_bench.py - the bench the colonization floor is predicted on. THE RULE, exactly as the work runs it,
in doubles and in the same order.

A field `wide` x `deep` metres (x east, y north, origin at the middle). POINTS ask; SITES answer.
  STEP   every point asks the nearest site that may answer, if one stands within HEAR (ties: the older site).
         every site that was asked grows one piece of length PIECE toward the sum of the unit directions to its
         askers - unless it has already grown a child at that very place.
         a point is TAKEN when a site stands within TAKE of it.
  `answers`: all = every site may answer again (a tree); tips = only a site without a child (a thread).
  BUDGET sites can be made; a thread that cannot branch spends all of it and takes few points.
The root stands at the middle of the near edge. The field begins with a seeded scatter of points.

    python tools/probes/colonization_bench.py                 -> the table for seeds 1..8, both policies
    python tools/probes/colonization_bench.py --json <seed>   -> {policy: [steps, sites, points taken, points left, metres]}
"""
import sys, json, math

WIDE, DEEP = 12.0, 4.4
HEAR, TAKE, PIECE = 1.6, 0.3, 0.15
POINTS = 60
BUDGET = 900        # sites: when they are spent nothing grows


def hash01(*key):
    h = 2166136261
    for v in key:
        h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
        h ^= h >> 13
        h = (h * 1274126177) & 0xffffffff
    h ^= h >> 16
    return (h & 0xffffff) / 16777216.0


class Field:
    def __init__(self, seed, answers):
        self.answers = answers
        self.sx = [0.0]; self.sy = [-DEEP * 0.5 + 0.2]; self.parent = [-1]; self.children = [[]]
        self.px = []; self.py = []; self.alive = []
        for i in range(POINTS):
            self.add_point((hash01(seed, i, 0) - 0.5) * (WIDE - 0.6), (hash01(seed, i, 1) - 0.5) * (DEEP - 0.6))
        self.steps = 0

    def add_point(self, x, y):
        self.px.append(x); self.py.append(y); self.alive.append(True)

    def step(self):
        """returns how many sites grew"""
        asked = {}
        for t in range(len(self.px)):
            if not self.alive[t]: continue
            best = -1; best_d = HEAR * HEAR
            for s in range(len(self.sx)):
                if self.answers == 'tips' and self.children[s]: continue
                dx = self.px[t] - self.sx[s]; dy = self.py[t] - self.sy[s]
                d = dx * dx + dy * dy
                if d < best_d or (d == best_d and best >= 0 and s < best):
                    best = s; best_d = d
            if best < 0: continue
            dx = self.px[t] - self.sx[best]; dy = self.py[t] - self.sy[best]
            far = math.sqrt(dx * dx + dy * dy)
            if far < 1e-9: continue
            ax, ay = asked.get(best, (0.0, 0.0))
            asked[best] = (ax + dx / far, ay + dy / far)
        grew = 0
        for s in sorted(asked):
            if len(self.sx) >= BUDGET: break
            ax, ay = asked[s]
            far = math.sqrt(ax * ax + ay * ay)
            if far < 1e-9: continue
            nx = self.sx[s] + ax / far * PIECE; ny = self.sy[s] + ay / far * PIECE
            if any((self.sx[c] - nx) ** 2 + (self.sy[c] - ny) ** 2 < 1e-12 for c in self.children[s]): continue
            self.children[s].append(len(self.sx))
            self.sx.append(nx); self.sy.append(ny); self.parent.append(s); self.children.append([])
            grew += 1
            for t in range(len(self.px)):
                if self.alive[t] and (self.px[t] - nx) ** 2 + (self.py[t] - ny) ** 2 < TAKE * TAKE: self.alive[t] = False
        self.steps += 1
        return grew

    def run(self):
        while self.step() > 0: pass
        return [self.steps, len(self.sx), sum(1 for a in self.alive if not a), sum(1 for a in self.alive if a), round((len(self.sx) - 1) * PIECE, 2)]


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    if '--json' in sys.argv:
        print(json.dumps({p: Field(int(args[0]), p).run() for p in ('all', 'tips')}))
        sys.exit(0)
    for seed in range(1, 9):
        for policy in ('all', 'tips'):
            steps, sites, taken, left, metres = Field(seed, policy).run()
            print('seed %d  answers %-4s: %4d steps, %4d sites, %5.1f m of branch, %2d of %d points taken, %2d never heard or never reached' % (seed, policy, steps, sites, metres, taken, POINTS, left))
