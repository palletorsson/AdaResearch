"""two_reports_bench.py - the rule table of TWO REPORTS before it is built (floor
SpeculativeComputation_Paraconsistent_Engineering; the pass, 2026-11-16).

Report A: the door is open. Report B: the door is closed. Two reasoners are told what the visitor tells them.
CLASSICAL: every statement is true or false. PARACONSISTENT (the Logic of Paradox): a statement may be true, false,
or both; `follows` means: in every case where all that was told holds (true or both), the conclusion holds.

Seven conclusions are asked of each. The last is asked with one more thing told: 'the door is open, or the lamp is
on' - it shows the rule the paraconsistent reasoner gives up (from 'A or B' and 'not A', B).

With WHERE FROM, the reports name their doors: A is about the west door, B about the east door. Then they are
about different things and neither reasoner has a contradiction.

The same arithmetic is in commons/artifacts/two_reports/two_reports.gd; the walk probe compares."""
import itertools

F, B, T = 0, 1, 2


def val(f, v):
    if isinstance(f, str): return v[f]
    if f[0] == 'not': return 2 - val(f[1], v)
    if f[0] == 'and': return min(val(f[1], v), val(f[2], v))
    if f[0] == 'or': return max(val(f[1], v), val(f[2], v))
    raise ValueError(f)


def atoms(f, out):
    if isinstance(f, str): out.add(f)
    else:
        for g in f[1:]: atoms(g, out)
    return out


def follows(premises, conclusion, values):
    names = sorted(set().union(*[atoms(f, set()) for f in premises + [conclusion]]))
    for combo in itertools.product(values, repeat=len(names)):
        v = dict(zip(names, combo))
        if all(val(p, v) >= B for p in premises) and val(conclusion, v) < B: return False
    return True


def table(told_a, told_b, sourced):
    p1, p2 = ('W', 'E') if sourced else ('P', 'P')
    premises = ([p1] if told_a else []) + ([('not', p2)] if told_b else [])
    rows = [p1, ('not', p2), ('and', p1, ('not', p1)), ('or', p1, 'Q'), 'Q', ('not', 'Q')]
    out = []
    for name, values in (('classical', (F, T)), ('paraconsistent', (F, B, T))):
        got = [follows(premises, r, values) for r in rows]
        got.append(follows(premises + [('or', p2, 'Q')], 'Q', values))
        out.append((name, got))
    return out


if __name__ == '__main__':
    for sourced in (False, True):
        for told_a, told_b in ((False, False), (True, False), (False, True), (True, True)):
            line = '%s A %s B %s:' % ('sourced' if sourced else 'bare   ', 'told' if told_a else '-   ', 'told' if told_b else '-   ')
            for name, got in table(told_a, told_b, sourced):
                line += '  %s %s (%d)' % (name, ''.join('Y' if g else '.' for g in got), sum(got))
            print(line)
