"""track_compose.py — couple a route of sections into a map (P-10 + P-10a).

The train was the coupling, not the line (L-024): sections keep their
contracts, slots and bodies, and the router lays them as a FOLDED ROUTE on
the grid — 90-degree corner turns at a cadence (a corner is a cut), the
climax as a PLAZA discovered around the fold rather than a hall sighted from
the start. Trains are sampled from the grammar mined off the composed
corridors; the walk-order grammar survives the fold untouched.

Judged as before: pathfinder gate, experience fitness, FIT against the
text-compiled desire target. Champion -> commons/maps/Track_<Map>/ with the
route (sections + turns) in the manifest.

  python tools/track_compose.py --map Point_Lines --seeds 6
  python tools/track_compose.py --seeds 6            # whole script file
"""
import argparse
import json
import os
import random
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import desire_timeline as dt  # noqa: E402
import script_compose as sc  # noqa: E402
from map_tournament import experience_score, run  # noqa: E402

KIT = json.load(open(os.path.join(ROOT, "commons", "data", "track_sections.json"), encoding="utf-8"))
GRAMMAR = json.load(open(os.path.join(ROOT, "commons", "data", "track_grammar.json"), encoding="utf-8"))
WIDTH = KIT["width"]
LANES = KIT["lanes"]
SEC = {s["id"]: s for s in KIT["sections"]}
BY_CAT = {}
for s in KIT["sections"]:
    if "register" not in s and not s.get("authored"):
        BY_CAT.setdefault(s["mined_as"], []).append(s)

CORNER_CADENCE = 3  # a cut every ~3 cars, alternating sides


def lane_u(lane):
    xs = LANES[lane]
    return xs[len(xs) // 2]


def vec_letter(v):
    return {(-1, 0): "w", (1, 0): "e", (0, -1): "n", (0, 1): "s"}[v]


def rot_cw(d):
    return (d[1], -d[0])


def rot_ccw(d):
    return (-d[1], d[0])


def sample_train(rng, n_sections):
    starts = GRAMMAR["starts"]
    cats = list(starts)
    cat = rng.choices(cats, weights=[starts[c] for c in cats])[0]
    train = [cat]
    while len(train) < n_sections:
        row = GRAMMAR["transitions"].get(cat)
        if not row:
            break
        nxt = list(row)
        cat = rng.choices(nxt, weights=[row[c] for c in nxt])[0]
        train.append(cat)
    return train


class Router:
    """Lays sections along a folded route: cursor + direction, 90-deg turns,
    collision-checked against everything already down."""

    def __init__(self):
        self.floor = {}    # (x,z) -> height str
        self.walls = {}    # (x,z) -> letters
        self.arts = {}     # (x,z) -> token
        self.pos = (0, 0)
        self.d = (0, 1)    # walking +z
        self.route = []

    def ru(self):
        return (self.d[1], -self.d[0])  # local u axis (across the walk)

    def cells_of(self, sec, pos, d):
        ru = (d[1], -d[0])
        w = 13 if sec["z_len"] == 13 and "13x13" in sec.get("profile", "") else WIDTH
        for v in range(sec["z_len"]):
            for u in range(w):
                yield (pos[0] + ru[0] * u + d[0] * v,
                       pos[1] + ru[1] * u + d[1] * v), u, v

    def collides(self, sec, pos, d):
        return any(c in self.floor for c, _, _ in self.cells_of(sec, pos, d))

    def place(self, sec, fills):
        """fills: list of (u, v, token) resolved by the caller."""
        pos, d, ru = self.pos, self.d, self.ru()
        body = sec.get("body", {})
        for c, u, v in self.cells_of(sec, pos, d):
            h = "1"
            if sec["id"] == "arrival_void" and not (5 <= u <= 7):
                h = "0"
            if sec["id"] == "shrunken_void" and not (3 <= u <= 9):
                h = "0"
            self.floor[c] = h
        for u, v, tok in fills:
            c = (pos[0] + ru[0] * u + d[0] * v, pos[1] + ru[1] * u + d[1] * v)
            self.arts[c] = tok
            if body.get("podiums") and self.floor.get(c) == "1":
                self.floor[c] = "2"
        wall = body.get("wall")
        sides = []
        if wall in ("left", "both"):
            sides.append((0, tuple(-x for x in ru)))
        if wall in ("right", "both"):
            sides.append((12, ru))
        if wall == "outer":
            sides = [(0, tuple(-x for x in ru)), (12, ru)]
        for u_edge, face in sides:
            for v in range(sec["z_len"]):
                c = (pos[0] + ru[0] * u_edge + d[0] * v, pos[1] + ru[1] * u_edge + d[1] * v)
                self.walls[c] = self.walls.get(c, "") + vec_letter(face)
        for pu, pv in body.get("pillars", []):
            c = (pos[0] + ru[0] * pu + d[0] * pv, pos[1] + ru[1] * pu + d[1] * pv)
            if self.floor.get(c) == "1":
                self.floor[c] = "3"
        self.route.append({"id": sec["id"], "pos": list(pos), "dir": list(d)})
        self.pos = (pos[0] + d[0] * sec["z_len"], pos[1] + d[1] * sec["z_len"])

    def try_corner(self, turn):
        """A corner is a 13x13 block; the walk enters, turns, exits the side."""
        sec = SEC["corner_turn"]
        pos, d = self.pos, self.d
        if self.collides(sec, pos, d):
            return False
        new_d = rot_cw(d) if turn == "R" else rot_ccw(d)
        ru = self.ru()
        # exit cursor: through the turned side, lanes running along the old d
        if turn == "R":
            # next leg couples on the corner's right face, lanes running back along -d
            exit_pos = (pos[0] + ru[0] * 13 + d[0] * 12, pos[1] + ru[1] * 13 + d[1] * 12)
        else:
            # next leg couples on the corner's LEFT face, lanes running along +d
            # (exit one cell left of the corner's first column, same entry row)
            exit_pos = (pos[0] - ru[0], pos[1] - ru[1])
        # tentatively check the NEXT breather placement from there too
        save = (self.pos, self.d)
        self.place(sec, [(6, 6, "")] if False else [])
        self.route[-1]["turn"] = turn
        self.pos, self.d = exit_pos, new_d
        if self.collides(SEC["breather"], self.pos, self.d):
            # cannot continue after the turn — accept anyway only if straight also dead
            pass
        return True


def compose(map_name, scripts, seeds):
    script = scripts["maps"][map_name]
    source, cast, exit_tok = sc.read_cast(map_name)
    for pin in script.get("pins", []):
        if not any(sc.base_of(t) == sc.base_of(pin) for t in cast):
            cast.append(pin)
    hero_i = sc.pick(cast, script["hero"])
    if hero_i is None:
        hero_i = max(range(len(cast)), key=lambda i: sc.size_of(cast[i]))
    counter_i = sc.pick(cast, script.get("counter", []), exclude=hero_i)
    rest = [i for i in range(len(cast)) if i not in (hero_i, counter_i)]
    target = sc.load_target(map_name)
    best = None
    cand = f"TrackCand_{map_name}"
    for seed in range(seeds):
        rng = random.Random(seed * 101 + 46)
        n = max(4, round(len(rest) / 2.2))
        cats = sample_train(rng, n)
        sections = []
        if script["register"] == "arrival":
            sections.append(SEC["arrival_void"])
        for c in cats:
            sections.append(rng.choice(BY_CAT.get(c, BY_CAT["side_bay"])))
        pos_climax = len(sections) if script["register"] == "close" else max(1, int(len(sections) * 0.72))
        sections.insert(pos_climax, SEC["vacuum_approach"])

        router = Router()
        queue = list(rest)
        turn_side = "R" if seed % 2 else "L"
        since_corner = 0
        placed_climax = False
        i_sec = 0
        all_secs = list(sections)
        while i_sec < len(all_secs) or queue or not placed_climax:
            if i_sec >= len(all_secs):
                if not placed_climax:
                    all_secs.append(SEC["climax_plaza"])
                else:
                    all_secs.append(SEC["podium_gallery"])
            sec = all_secs[i_sec]
            # the authored climax becomes the plaza, discovered after a fold
            if i_sec == pos_climax + 1 and not placed_climax:
                if router.try_corner(turn_side):
                    turn_side = "L" if turn_side == "R" else "R"
                    since_corner = 0
                sec = SEC["climax_plaza"]
                all_secs[i_sec] = sec
            # cadence corners between ordinary cars
            elif since_corner >= CORNER_CADENCE and sec["z_len"] != 13:
                if router.try_corner(turn_side):
                    turn_side = "L" if turn_side == "R" else "R"
                    since_corner = 0
            if router.collides(sec, router.pos, router.d):
                if router.try_corner(turn_side):
                    turn_side = "L" if turn_side == "R" else "R"
                    since_corner = 0
                if router.collides(sec, router.pos, router.d):
                    break  # boxed in — end the route here
            fills = []
            for slot in sec.get("slots", []):
                kinds = slot["kinds"]
                u, v = lane_u(slot["lane"]), slot["dz"]
                if "hero" in kinds:
                    fills.append((6, 6 if sec["z_len"] == 13 else v, cast[hero_i]))
                    placed_climax = True
                    continue
                if "counter" in kinds:
                    if counter_i is not None:
                        fills.append((u, v, sc.set_rotation(cast[counter_i], 0)))
                    continue
                pick_j = next((j for j in queue if dt.kind_of(sc.base_of(cast[j])) in kinds), None)
                if pick_j is None and queue:
                    pick_j = queue[0]
                if pick_j is not None:
                    queue.remove(pick_j)
                    fills.append((u, v, cast[pick_j]))
            router.place(sec, fills)
            since_corner += 1
            i_sec += 1
            if i_sec > 60:
                break
        # exit gate straight ahead
        if not router.collides(SEC["exit_gate"], router.pos, router.d):
            router.place(SEC["exit_gate"], [])
        # rasterize: bbox -> arrays
        xs = [c[0] for c in router.floor]
        zs = [c[1] for c in router.floor]
        x0, z0 = min(xs), min(zs)
        W = max(xs) - x0 + 1
        D = max(zs) - z0 + 1
        floor = [["0"] * W for _ in range(D)]
        walls = [[""] * W for _ in range(D)]
        inter = [[" "] * W for _ in range(D)]
        for (x, z), h in router.floor.items():
            floor[z - z0][x - x0] = h
        for (x, z), w in router.walls.items():
            walls[z - z0][x - x0] = w
        dropped = []
        for (x, z), tok in router.arts.items():
            if tok and inter[z - z0][x - x0].strip() == "":
                inter[z - z0][x - x0] = tok
            elif tok:
                dropped.append(sc.base_of(tok))
        # spawn on the first section's axis; exit token at the route's end
        s0 = router.route[0]
        ru0 = (s0["dir"][1], -s0["dir"][0])
        sp = (s0["pos"][0] + ru0[0] * 6 - x0, s0["pos"][1] + ru0[1] * 6 - z0)
        last = router.route[-1]
        rud = (last["dir"][1], -last["dir"][0])
        secl = SEC[last["id"]]
        ex = (last["pos"][0] + rud[0] * 6 + last["dir"][0] * (secl["z_len"] - 1) - x0,
              last["pos"][1] + rud[1] * 6 + last["dir"][1] * (secl["z_len"] - 1) - z0)
        utils = [[" "] * W for _ in range(D)]
        utils[sp[1]][sp[0]] = "s"
        utils[ex[1]][ex[0]] = exit_tok
        data = {
            "documentation": {
                "composer": {
                    "tool": "track_compose.py (folded, P-10a)",
                    "register": script["register"],
                    "seed": seed,
                    "route": router.route,
                    "dropped": dropped,
                },
                "authored_by": "grammar (mined) + fold router + slots; judged by ride + FIT",
            },
            "layers": {"structure": floor, "utilities": utils, "interactables": inter},
            "lighting": source.get("lighting", {}),
            "map_info": {"dimensions": {"width": float(W), "depth": float(D), "max_height": 4.0},
                         "lookup_name": cand, "name": cand, "format": "json"},
            "settings": source.get("settings", {}),
            "utility_definitions": source.get("utility_definitions", {}),
        }
        if any(any(c for c in row) for row in walls):
            data["layers"]["walls"] = walls
        # hard gate the pathfinder missed once: every floor cell reachable
        walk = {c for c, h in router.floor.items() if h not in ("0", "", " ")}
        seen, stack = set(), [next(iter(walk))]
        seen.add(stack[0])
        while stack:
            x, z = stack.pop()
            for nb in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
                if nb in walk and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
        if len(seen) != len(walk):
            print(f"  seed {seed}: ISLANDS ({len(seen)}/{len(walk)} connected) — rejected")
            continue
        sc.write_map(cand, data)
        s_exp, detail = experience_score(cand)
        if s_exp is None:
            print(f"  seed {seed}: GATE FAIL ({detail})")
            continue
        fit = 0.0
        if target:
            rc, ride = run([sys.executable, "tools/gaze_ride.py", cand], timeout=180)
            if rc == 0:
                fit = sc.curve_fit(ride, target)
        turns = sum(1 for r in router.route if r.get("turn"))
        total = s_exp + 3.0 * fit
        print(f"  seed {seed}: {total:5.2f}  exp={s_exp:.2f} FIT={fit:.2f} "
              f"turns={turns} bbox={W}x{D} cars={len(router.route)}")
        if best is None or total > best[0]:
            best = (total, seed, data, fit, router.route)
    shutil.rmtree(os.path.join(MAPS_DIR, cand), ignore_errors=True)
    if best is None:
        print(f"{map_name}: no candidate passed")
        return False
    total, seed, data, fit, route = best
    out = f"Track_{map_name}"
    data["map_info"]["lookup_name"] = out
    data["map_info"]["name"] = out
    data["documentation"]["composer"]["score"] = round(total, 2)
    data["documentation"]["composer"]["fit"] = round(fit, 2)
    sc.write_map(out, data)
    turns = sum(1 for r in route if r.get("turn"))
    print(f"{map_name} -> {out}  seed {seed}  total {total:.2f} (FIT {fit:.2f}, {turns} turns)")
    print("  route: " + " > ".join(r["id"] + ("(" + r["turn"] + ")" if r.get("turn") else "")
                                   for r in route))
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map")
    ap.add_argument("--scripts", default="doc/book/look_scripts/primitives.json")
    ap.add_argument("--seeds", type=int, default=6)
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    targets = [args.map] if args.map else list(scripts["maps"].keys())
    ok = 0
    for m in targets:
        print(f"== {m} ==")
        ok += compose(m, scripts, args.seeds)
    print(f"done: {ok}/{len(targets)}")


if __name__ == "__main__":
    main()
