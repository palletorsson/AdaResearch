"""fresh_ground_bench.py - the field of the floor work `fresh_ground` (hall ML_Evolution), tried before it was built.
The rule is the tutorial's own (doc/book/studies/ml-environment/population.gd): its constants are READ from that file.
An 8 x 8 field; a body wanders, a cell that is available pays the first body on it and is then gone (finite) or comes
back after RENEW_SECONDS (returns); energy drains; over THRESHOLD a body halves its energy into a child with a
slightly different speed; at most LIMIT bodies.

The floor adds one thing: a visitor, a metre a cell, who is the thirteenth body of the model's list (after the twelve
founders, before any child) and is put where the visitor stands before each step; the same loop pays, drains and
divides it. This bench cannot replay Godot's random numbers, so it reports what many
seeds do, not one run:

  python tools/probes/fresh_ground_bench.py

  finite / returns, with nobody walking: when the ground is bare, when the last body stops, how many live at 60 s;
  the same with a visitor mowing the field at 1.2 m/s from the first second: what the visitor's eating does to the
  others, how long the visitor's own energy lasts, and how many children the visitor has.
"""
import math
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
text = (ROOT / 'doc/book/studies/ml-environment/population.gd').read_text(encoding='utf-8')


def const(name):
    return float(re.search(r'const %s := ([0-9.]+)(?: / ([0-9.]+))?' % name, text).group(1)) / float(re.search(r'const %s := ([0-9.]+)(?: / ([0-9.]+))?' % name, text).group(2) or 1)


DT, SIDE, LIMIT = const('DT'), int(const('SIDE')), int(const('LIMIT'))
REWARD, DRAIN, THRESHOLD, RENEW = const('REWARD'), const('DRAIN'), const('THRESHOLD'), const('RENEW_SECONDS')
METRES = SIDE / 2.0          # the model's -1..1 is the field's -4..4 m: a metre a cell


def cell(p):
    x = min(SIDE - 1, max(0, int((p[0] + 1.0) * 0.5 * SIDE)))
    z = min(SIDE - 1, max(0, int((p[1] + 1.0) * 0.5 * SIDE)))
    return z * SIDE + x


def wrap(v):
    return (v + 1.0) % 2.0 - 1.0


def run(seed, renew, visitor, seconds=60.0, barren=False, still=False):
    rng = random.Random(seed)
    ready = [math.inf if barren else 0.0] * (SIDE * SIDE)
    bodies = []
    for i in range(12):
        bodies.append({"p": [rng.uniform(-0.8, 0.8), rng.uniform(-0.8, 0.8)], "a": rng.uniform(-math.pi, math.pi), "speed": rng.uniform(0.1, 0.4), "energy": 1.5, "mine": False, "visitor": False})
    me = {"alive": visitor, "children": 0, "stopped_at": None}
    if visitor:
        # the thirteenth body of the list: after the founders, before any child
        bodies.append({"p": [0.0, 0.0], "a": 0.0, "speed": 0.3, "energy": 1.5, "mine": True, "visitor": True})
    out = {"bare_at": None, "last_stops": None, "most": 12}
    ticks = 0
    while ticks * DT < seconds:
        ticks += 1
        t = ticks * DT
        survivors = []
        for b in bodies:
            if b["visitor"]:
                # put where the visitor stands: mowing rows a metre apart at 1.2 m/s from the south-west corner, or
                # standing still on one panel
                walked = 0.0 if still else 1.2 * t
                row = int(walked // (SIDE - 1.0)) % SIDE
                along = walked % (SIDE - 1.0)
                x = -METRES + 0.5 + (along if row % 2 == 0 else (SIDE - 1.0) - along)
                z = METRES - 0.5 - row
                b["p"] = [x / METRES, z / METRES]
            else:
                b["a"] += rng.uniform(-0.25, 0.25)
                b["p"] = [wrap(b["p"][0] + math.cos(b["a"]) * b["speed"] * DT), wrap(b["p"][1] + math.sin(b["a"]) * b["speed"] * DT)]
            index = cell(b["p"])
            if t >= ready[index]:
                b["energy"] += REWARD
                ready[index] = t + RENEW if renew else math.inf
            b["energy"] -= DRAIN * DT
            if b["energy"] > 0.0:
                survivors.append(b)
            elif b["visitor"]:
                me["alive"] = False
                me["stopped_at"] = t
        children = []
        for parent in survivors:
            if parent["energy"] > THRESHOLD and len(survivors) + len(children) < LIMIT:
                parent["energy"] *= 0.5
                if parent["visitor"]:
                    me["children"] += 1
                children.append({"p": list(parent["p"]), "a": rng.uniform(-math.pi, math.pi), "speed": min(0.6, max(0.05, parent["speed"] + rng.uniform(-0.05, 0.05))), "energy": parent["energy"], "mine": parent["mine"], "visitor": False})
        bodies = survivors + children
        out["most"] = max(out["most"], len(bodies))
        if out["bare_at"] is None and all(t < r for r in ready):
            out["bare_at"] = t
        if out["last_stops"] is None and not bodies:
            out["last_stops"] = t
    out["alive_at_end"] = len(bodies)
    out["mine_at_end"] = sum(1 for b in bodies if b["mine"] and not b["visitor"])
    out["me"] = me
    return out


def mid(values):
    values = sorted(v for v in values if v is not None)
    return values[len(values) // 2] if values else None


if __name__ == '__main__':
    print('the tutorial\'s constants: a field %d x %d, at most %d bodies; a cell pays %.1f, energy drains %.2f a second, a child over %.1f; ground returns after %.0f s' % (SIDE, SIDE, LIMIT, REWARD, DRAIN, THRESHOLD, RENEW))
    seeds = range(1, 41)
    for label, renew, barren in (('finite ', False, False), ('returns', True, False), ('barren ', False, True)):
        for visitor, still in ((False, False), (True, False), (True, True)):
            runs = [run(s, renew, visitor, barren=barren, still=still) for s in seeds]
            bare = mid(r["bare_at"] for r in runs)
            last = mid(r["last_stops"] for r in runs)
            line = '%s %s: most alive %d (median); ground bare at %s; the last body stops at %s; alive at 60 s: %d' % (
                label, ('a visitor standing still' if still else 'a visitor mowing        ') if visitor else 'nobody walking          ', mid(r["most"] for r in runs),
                '%.0f s' % bare if bare else 'never', '%.0f s' % last if last else 'never (in 60 s)', mid(r["alive_at_end"] for r in runs))
            if visitor:
                stopped = mid(r["me"]["stopped_at"] for r in runs)
                line += '; the visitor: %d children, energy gone at %s' % (mid(r["me"]["children"] for r in runs), '%.0f s' % stopped if stopped else 'never (in 60 s)')
            print(line)
