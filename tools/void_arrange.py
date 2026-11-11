#!/usr/bin/env python3
"""A FLOOR OF THE VOID AS A MATHEMATICAL PROBLEM (Palle, 2026-11-11: "footprint and direction, flocking, game of
life, pathfinding in between objects - the spaced objects are like upside down trees, with different size trunks").

In the engine a floor already is numbers; this writes the WISH as numbers too, as far as it is known, and searches.

  the tree      every work is a TRUNK (its measured footprint, moved with it) under a CROWN: the room it needs - a
                margin that grows with the trunk, and an APRON in front, the way it faces, where a visitor stands.
                Crowns keep off each other, as trees do; a trunk in another's apron stands in its light.
  flocking      separation: overlapping crowns push apart, a little each, until they settle (pinned works do not
                move); cohesion: neighbours on the timeline stay within reach; a weak pull home (minimal change).
  pathfinding   a 0.5 m walk grid, blocked by trunks, columns, shafts, props and walls. Every apron must be reachable
                from the spawn point, and the walking distance to each work should follow the order of the timeline.
  sight         rays from the spawn point (1.6 m, a 120 degree cone): nothing in the face, the first work and the
                biggest work visible, no bare cone.
  life          afterwards, a neighbour count on a 3 m density grid, as in the game of life: a work with no
                neighbours is LONELY (stage it), a full cell among full cells is CROWDED (thin or fold), a block of
                empty cells in view is BARE (a family, a bigger scale). These are only printed.

    python tools/void_arrange.py 79,80,84 [--plans=ada_run/arrange] [--json=ada_run/arrange/report.json]
                                          [--moves=ada_run/arrange/moves.json] [--max-moves=6]

It moves POSITIONS only (no facing, scale or height), few works and as little as possible, and it writes nothing into
rooms.json: `--moves` writes a decisions file for `tools/void_fit.py apply`. It is a proposal - boxes, not bodies: a
hall or a ground (a box of 60 m2 or more) is neither an obstacle nor moved, and what is inside it stays with it. The
picture from the spawn point (tools/blender/ada_void/arrival.py) and the game judge the result.
"""
from __future__ import annotations

import heapq
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import void_arrival_worklist as wl  # noqa: E402

CELL = 0.5                 # the walk grid
BODY = 0.3                 # half a body: obstacles are inflated by this
TALL = 1.2                 # from here up a thing hides what stands behind it
WEIGHT = {"inside": 200, "hard": 40, "pivot": 100, "face": 5, "light": 4, "crowns": 0.5, "apron": 2, "reach": 30,
          "order": 20, "hero": 12, "first": 8, "bare": 10, "cohesion": 0.5, "moved": 3, "metres": 0.6}
FRONT = {0: (0.0, 1.0), 90: (1.0, 0.0), 180: (0.0, -1.0), 270: (-1.0, 0.0)}


def inter(a, b) -> float:
    w, d = min(a[2], b[2]) - max(a[0], b[0]), min(a[3], b[3]) - max(a[1], b[1])
    return w * d if w > 0 and d > 0 else 0.0


def area(r) -> float:
    return max(0.0, r[2] - r[0]) * max(0.0, r[3] - r[1])


def grow(r, m):
    return (r[0] - m, r[1] - m, r[2] + m, r[3] + m)


class Floor:
    def __init__(self, index: int, record: dict, frame: dict, catalog: dict, meas: dict, order: list):
        self.i, self.map = index, record.get("map")
        self.W, self.D = frame["width"] / 2, frame["depth"] / 2
        sp = (frame.get("spawn_points") or {}).get(str(index), [0, 0.06, 7.8])
        self.spawn = (float(sp[0]), float(sp[2]))
        n = math.hypot(*self.spawn) or 1.0
        self.fwd = (-self.spawn[0] / n, -self.spawn[1] / n)
        cols = (frame.get("floor_columns") or {}).get(str(index), {"x": frame["column_x"], "z": frame["column_z"]})
        cw = frame["column_width"] / 2
        self.fixed = [("shaft " + s["name"], (s["x"] - frame["shaft_width"] / 2, -frame["shaft_depth"] / 2, s["x"] + frame["shaft_width"] / 2, frame["shaft_depth"] / 2), 0.0, True) for s in frame["shafts"]]
        self.fixed += [("column", (x - cw, z - cw, x + cw, z + cw), 6.0, True) for x in cols["x"] for z in cols["z"]]
        self.protected = [(-6.6, 3.9, -5.4, 5.1)] + [(x, z, x + 1.0, z + 1.0) for x, z in record.get("impact_cells") or []]
        works, blockers = wl.boxes(record, catalog, meas)
        for b in blockers:      # props and walls: staging, it does not move here
            if not b[0].startswith("work "):
                self.fixed.append((b[0], tuple(b[1:5]), float(b[5]), False))
        rank = {k: n for n, k in enumerate(order)}
        rows = {a["id"]: a for a in record.get("artifacts", []) + record.get("copies", [])}
        self.works = []
        for (wid, key, x0, z0, x1, z1, top, measured) in works:
            a = rows[wid]
            px, pz = a["position"]
            w = {"id": wid, "key": key, "off": (x0 - px, z0 - pz, x1 - px, z1 - pz), "top": float(top), "measured": measured,
                 "front": FRONT.get(int(a.get("facing", 0)) % 360), "rank": rank.get(key), "home": (float(px), float(pz))}
            mid = ((x0 + x1) / 2, (z0 + z1) / 2)
            w["enclosure"] = area(w["off"]) >= wl.ENCLOSURE or abs(mid[0]) > self.W or abs(mid[1]) > self.D      # or an exterior bay
            self.works.append(w)
        rooms = [self.trunk(w, w["home"]) for w in self.works if w["enclosure"]]
        copies = {}      # a set of copies is one composition (the maze panels round shaft B on floor 81): not pulled apart
        for w in self.works:
            copies[w["key"]] = copies.get(w["key"], 0) + 1
        for w in self.works:
            t = self.trunk(w, w["home"])
            cx, cz = (t[0] + t[2]) / 2, (t[1] + t[3]) / 2
            guest = any(r[0] < cx < r[2] and r[1] < cz < r[3] for r in rooms) and not w["enclosure"]
            in_shaft = any(inter(t, f[1]) > 0.3 * area(t) for f in self.fixed if f[3] and f[0].startswith("shaft"))
            w["pinned"] = "a hall or a ground" if w["enclosure"] else "inside a hall or a ground" if guest else \
                "not measured" if not w["measured"] else "stands in a shaft on purpose" if in_shaft else \
                "one of a set of %d" % copies[w["key"]] if copies[w["key"]] >= 2 else ""
            w["guest"] = guest
        self.nx, self.nz = int(2 * self.W / CELL), int(2 * self.D / CELL)
        self.static = bytearray(self.nx * self.nz)
        for _, r, top, hole in self.fixed:
            if hole or top > 0.4:
                self.block(self.static, grow(r, BODY))

    # ---- the tree: trunk, crown, apron ---------------------------------------------------------------------------
    def trunk(self, w, p):
        o = w["off"]
        return (p[0] + o[0], p[1] + o[1], p[0] + o[2], p[1] + o[3])

    def margin(self, w) -> float:
        o = w["off"]
        return min(1.0, max(0.4, 0.2 * max(o[2] - o[0], o[3] - o[1])))

    def apron(self, w, p):
        """the room in front, the way the work faces: as deep as the face is big (1.2 to 3.5 m)"""
        if not w["front"] or w["enclosure"]:
            return None
        t, (fx, fz) = self.trunk(w, p), w["front"]
        face = (t[2] - t[0]) if fx == 0 else (t[3] - t[1])
        deep = min(3.5, max(1.2, 0.9 * max(face, min(w["top"], 3.0))))
        if fz > 0:
            return (t[0], t[3], t[2], t[3] + deep)
        if fz < 0:
            return (t[0], t[1] - deep, t[2], t[1])
        if fx > 0:
            return (t[2], t[1], t[2] + deep, t[3])
        return (t[0] - deep, t[1], t[0], t[3])

    def crown(self, w, p):
        c = grow(self.trunk(w, p), self.margin(w))
        a = self.apron(w, p)
        return (min(c[0], a[0]), min(c[1], a[1]), max(c[2], a[2]), max(c[3], a[3])) if a else c

    def approach(self, w, p):
        t = self.trunk(w, p)
        cx, cz = (t[0] + t[2]) / 2, (t[1] + t[3]) / 2
        if not w["front"]:
            return (cx, cz)
        fx, fz = w["front"]
        return (cx + fx * ((t[2] - t[0]) / 2 + 0.8), cz + fz * ((t[3] - t[1]) / 2 + 0.8))

    # ---- pathfinding ---------------------------------------------------------------------------------------------
    def cell(self, x, z):
        return int((x + self.W) / CELL), int((z + self.D) / CELL)

    def block(self, grid, r):
        i0, k0 = self.cell(r[0] + CELL / 2, r[1] + CELL / 2)
        i1, k1 = self.cell(r[2] - CELL / 2, r[3] - CELL / 2)
        for k in range(max(0, k0), min(self.nz - 1, k1) + 1):
            for i in range(max(0, i0), min(self.nx - 1, i1) + 1):
                grid[k * self.nx + i] = 1

    def free_near(self, grid, x, z, reach=1.5):
        i, k = self.cell(x, z)
        best = None
        r = int(reach / CELL)
        for dk in range(-r, r + 1):
            for di in range(-r, r + 1):
                a, b = i + di, k + dk
                if 0 <= a < self.nx and 0 <= b < self.nz and not grid[b * self.nx + a]:
                    d = di * di + dk * dk
                    if best is None or d < best[0]:
                        best = (d, a, b)
        return (best[1], best[2]) if best else None

    def walk(self, state):
        """walking distance from the spawn point to every free cell (Dijkstra, eight neighbours)"""
        grid = bytearray(self.static)
        for w in self.works:
            if not w["enclosure"] and w["top"] > 0.4:
                self.block(grid, grow(self.trunk(w, state[w["id"]]), BODY))
        start = self.free_near(grid, *self.spawn)
        dist = {}
        if start:
            heap = [(0.0, start[0], start[1])]
            dist[start] = 0.0
            while heap:
                d, i, k = heapq.heappop(heap)
                if d > dist.get((i, k), 1e9):
                    continue
                for di, dk, c in ((1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1), (1, 1, 1.414), (1, -1, 1.414), (-1, 1, 1.414), (-1, -1, 1.414)):
                    a, b = i + di, k + dk
                    if 0 <= a < self.nx and 0 <= b < self.nz and not grid[b * self.nx + a]:
                        nd = d + c * CELL
                        if nd < dist.get((a, b), 1e9):
                            dist[(a, b)] = nd
                            heapq.heappush(heap, (nd, a, b))
        out = {}
        for w in self.works:
            c = self.free_near(grid, *self.approach(w, state[w["id"]]))
            out[w["id"]] = dist.get(c, math.inf) if c else math.inf
        return out

    # ---- sight ---------------------------------------------------------------------------------------------------
    def sight(self, state):
        """-> (share of each work's own width that is seen, share of the middle cone that sees nothing within 18 m)"""
        sx, sz = self.spawn
        things = [(w["id"], self.trunk(w, state[w["id"]]), w["top"]) for w in self.works]
        things += [(n, r, top) for n, r, top, hole in self.fixed if not hole and top > 0.4]
        things = [t for t in things if not (t[1][0] < sx < t[1][2] and t[1][1] < sz < t[1][3])]      # not from inside it
        seen, alone = {}, {}
        bare = middle = 0
        base = math.atan2(self.fwd[1], self.fwd[0])
        for step in range(-60, 61):
            a = base + math.radians(step)
            dx, dz = math.cos(a), math.sin(a)
            hits = []
            for name, r, top in things:
                t0, t1 = 0.0, 30.0
                for o, d, lo, hi in ((sx, dx, r[0], r[2]), (sz, dz, r[1], r[3])):
                    if abs(d) < 1e-9:
                        if not lo <= o <= hi:
                            t0 = 1e9
                        continue
                    ta, tb = (lo - o) / d, (hi - o) / d
                    t0, t1 = max(t0, min(ta, tb)), min(t1, max(ta, tb))
                if t0 <= t1:
                    hits.append((t0, name, top))
            hidden, any_seen = 0.0, False
            for t0, name, top in sorted(hits):
                alone[name] = alone.get(name, 0) + 1
                if top > hidden + (0.5 if hidden else 0.0):
                    seen[name] = seen.get(name, 0) + 1
                    any_seen = any_seen or t0 <= 18.0
                if top >= TALL:
                    hidden = max(hidden, top)
            if abs(step) <= 35:
                middle += 1
                bare += 0 if any_seen else 1
        return {n: seen.get(n, 0) / c for n, c in alone.items()}, bare / max(1, middle)

    # ---- the wish, as one number ---------------------------------------------------------------------------------
    def cheap(self, state) -> dict:
        c = dict.fromkeys(WEIGHT, 0.0)
        sx, sz = self.spawn
        slab = (-self.W, -self.D, self.W, self.D)
        live = [w for w in self.works if not w["enclosure"] and not w["guest"]]
        trunks = {w["id"]: self.trunk(w, state[w["id"]]) for w in live}
        for w in live:
            t, p = trunks[w["id"]], state[w["id"]]
            if t[0] < sx < t[2] and t[1] < sz < t[3] and w["top"] > 0.3:
                c["inside"] += 1
            c["hard"] += area(t) - inter(t, slab) + sum(inter(t, f[1]) for f in self.fixed if f[3] or f[2] > 0.4) + sum(inter(t, r) for r in self.protected)
            foot = (p[0] - 0.65, p[1] - 0.65, p[0] + 0.65, p[1] + 0.65)      # the validator's access footprint
            if inter(foot, slab) < area(foot) - 1e-6 or any(inter(foot, f[1]) > 0 for f in self.fixed if f[3]) or any(inter(foot, r) > 0 for r in self.protected):
                c["pivot"] += 1
            a = self.apron(w, p)
            if a:
                c["apron"] += area(a) - inter(a, slab) + sum(inter(a, f[1]) for f in self.fixed if f[3] and f[0].startswith("shaft"))
            if w["top"] > 0.8:
                for n in range(14):
                    for u in (-0.5, -0.25, 0.0, 0.25, 0.5):
                        t_ = 0.4 + 0.2 * n
                        x, z = sx + self.fwd[0] * t_ - self.fwd[1] * u, sz + self.fwd[1] * t_ + self.fwd[0] * u
                        if t[0] <= x <= t[2] and t[1] <= z <= t[3]:
                            c["face"] += 1
            d = math.hypot(p[0] - w["home"][0], p[1] - w["home"][1])
            if d > 0.05:
                c["moved"] += 1
                c["metres"] += d
        for n, a in enumerate(live):
            ca, pa = self.crown(a, state[a["id"]]), (state[a["id"]][0] - 0.65, state[a["id"]][1] - 0.65, state[a["id"]][0] + 0.65, state[a["id"]][1] + 0.65)
            for b in live[n + 1:]:
                cb = self.crown(b, state[b["id"]])
                c["hard"] += inter(trunks[a["id"]], trunks[b["id"]])
                c["light"] += inter(ca, trunks[b["id"]]) + inter(cb, trunks[a["id"]]) - 2 * inter(trunks[a["id"]], trunks[b["id"]])
                c["crowns"] += inter(ca, cb)
                pb = (state[b["id"]][0] - 0.65, state[b["id"]][1] - 0.65, state[b["id"]][0] + 0.65, state[b["id"]][1] + 0.65)
                if inter(pa, pb) > 0:
                    c["pivot"] += 1
        return c

    def cost(self, state, full=True) -> dict:
        c = self.cheap(state)
        if full:
            walk = self.walk(state)
            frac, bare = self.sight(state)
            c["reach"] = sum(1 for w in self.works if not w["enclosure"] and not w["guest"] and walk[w["id"]] == math.inf)
            c["bare"] = bare
            keys = {}
            for w in self.works:
                if w["rank"] is not None and walk[w["id"]] < math.inf:
                    keys[w["rank"]] = min(keys.get(w["rank"], math.inf), walk[w["id"]])
            ranks = sorted(keys)
            rho = 1.0
            if len(ranks) >= 3:
                by_dist = sorted(ranks, key=lambda r: keys[r])
                n = len(ranks)
                rho = 1 - 6 * sum((ranks.index(r) - by_dist.index(r)) ** 2 for r in ranks) / (n * (n * n - 1))
            c["order"] = (1 - rho) / 2
            c["_rho"] = rho
            sized = [w for w in self.works if w["measured"]]
            if sized:
                def vol(w):
                    o = w["off"]
                    return min(o[2] - o[0], 20) * min(o[3] - o[1], 20) * min(max(w["top"], 0.2), 6)
                hero = max(sized, key=vol)
                t = self.trunk(hero, state[hero["id"]])
                around = t[0] < self.spawn[0] < t[2] and t[1] < self.spawn[1] < t[3]
                c["hero"] = 0.0 if around else 1 - frac.get(hero["id"], 0.0)
                c["_hero"] = hero["key"]
            firsts = [w for w in self.works if w["rank"] is not None]
            if firsts:
                r0 = min(w["rank"] for w in firsts)
                c["first"] = 1 - min(1.0, max(frac.get(w["id"], 0.0) for w in firsts if w["rank"] == r0) / 0.5)
            cent = {}
            for w in self.works:
                if w["rank"] is not None:
                    t = self.trunk(w, state[w["id"]])
                    cent.setdefault(w["rank"], []).append(((t[0] + t[2]) / 2, (t[1] + t[3]) / 2))
            rs = sorted(cent)
            for a, b in zip(rs, rs[1:]):
                d = min(math.hypot(p[0] - q[0], p[1] - q[1]) for p in cent[a] for q in cent[b])
                c["cohesion"] += max(0.0, d - 9.0)
            c["_walk"], c["_seen"] = walk, frac
        c["total"] = sum(WEIGHT[k] * c[k] for k in WEIGHT)
        return c

    # ---- the search ----------------------------------------------------------------------------------------------
    def legal(self, w, p, state) -> bool:
        t = self.trunk(w, p)
        if t[0] < -self.W or t[2] > self.W or t[1] < -self.D or t[3] > self.D:
            return False
        if any(inter(t, f[1]) > 0.02 for f in self.fixed if f[3] or f[2] > 0.4) or any(inter(t, r) > 0 for r in self.protected):
            return False
        if t[0] - 0.4 < self.spawn[0] < t[2] + 0.4 and t[1] - 0.4 < self.spawn[1] < t[3] + 0.4:
            return False
        for v in self.works:      # not into another trunk, and not into a hall or a ground: its inside is its own
            if v is not w and not v["guest"] and inter(t, self.trunk(v, state[v["id"]])) > 0.02:
                return False
        return True

    def settle(self, state, rounds=40) -> dict:
        """flocking's separation: crowns that overlap push each other apart, half each; pinned works do not move"""
        s = dict(state)
        live = [w for w in self.works if not w["enclosure"] and not w["guest"]]
        for _ in range(rounds):
            push = {w["id"]: [0.0, 0.0] for w in live}
            for n, a in enumerate(live):
                for b in live[n + 1:]:
                    ca, cb = self.crown(a, s[a["id"]]), self.crown(b, s[b["id"]])
                    ox, oz = min(ca[2], cb[2]) - max(ca[0], cb[0]), min(ca[3], cb[3]) - max(ca[1], cb[1])
                    if ox <= 0 or oz <= 0:
                        continue
                    axis = 0 if ox < oz else 1
                    sign = 1.0 if (ca[axis] + ca[axis + 2]) < (cb[axis] + cb[axis + 2]) else -1.0
                    amount = min(ox, oz) / 2
                    if not a["pinned"]:
                        push[a["id"]][axis] -= sign * amount * (1.0 if b["pinned"] else 0.5)
                    if not b["pinned"]:
                        push[b["id"]][axis] += sign * amount * (1.0 if a["pinned"] else 0.5)
            moved = 0.0
            for w in live:
                dx, dz = push[w["id"]]
                dx, dz = max(-0.5, min(0.5, dx)) + 0.02 * (w["home"][0] - s[w["id"]][0]), max(-0.5, min(0.5, dz)) + 0.02 * (w["home"][1] - s[w["id"]][1])
                p = (round(s[w["id"]][0] + dx, 2), round(s[w["id"]][1] + dz, 2))
                if (abs(dx) > 0.01 or abs(dz) > 0.01) and self.legal(w, p, s):
                    s[w["id"]] = p
                    moved += abs(dx) + abs(dz)
            if moved < 0.05:
                break
        return s

    def candidates(self, w, state) -> list:
        o, here = w["off"], state[w["id"]]
        out = [(here[0] + dx, here[1] + dz) for d in (1.0, 2.0, 3.0) for dx, dz in ((d, 0), (-d, 0), (0, d), (0, -d))]
        x = -self.W + 1.0
        while x <= self.W - 1.0:
            z = -self.D + 1.0
            while z <= self.D - 1.0:
                out.append((x - (o[0] + o[2]) / 2, z - (o[1] + o[3]) / 2))      # the box's middle on a 2 m lattice
                z += 2.0
            x += 2.0
        return [(round(a, 2), round(b, 2)) for a, b in out]

    def shortlist(self, state, movable, most=14) -> list:
        """on a crowded floor only the works that carry blame are tried: those in a fault, the biggest, and one
        placement of each timeline row (floor 82 has 48 copies of one work)"""
        if len(movable) <= most:
            return movable
        sx, sz = self.spawn
        slab = (-self.W, -self.D, self.W, self.D)
        trunks = {w["id"]: self.trunk(w, state[w["id"]]) for w in self.works}

        def blame(w):
            t = trunks[w["id"]]
            b = 200.0 if (t[0] < sx < t[2] and t[1] < sz < t[3] and w["top"] > 0.3) else 0.0
            b += 40 * (area(t) - inter(t, slab) + sum(inter(t, f[1]) for f in self.fixed if f[3] or f[2] > 0.4))
            b += 40 * sum(inter(t, trunks[v["id"]]) for v in self.works if v is not w and not v["enclosure"] and not v["guest"])
            if w["top"] > 0.8 and inter(t, (sx - 1.0, sz - 3.2, sx + 1.0, sz + 3.2)) > 0:
                b += 50
            return b
        ranked = sorted((w for w in movable if blame(w) > 0), key=blame, reverse=True)[:most - 4]
        keep = {w["id"] for w in ranked}
        biggest = max(movable, key=lambda w: area(w["off"]) * min(max(w["top"], 0.2), 6))
        keep.add(biggest["id"])
        seen_rank = set()
        for w in sorted(movable, key=lambda w: (w["rank"] is None, w["rank"] or 0, math.hypot(state[w["id"]][0] - sx, state[w["id"]][1] - sz))):
            if len(keep) >= most:
                break
            if w["rank"] is not None and w["rank"] not in seen_rank:
                seen_rank.add(w["rank"])
                keep.add(w["id"])
        return [w for w in movable if w["id"] in keep]

    def arrange(self, max_moves=6) -> tuple:
        home = {w["id"]: w["home"] for w in self.works}
        before = self.cost(home)
        state, now, log = dict(home), before, []
        movable = self.shortlist(state, [w for w in self.works if not w["pinned"]])
        relaxed = self.settle(state)
        c = self.cost(relaxed)
        if c["total"] < now["total"] - 0.5:
            state, now = relaxed, c
            log.append({"move": "settle", "total": round(c["total"], 2)})
        for _ in range(max_moves):
            best = None
            for w in movable:
                trial = dict(state)
                options = [(p, None) for p in self.candidates(w, state)]
                for v in movable:           # or change places with another work (box middle for box middle)
                    if v is not w:
                        tw, tv = self.trunk(w, state[w["id"]]), self.trunk(v, state[v["id"]])
                        mw, mv = ((tw[0] + tw[2]) / 2, (tw[1] + tw[3]) / 2), ((tv[0] + tv[2]) / 2, (tv[1] + tv[3]) / 2)
                        pw = (round(state[w["id"]][0] + mv[0] - mw[0], 2), round(state[w["id"]][1] + mv[1] - mw[1], 2))
                        pv = (round(state[v["id"]][0] + mw[0] - mv[0], 2), round(state[v["id"]][1] + mw[1] - mv[1], 2))
                        options.append((pw, (v, pv)))
                for p, swap in options:
                    trial[w["id"]] = p
                    if swap:
                        trial[swap[0]["id"]] = swap[1]
                    ok = self.legal(w, p, trial) and (not swap or self.legal(swap[0], swap[1], trial))
                    if ok:
                        quick = self.cost(trial, full=False)["total"]
                        # the walk and the sight lines are the dear part: only where the cheap part leaves room to win
                        if quick < now["total"] + 1e-6:
                            c = self.cost(trial)
                            if c["total"] < (best[0]["total"] if best else now["total"] - 0.5):
                                best = (c, dict(trial), w, swap)
                    trial[w["id"]] = state[w["id"]]
                    if swap:
                        trial[swap[0]["id"]] = state[swap[0]["id"]]
            if not best:
                break
            c, state, w, swap = best
            log.append({"move": w["id"] + (" <-> " + swap[0]["id"] if swap else ""), "total": round(c["total"], 2)})
            now = c
        return home, state, before, now, log

    # ---- life: a neighbour count on the density grid -----------------------------------------------------------
    def life(self, state) -> dict:
        size = 3.0
        nx, nz = int(2 * self.W / size), int(2 * self.D / size)
        cover = [[0.0] * nx for _ in range(nz)]
        boxes = [(w, self.trunk(w, state[w["id"]])) for w in self.works if not w["enclosure"]]
        solid = [t for _, t in boxes] + [f[1] for f in self.fixed if not f[3] and f[2] > 0.4]
        for k in range(nz):
            for i in range(nx):
                c = (-self.W + i * size, -self.D + k * size, -self.W + (i + 1) * size, -self.D + (k + 1) * size)
                cover[k][i] = min(1.0, sum(inter(c, t) for t in solid) / (size * size))
        alive = [[cover[k][i] >= 0.12 for i in range(nx)] for k in range(nz)]

        def near(i, k):
            return sum(1 for dk in (-1, 0, 1) for di in (-1, 0, 1) if (di or dk) and 0 <= i + di < nx and 0 <= k + dk < nz and alive[k + dk][i + di])
        lonely, crowded, bare = [], [], 0
        for w, t in boxes:
            i, k = min(nx - 1, max(0, int(((t[0] + t[2]) / 2 + self.W) / size))), min(nz - 1, max(0, int(((t[1] + t[3]) / 2 + self.D) / size)))
            n = near(i, k)
            if n == 0 and w["key"] not in lonely:
                lonely.append(w["key"])
            if n >= 6 and cover[k][i] >= 0.5 and w["key"] not in crowded:
                crowded.append(w["key"])
        holes = [f[1] for f in self.fixed if f[3] and f[0].startswith("shaft")]
        for k in range(nz):
            for i in range(nx):
                c = (-self.W + i * size, -self.D + k * size, -self.W + (i + 1) * size, -self.D + (k + 1) * size)
                if not alive[k][i] and near(i, k) == 0 and not any(inter(c, h) > 0 for h in holes):
                    bare += 1
        return {"lonely": lonely, "crowded": crowded, "bare_cells": bare, "cells": nx * nz, "alive": sum(map(sum, alive))}


def draw(fl: Floor, home: dict, state: dict, before: dict, after: dict, path: Path) -> None:
    from PIL import Image, ImageDraw
    S, pad = 26, 30
    w, h = int(2 * fl.W * S) + 2 * pad, int(2 * fl.D * S) + 2 * pad + 22
    img = Image.new("RGB", (w, 2 * h), (244, 242, 238))
    d = ImageDraw.Draw(img)

    def panel(top, st, c, title):
        def px(x, z):
            return (pad + (x + fl.W) * S, top + 22 + pad + (z + fl.D) * S)

        def box(r, **kw):
            d.rectangle([px(r[0], r[1]), px(r[2], r[3])], **kw)
        d.text((pad, top + 6), title, fill=(30, 28, 25))
        box((-fl.W, -fl.D, fl.W, fl.D), fill=(232, 229, 222), outline=(120, 114, 104))
        for name, r, top_, hole in fl.fixed:
            box(r, fill=(250, 250, 250) if name.startswith("shaft") else (150, 144, 134) if name == "column" else (196, 186, 166), outline=(120, 114, 104))
        for w_ in fl.works:
            a = fl.apron(w_, st[w_["id"]])
            if a and not w_["guest"]:
                box(a, outline=(196, 160, 90))
        for w_ in sorted(fl.works, key=lambda x: -area(x["off"])):
            t = fl.trunk(w_, st[w_["id"]])
            moved = math.hypot(st[w_["id"]][0] - w_["home"][0], st[w_["id"]][1] - w_["home"][1]) > 0.05
            fill = None if w_["enclosure"] else (176, 69, 122) if moved else (120, 142, 168) if not w_["pinned"] else (168, 168, 160)
            box(t, fill=fill, outline=(60, 56, 50))
            if moved:
                d.line([px(*w_["home"]), px(*st[w_["id"]])], fill=(176, 69, 122), width=2)
            if w_["rank"] is not None:
                d.text(px((t[0] + t[2]) / 2 - 0.2, (t[1] + t[3]) / 2 - 0.25), str(w_["rank"] + 1), fill=(255, 255, 255) if fill else (30, 28, 25))
        sx, sz = fl.spawn
        base = math.atan2(fl.fwd[1], fl.fwd[0])
        for a in (-60, 60):
            d.line([px(sx, sz), px(sx + 9 * math.cos(base + math.radians(a)), sz + 9 * math.sin(base + math.radians(a)))], fill=(46, 125, 91), width=1)
        d.ellipse([px(sx - 0.3, sz - 0.3), px(sx + 0.3, sz + 0.3)], fill=(46, 125, 91))
        parts = ", ".join(f"{k} {WEIGHT[k] * c[k]:.1f}" for k in WEIGHT if WEIGHT[k] * c[k] >= 0.05)
        d.text((pad, top + h - 16), f"cost {c['total']:.1f}: {parts}   order {c.get('_rho', 1):+.2f}   hero {c.get('_hero', '-')}", fill=(30, 28, 25))
    panel(0, home, before, f"floor {fl.i} {fl.map} - as it stands (green: the spawn point and its cone; numbers: timeline order; orange: aprons)")
    panel(h, state, after, f"floor {fl.i} {fl.map} - proposed (pink: moved)")
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def main() -> int:
    args = sys.argv[1:]
    floors = [int(x) for x in args[0].split(",")] if args and not args[0].startswith("--") else []
    opt = {a.split("=", 1)[0]: a.split("=", 1)[1] for a in args if a.startswith("--") and "=" in a}
    rooms = json.loads((ROOT / "commons/void/rooms.json").read_text(encoding="utf-8"))["floors"]
    frame = json.loads((ROOT / "commons/void/layout.json").read_text(encoding="utf-8"))
    catalog = json.loads((ROOT / "commons/void/catalog.json").read_text(encoding="utf-8"))["props"]
    timeline = json.loads((ROOT / "commons/data/artifact_timeline.json").read_text(encoding="utf-8"))
    by_floor = {}
    for r in timeline.get("main", []):
        if isinstance(r.get("floor"), int):
            by_floor.setdefault(r["floor"], []).append(r["key"])
    meas = wl.measured()
    report, decisions = [], []
    for i in floors:
        fl = Floor(i, rooms[i], frame, catalog, meas, by_floor.get(i, []))
        home, state, before, after, log = fl.arrange(int(opt.get("--max-moves", 6)))
        moves = []
        for w in fl.works:
            if math.hypot(state[w["id"]][0] - w["home"][0], state[w["id"]][1] - w["home"][1]) > 0.05:
                moves.append({"id": w["id"], "artifact": w["key"], "from": list(w["home"]), "to": list(state[w["id"]])})
                decisions.append({"map": fl.map, "id": w["id"], "set": {"position": list(state[w["id"]])},
                                  "note": f"2026-11-11 tools/void_arrange.py: cost {before['total']:.1f} -> {after['total']:.1f}"})
        row = {"floor": i, "map": fl.map, "works": len(fl.works), "pinned": {w["id"]: w["pinned"] for w in fl.works if w["pinned"]},
               "before": {k: round(WEIGHT[k] * before[k], 2) for k in WEIGHT} | {"total": round(before["total"], 2), "order_rho": round(before.get("_rho", 1), 2)},
               "after": {k: round(WEIGHT[k] * after[k], 2) for k in WEIGHT} | {"total": round(after["total"], 2), "order_rho": round(after.get("_rho", 1), 2)},
               "hero": after.get("_hero"), "moves": moves, "log": log, "life": fl.life(state)}
        report.append(row)
        if "--plans" in opt:
            draw(fl, home, state, before, after, ROOT / opt["--plans"] / f"plan_{i}.png")
        gone = ", ".join(f"{k} {row['before'][k]:.0f}->{row['after'][k]:.0f}" for k in WEIGHT if abs(row["before"][k] - row["after"][k]) >= 0.5)
        print(f"floor {i} {fl.map}: cost {before['total']:.1f} -> {after['total']:.1f}, {len(moves)} of {len(fl.works)} works moved"
              + (f" ({gone})" if gone else "") + f"; life: {len(row['life']['lonely'])} lonely, {len(row['life']['crowded'])} crowded, {row['life']['bare_cells']} bare cells", flush=True)
        for m in moves:
            print(f"    {m['artifact']} ({m['from'][0]:g}, {m['from'][1]:g}) -> ({m['to'][0]:g}, {m['to'][1]:g})", flush=True)
    for key, data in (("--json", report), ("--moves", decisions)):
        if key in opt:
            out = ROOT / opt[key]
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
