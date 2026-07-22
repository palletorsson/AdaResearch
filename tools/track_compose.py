"""track_compose.py — couple a train of sections into a map (P-10).

Samples section-trains from the mined grammar (track_grammar.json), fills the
kit sections' slots with the map's cast (kind-affinity; hero into the climax
hall at ~0.72, counter facing from the wing), assembles at the locked width
x=13, gates with the pathfinder, and judges with the experience fitness +
FIT against the text-compiled desire target. Champion -> commons/maps/
Track_<Map>/ with the full train in its manifest (the seam: every section
names itself).

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
BY_CAT = {}
for s in KIT["sections"]:
    if "register" not in s:  # arrival/exit are authored, never sampled
        BY_CAT.setdefault(s["mined_as"], []).append(s)


def lane_x(lane):
    xs = LANES[lane]
    return xs[len(xs) // 2]


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
        # authored moves (not sampled): arrival opener, climax at ~0.72, exit
        sections = []
        if script["register"] == "arrival":
            sections.append(next(s for s in KIT["sections"] if s["id"] == "arrival_void"))
        for c in cats:
            sections.append(rng.choice(BY_CAT.get(c, BY_CAT["side_bay"])))
        climax = next(s for s in KIT["sections"] if s["id"] == "climax_hall")
        vac = next(s for s in KIT["sections"] if s["id"] == "vacuum_approach")
        pos = len(sections) if script["register"] == "close" else max(1, int(len(sections) * 0.72))
        sections[pos:pos] = [vac, climax]
        # fill slots: kind affinity in cast order; overflow appends podium galleries
        queue = list(rest)
        placements, train_log = [], []
        z = 0
        gallery = next(s for s in KIT["sections"] if s["id"] == "podium_gallery")
        i_sec = 0
        all_secs = list(sections)
        exit_sec = next(x for x in KIT["sections"] if x["id"] == "exit_gate")
        while i_sec < len(all_secs) or queue:
            if i_sec >= len(all_secs):
                all_secs.append(gallery)  # overflow: the train grows until the cast fits
            sec = all_secs[i_sec]
            train_log.append({"id": sec["id"], "z": z})
            for slot in sec.get("slots", []):
                kinds = slot["kinds"]
                if "hero" in kinds:
                    placements.append((lane_x(slot["lane"]), z + slot["dz"], cast[hero_i]))
                    continue
                if "counter" in kinds:
                    if counter_i is not None:
                        placements.append((lane_x(slot["lane"]), z + slot["dz"],
                                           sc.set_rotation(cast[counter_i], 0)))
                    continue
                pick_j = next((j for j in queue if dt.kind_of(sc.base_of(cast[j])) in kinds), None)
                if pick_j is None and queue:
                    pick_j = queue[0]
                if pick_j is not None:
                    queue.remove(pick_j)
                    placements.append((lane_x(slot["lane"]), z + slot["dz"], cast[pick_j]))
            z += sec["z_len"]
            i_sec += 1
        train_log.append({"id": exit_sec["id"], "z": z})  # the exit couples last, always
        z += exit_sec["z_len"]
        depth = z + 1
        # floor: full width; arrival_void carves the plate; shrunken narrows;
        # BODIES: podium plinths (height 2) under display slots, wall segments
        # on the corridor edges, pillar columns (height 3) at the gates.
        floor = [["1"] * WIDTH for _ in range(depth)]
        walls = [[""] * WIDTH for _ in range(depth)]
        slot_cells = {(x, z2) for x, z2, _ in placements}
        for sec in train_log:
            s = next(x for x in KIT["sections"] if x["id"] == sec["id"])
            z0, z1 = sec["z"], min(depth, sec["z"] + s["z_len"])
            if s["id"] == "arrival_void":
                for r in range(z0, z1):
                    for x in range(WIDTH):
                        floor[r][x] = "1" if 5 <= x <= 7 else "0"
            if s["id"] == "shrunken_void":
                for r in range(z0, z1):
                    for x in range(WIDTH):
                        floor[r][x] = "1" if 3 <= x <= 9 else "0"
            body = s.get("body", {})
            if body.get("podiums"):
                for slot in s.get("slots", []):
                    x, r = lane_x(slot["lane"]), sec["z"] + slot["dz"]
                    if r < depth and (x, r) in slot_cells and floor[r][x] == "1":
                        floor[r][x] = "2"  # the plinth; the artifact seats on top
            wall = body.get("wall")
            if wall in ("left", "both"):
                for r in range(z0, z1):
                    walls[r][0] += "w"
            if wall in ("right", "both"):
                for r in range(z0, z1):
                    walls[r][WIDTH - 1] += "e"
            for px, pdz in body.get("pillars", []):
                r = sec["z"] + pdz
                if r < depth and floor[r][px] == "1":
                    floor[r][px] = "3"  # gate column
        data, dropped = sc.build_map(source, cand, WIDTH, depth, floor, placements,
                                     (6, 0), (6, depth - 1), exit_tok, script, seed)
        if any(any(c for c in row) for row in walls):
            data["layers"]["walls"] = walls
        data["documentation"]["composer"]["tool"] = "track_compose.py"
        data["documentation"]["composer"]["train"] = [t["id"] for t in train_log]
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
        total = s_exp + 3.0 * fit
        print(f"  seed {seed}: {total:5.2f}  exp={s_exp:.2f} FIT={fit:.2f} "
              f"train={'>'.join(t['id'][:9] for t in train_log[:7])}…")
        if best is None or total > best[0]:
            best = (total, seed, data, detail, fit, [t["id"] for t in train_log])
    shutil.rmtree(os.path.join(MAPS_DIR, cand), ignore_errors=True)
    if best is None:
        print(f"{map_name}: no candidate passed")
        return False
    total, seed, data, detail, fit, train = best
    out = f"Track_{map_name}"
    data["map_info"]["lookup_name"] = out
    data["map_info"]["name"] = out
    data["documentation"]["composer"]["score"] = round(total, 2)
    data["documentation"]["composer"]["fit"] = round(fit, 2)
    sc.write_map(out, data)
    print(f"{map_name} -> {out}  seed {seed}  total {total:.2f} (FIT {fit:.2f})")
    print(f"  train: {' > '.join(train)}")
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
