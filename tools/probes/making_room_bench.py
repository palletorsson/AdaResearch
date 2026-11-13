"""making_room_bench.py - the workshop of the floor work `making_room` (hall GT_Matching), counted before it was built.
The people, tools and lines are read from the work's own script (algorithms/graphtheory/making_room/making_room.gd);
the rule is the hall model's (doc/book/studies/graphs-through-the-hands/GT_Matching/matching_model.gd): greedy takes
the lines in order and pairs two free ends; an alternating path from a waiting maker to a free tool is searched
breadth first, a paired line walked from the tool to the maker and an unpaired one from the maker to the tool.

  python tools/probes/making_room_bench.py

Prints, for the full workshop and for the one without its last tool: the first arrangement, who waits, the question
that goes down the row, and what the rearrangement gives - and that no order of choosing would have done better than
the rearrangement does.
"""
import re
from collections import deque
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
text = (ROOT / 'algorithms/graphtheory/making_room/making_room.gd').read_text(encoding='utf-8')
PEOPLE = re.findall(r'"([^"]+)"', re.search(r'const PEOPLE := \[(.*?)\]', text).group(1))
TOOLS = re.findall(r'"([^"]+)"', re.search(r'const TOOLS := \[(.*?)\]', text).group(1))
LINKS = [(int(a), int(b)) for a, b in re.findall(r'\[(\d+), (\d+)\]', re.search(r'const LINKS := \[(.*)\]', text).group(1))]
N = len(PEOPLE)


def name(v):
    return PEOPLE[v] if v < N else TOOLS[v - N].lower()


def greedy(links):
    mate = {}
    for a, b in links:
        if a not in mate and b not in mate:
            mate[a] = b
            mate[b] = a
    return mate


def alternating(links, mate, tools):
    nxt = {}
    for a, b in links:
        if mate.get(a) == b:
            nxt.setdefault(b, []).append(a)
        else:
            nxt.setdefault(a, []).append(b)
    for person in range(N):
        if person in mate:
            continue
        for tool in tools:
            if tool in mate:
                continue
            came = {person: None}
            queue = deque([person])
            while queue:
                v = queue.popleft()
                if v == tool:
                    path = []
                    while v is not None:
                        path.append(v)
                        v = came[v]
                    return path[::-1]
                for w in nxt.get(v, []):
                    if w not in came:
                        came[w] = v
                        queue.append(w)
    return []


def augment(mate, path):
    for i in range(1, len(path) - 1, 2):
        mate.pop(path[i], None)
        mate.pop(path[i + 1], None)
    for i in range(0, len(path) - 1, 2):
        mate[path[i]] = path[i + 1]
        mate[path[i + 1]] = path[i]


def most(links):
    best = 0
    for order in permutations(links):
        best = max(best, len(greedy(order)) // 2)
        if best == N:
            break
    return best


if __name__ == '__main__':
    for label, tools in (('four tools', list(range(N, N + len(TOOLS)))), ('the last tool is not there', list(range(N, N + len(TOOLS) - 1)))):
        links = [l for l in LINKS if l[1] in tools]
        mate = greedy(links)
        pairs = ['%s-%s' % (name(p), name(mate[p])) for p in range(N) if p in mate]
        waits = [name(p) for p in range(N) if p not in mate]
        path = alternating(links, mate, tools)
        print('%s: the first arrangement %s; waiting: %s; unused: %s' % (label, ' '.join(pairs), ' '.join(waits) or '-', ' '.join(name(t) for t in tools if t not in mate) or '-'))
        if path:
            print('   the question: ' + ' > '.join(name(v) for v in path) + '   (%d makers step to another bench)' % ((len(path) - 2) // 2))
            augment(mate, path)
            print('   after: ' + ' '.join('%s-%s' % (name(p), name(mate[p])) for p in range(N) if p in mate) + '; working %d of %d' % (len(mate) // 2, N))
        else:
            print('   the question finds no free tool: nobody moves; working %d of %d' % (len(mate) // 2, N))
        print('   the most any order of choosing could pair: %d' % most(links))
