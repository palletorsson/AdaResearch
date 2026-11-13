"""room_for_another_bench.py - the harbour of the floor work `room_for_another` (hall GT_Flow), counted before it was
built. The network is the hall's own: the `links` of commons/artifacts/graph_worlds/flow_model.gd are read from that
file, not typed again. Node 0 is the south bank, 1 and 2 the depots, 3 and 4 the yards, 5 the dock, 6 the ship's side.

At the size of a body every crate slot is a bridge of its own (a link of capacity two is two bridges). A bridge is
EMPTY or FULL. A body can enter an EMPTY bridge only from its tail and leaves it FULL; it can enter a FULL bridge only
from its head and leaves it EMPTY (the promise is taken back). The south bank and the ship's side are one floor: the
body walks round outside.

  python tools/probes/room_for_another_bench.py

Prints: the first allocation and the second (which runs against the first), the most that fits and what closes the
harbour then; and, over EVERY state a body can produce from each of the three plans, that the crates always make a
plan that adds up (nothing promised into a land that is not promised out of it, except one crate where the body
stands), that the body can always get out, and the fewest bridges a body walks to bring the second delivery.
"""
import re
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE, SINK = 0, 6


def links():
    text = (ROOT / 'commons/artifacts/graph_worlds/flow_model.gd').read_text(encoding='utf-8')
    found = re.findall(r'\{"a":\s*(\d+),\s*"b":\s*(\d+),\s*"cap":\s*(\d+)\}', text)
    return [(int(a), int(b), int(c)) for a, b, c in found]


def slots(ls):
    """One bridge a crate slot: (tail, head), in the order of the links."""
    out = []
    for a, b, cap in ls:
        out += [(a, b)] * cap
    return out


def residual_path(sl, full):
    """Breadth first from the south bank to the ship's side over what a crate could still take: an EMPTY bridge
    forwards, a FULL one backwards. Neighbours in the order of their numbers, as the hall's model searches."""
    nxt = {}
    for i, (a, b) in enumerate(sl):
        if not full[i]:
            nxt.setdefault(a, {}).setdefault(b, i)
        else:
            nxt.setdefault(b, {}).setdefault(a, i)
    came = {SOURCE: None}
    queue = deque([SOURCE])
    while queue:
        v = queue.popleft()
        if v == SINK:
            path = []
            while came[v] is not None:
                u, i = came[v]
                path.append((i, u, v))
                v = u
            return path[::-1], set(came)
        for w in sorted(nxt.get(v, {})):
            if w not in came:
                came[w] = (v, nxt[v][w])
                queue.append(w)
    return None, set(came)


def allocate(sl, full):
    path, _ = residual_path(sl, full)
    if path is None:
        return None
    for i, u, v in path:
        full[i] = not full[i]
    return path


def excess(sl, full):
    """What is promised into each inner land minus what is promised out of it."""
    e = {}
    for i, (a, b) in enumerate(sl):
        if full[i]:
            e[b] = e.get(b, 0) + 1
            e[a] = e.get(a, 0) - 1
    return {v: x for v, x in e.items() if x != 0 and v not in (SOURCE, SINK)}


def moves(sl, full, land):
    """Where a body standing on `land` (SOURCE and SINK are both the floor outside: 'out') can walk."""
    here = (SOURCE, SINK) if land == 'out' else (land,)
    out = []
    for i, (a, b) in enumerate(sl):
        if not full[i] and a in here:
            out.append((i, b))
        if full[i] and b in here:
            out.append((i, a))
    return out


def explore(sl, start):
    """Every (crates, where the body is) a body can produce from `start` with the body outside."""
    first = (tuple(start), 'out')
    seen = {first: 0}
    queue = deque([first])
    while queue:
        state = queue.popleft()
        full, land = state
        for i, to in moves(sl, full, land):
            after = list(full)
            after[i] = not after[i]
            nxt = (tuple(after), 'out' if to in (SOURCE, SINK) else to)
            if nxt not in seen:
                seen[nxt] = seen[state] + 1
                queue.append(nxt)
    return seen


def can_leave(sl, state, seen_out):
    full, land = state
    queue = deque([state])
    seen = {state}
    while queue:
        s = queue.popleft()
        if s[1] == 'out':
            return True
        for i, to in moves(sl, s[0], s[1]):
            after = list(s[0])
            after[i] = not after[i]
            nxt = (tuple(after), 'out' if to in (SOURCE, SINK) else to)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False


def arrived(sl, full):
    return sum(1 for i, (a, b) in enumerate(sl) if full[i] and b == SINK)


if __name__ == '__main__':
    ls = links()
    sl = slots(ls)
    print('the hall\'s network: %d links, %d crate slots: %s' % (len(ls), len(sl), ' '.join('%d>%d' % s for s in sl)))
    full = [False] * len(sl)
    plans = {'none': list(full)}
    one = allocate(sl, full)
    plans['first'] = list(full)
    print('first allocation : ' + ' '.join('%d>%d' % (u, v) for i, u, v in one))
    two = allocate(sl, full)
    plans['both'] = list(full)
    back = [(u, v) for i, u, v in two if sl[i] == (v, u)]
    print('second allocation: ' + ' '.join('%d>%d' % (u, v) for i, u, v in two) + '   against a promise: ' + ' '.join('%d>%d' % b for b in back))
    third, reach = residual_path(sl, full)
    cut = [sl[i] for i in range(len(sl)) if sl[i][0] in reach and sl[i][1] not in reach]
    print('a third: %s.  Arrived: %d.  From the south bank a crate still reaches lands %s; what closes the harbour: %s = %d full slots'
          % ('none' if third is None else 'yes', arrived(sl, full), sorted(reach), ' '.join('%d>%d' % c for c in cut), len(cut)))
    for name, start in plans.items():
        seen = explore(sl, start)
        bad = []
        for (f, land), steps in seen.items():
            e = excess(sl, f)
            want = {} if land == 'out' else {land: 1}
            if e != want:
                bad.append((f, land, e))
        stuck = [s for s in seen if not can_leave(sl, s, None)]
        outs = {f for (f, land) in seen if land == 'out'}
        most = max(arrived(sl, f) for f in outs)
        fewest = min((steps for (f, land), steps in seen.items() if land == 'out' and arrived(sl, f) == most), default=None)
        print('plan %-5s: %3d states a body can produce, %2d of them with the body outside; plans that do not add up: %d; states the body cannot leave: %d; '
              'the most that arrives: %d, after %s bridges at the fewest' % (name, len(seen), len(outs), len(bad), len(stuck), most, fewest))
