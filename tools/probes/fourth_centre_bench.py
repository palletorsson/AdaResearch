"""fourth_centre_bench.py - the rule of YOU ARE THE FOURTH CENTRE (floor ML_Classification), before it is built.

The work: the tutorial's own observations and starting centres (doc/book/studies/ml-classification/cluster_model.gd)
stand on a floor, three metres to its unit. Three centres are posts. The fourth is the visitor. Standing still asks
for an assignment (each point to its nearest centre; a tie goes to the lower index, so the visitor loses ties). A
plate moves the three posts to the mean of their points; the visitor walks to the mean of theirs.

What the bench asks:
  1. blobs: what does the first assignment give, and when the fourth centre walks onto the third blob, how many
     points change group without moving?  (the hall: 'Why can a point change groups even though the point itself
     has not moved?')
  2. assign and mean in turn: does the sum of squared distances ever rise?  how many rounds until nothing changes?
     with four centres and three blobs, which blob is cut in two, or which centre is left with nothing?
  3. rings: is each ring kept whole, or does the colour break?
  4. block, where no groups were planted: does the rule still give four?
  5. the tie: a point exactly between two centres.

    python tools/probes/fourth_centre_bench.py
"""
import math

START = [(-0.6, -0.3), (0.0, 0.1), (0.6, 0.3), (0.0, -0.8)]


def data(cohort):
    if cohort == 'blobs':
        return [(c[0] + o[0], c[1] + o[1]) for c in [(-0.8, -0.6), (0.8, -0.6), (0.0, 0.7)] for o in [(-0.1, 0), (0.1, 0), (0, -0.15), (0, 0.15)]]
    if cohort == 'rings':
        return [(math.cos(math.tau * i / 12.0) * r, math.sin(math.tau * i / 12.0) * r) for r in (0.35, 0.85) for i in range(12)]
    return [((x - 2) * 0.4, (z - 2) * 0.4) for z in range(5) for x in range(5)]


def kind(cohort, i):
    if cohort == 'blobs': return i // 4
    if cohort == 'rings': return i // 12
    return (i % 5 + i // 5) % 3


def nearest(p, centres):
    win, best = 0, (p[0] - centres[0][0]) ** 2 + (p[1] - centres[0][1]) ** 2
    for j in range(1, len(centres)):
        d = (p[0] - centres[j][0]) ** 2 + (p[1] - centres[j][1]) ** 2
        if d < best: win, best = j, d          # equal distances keep the lower index
    return win


def assign(pts, centres): return [nearest(p, centres) for p in pts]


def means(pts, groups, centres):
    out = []
    for j, c in enumerate(centres):
        mine = [p for p, g in zip(pts, groups) if g == j]
        out.append((sum(p[0] for p in mine) / len(mine), sum(p[1] for p in mine) / len(mine)) if mine else c)   # a centre with no points stays
    return out


def sse(pts, groups, centres): return sum((p[0] - centres[g][0]) ** 2 + (p[1] - centres[g][1]) ** 2 for p, g in zip(pts, groups))


def sizes(groups): return [groups.count(j) for j in range(4)]


ok = True
pts = data('blobs')
first = assign(pts, START)
print('1. blobs, first assignment (posts 1, 2, 3 and the fourth centre at its start):', sizes(first), ' sum of squares %.3f' % sse(pts, first, START))
walked = START[:3] + [(0.0, 0.7)]
second = assign(pts, walked)
changed = sum(1 for a, b in zip(first, second) if a != b)
print('   the fourth centre walks onto the third blob (0, 0.7):', sizes(second), ' changed group without moving: %d' % changed, ' sum of squares %.3f' % sse(pts, second, walked))
ok = ok and changed > 0
print('2. assign and mean in turn, all four centres going to their means (blobs, from the walked place):')
centres, groups, rounds, falls = walked, second, 0, True
last = sse(pts, groups, centres)
while True:
    centres = means(pts, groups, centres)
    after_mean = sse(pts, groups, centres)
    new = assign(pts, centres)
    after_assign = sse(pts, new, centres)
    falls = falls and after_mean <= last + 1e-12 and after_assign <= after_mean + 1e-12
    rounds += 1
    print('   round %d: after the means %.3f, after the assignment %.3f, sizes %s, changed %d' % (rounds, after_mean, after_assign, sizes(new), sum(1 for a, b in zip(groups, new) if a != b)))
    if new == groups: break
    groups, last = new, after_assign
print('   nothing changes after round %d; the sum of squares never rose: %s' % (rounds, falls))
per_blob = [sorted(set(groups[b * 4:b * 4 + 4])) for b in range(3)]
print('   groups found in each planted blob:', per_blob, ' centres left with nothing:', [j + 1 for j in range(4) if groups.count(j) == 0])
ok = ok and falls
for cohort in ('rings', 'block'):
    pts = data(cohort)
    centres = START[:]
    groups = assign(pts, centres)
    rounds = 0
    while True:
        centres = means(pts, groups, centres)
        new = assign(pts, centres)
        rounds += 1
        if new == groups: break
        groups = new
    if cohort == 'rings':
        inner, outer = sorted(set(groups[:12])), sorted(set(groups[12:]))
        print('3. rings, after %d rounds: sizes %s; groups on the inner ring %s, on the outer ring %s' % (rounds, sizes(groups), inner, outer))
        ok = ok and len(outer) >= 2
    else:
        print('4. block, after %d rounds: sizes %s - four groups where none were planted: %s' % (rounds, sizes(groups), all(n > 0 for n in sizes(groups))))
        ok = ok and all(n > 0 for n in sizes(groups))
    mixed = [[sum(1 for i, g in enumerate(groups) if g == j and kind(cohort, i) == k) for k in range(3)] for j in range(4)]
    print('   what each group holds, by kind of thing:', mixed)
tie = nearest((0.0, 0.0), [(-1.0, 0.0), (1.0, 0.0), (5.0, 5.0), (5.0, -5.0)])
print('5. a point exactly between centre 1 and centre 2 is given to centre %d' % (tie + 1))
tie4 = nearest((0.0, 0.0), [(5.0, 5.0), (5.0, -5.0), (-1.0, 0.0), (1.0, 0.0)])
print('   and exactly between centre 3 and the fourth (the visitor): to centre %d - the visitor loses a tie' % (tie4 + 1))
ok = ok and tie == 0 and tie4 == 2
print('PASSED' if ok else 'FAILED')
