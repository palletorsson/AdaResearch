"""gen_sdf_track.py — the hybrid: SDF terrain carrying track contracts.

The floor is a level set of the desire field (P-11): a serpentine spine,
radius from the text-compiled desire curve. The CONTENTS are the track's
(P-10): a section train sampled from the grammar mined off the composed
corridors, each section claiming an arclength interval of the tube and
applying its placement contract there — slots dealt into lanes that BREATHE
with the local radius, podium plinths, organic parapet walls on the rim,
pillar gates. Sections also modulate the tube itself: the vacuum pinches it,
the climax swells it into the bulge-plaza.

  python tools/gen_sdf_track.py --map Point_Lines --seeds 4
Champion -> commons/maps/SdfTrack_<Map>/ with the dealt train + intervals
in the manifest. Judged like everything else: connectivity, pathfinder,
experience fitness, FIT.
"""
import argparse
import json
import math
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
from track_compose import sample_train, SEC, BY_CAT  # noqa: E402
from gen_sdf_map import spine_points  # noqa: E402

# lane -> signed fraction of the local radius (the lanes breathe with the tube)
LANE_F = {"L_edge": -0.85, "L_bay": -0.5, "axis": 0.0, "R_bay": 0.5, "R_edge": 0.85}
# sections that reshape the tube itself
RADIUS_MOD = {"shrunken_void": 0.55, "vacuum_approach": 0.65, "breather": 0.85,
              "climax_plaza": 1.9, "climax_hall": 1.6, "arrival_void": 0.6}


def compose(map_name, scripts, seeds):
    script = scripts["maps"].get(map_name, {"register": "promenade", "hero": [], "counter": []})
    source, cast, exit_tok = sc.read_cast(map_name)
    for pin in script.get("pins", []):
        if not any(sc.base_of(t) == sc.base_of(pin) for t in cast):
            cast.append(pin)
    hero_i = sc.pick(cast, script.get("hero", []))
    if hero_i is None:
        hero_i = max(range(len(cast)), key=lambda i: sc.size_of(cast[i]))
    counter_i = sc.pick(cast, script.get("counter", []), exclude=hero_i)
    rest = [i for i in range(len(cast)) if i not in (hero_i, counter_i)]
    target = sc.load_target(map_name)
    vis = (target or {}).get("target", target or {}).get("visual", [30.0] * 16) \
        if target else [30.0] * 16
    if target and "target" in target:
        vis = target["target"]["visual"]

    spine = spine_points(400)
    W = D = 46
    best = None
    cand = f"SdfTrackCand_{map_name}"

    for seed in range(seeds):
        rng = random.Random(seed * 131 + 46)
        n = max(4, round(len(rest) / 2.0))
        cats = sample_train(rng, n)
        sections = [rng.choice(BY_CAT.get(c, BY_CAT["side_bay"])) for c in cats]
        pos = max(1, int(len(sections) * 0.72))
        sections[pos:pos] = [SEC["vacuum_approach"], SEC["climax_plaza"]]
        total = sum(s["z_len"] for s in sections)
        # deal arclength intervals proportional to z_len over t in [0.05, 0.95]
        t0, intervals = 0.05, []
        for s in sections:
            t1 = t0 + 0.90 * s["z_len"] / total
            intervals.append((s, t0, t1))
            t0 = t1

        def rad_mod(t):
            for s, a, b in intervals:
                if a <= t <= b:
                    return RADIUS_MOD.get(s["id"], 1.0)
            return 1.0

        def radius(t):
            f = t * (len(vis) - 1)
            a, b = vis[int(f)], vis[min(len(vis) - 1, int(f) + 1)]
            v = a + (b - a) * (f - int(f))
            return max(1.2, (2.0 + (v / 72.0) * 4.0) * rad_mod(t))

        def level_of(t):
            lv = 1 + min(3, int(t * 3.4))
            for s2, a2, b2 in intervals:
                if a2 <= t <= b2 and s2['id'] in ('climax_plaza', 'climax_hall'):
                    return min(4, lv + 1)
            return lv

        # rasterize the tube
        floor = [["0"] * W for _ in range(D)]
        utils = [[" "] * W for _ in range(D)]
        inter = [[" "] * W for _ in range(D)]
        samp = spine[::4]
        for z in range(D):
            for x in range(W):
                bd, bt = None, 0.0
                for (sx, sz, t) in samp:
                    d2 = (x - sx) ** 2 + (z - sz) ** 2
                    if bd is None or d2 < bd:
                        bd, bt = d2, t
                d = math.sqrt(bd)
                if d < radius(bt):
                    floor[z][x] = str(level_of(bt))
                elif d < radius(bt) + 0.9:
                    # the organic parapet: walled sections raise their rim
                    for s, a, b in intervals:
                        if a <= bt <= b and s.get("body", {}).get("wall"):
                            floor[z][x] = str(min(4, level_of(bt) + 1))
                            break
        # ramps at level transitions, on and around the spine
        prev = 1
        for (sx, sz, t) in spine:
            lv = level_of(t)
            if lv != prev:
                xi, zi = int(round(sx)), int(round(sz))
                for dz in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        xx, zz = xi + dx, zi + dz
                        if 0 <= xx < W and 0 <= zz < D and floor[zz][xx] not in ("0",):
                            utils[zz][xx] = "wp"
                prev = lv

        def frame_at(t):
            si = min(len(spine) - 1, int(t * len(spine)))
            sx, sz, _ = spine[si]
            nx, nz, _ = spine[min(len(spine) - 1, si + 4)]
            px, pz = -(nz - sz), (nx - sx)
            norm = math.hypot(px, pz) or 1
            return sx, sz, px / norm, pz / norm

        def drop(x, z, tok, podium=False):
            for r_ in range(0, 4):
                for dz in range(-r_, r_ + 1):
                    for dx in range(-r_, r_ + 1):
                        xx, zz = int(round(x)) + dx, int(round(z)) + dz
                        if 0 <= xx < W and 0 <= zz < D and floor[zz][xx] not in ("0",) \
                                and inter[zz][xx].strip() == "" and utils[zz][xx].strip() == "":
                            inter[zz][xx] = tok
                            if podium and floor[zz][xx] in ("1", "2", "3"):
                                floor[zz][xx] = str(int(floor[zz][xx]) + 1)
                            return True
            return False

        # deal the slots along the tube
        queue = list(rest)
        dropped, train_log = [], []
        for s, a, b in intervals:
            train_log.append({"id": s["id"], "t": [round(a, 3), round(b, 3)]})
            body = s.get("body", {})
            for slot in s.get("slots", []):
                t_slot = a + (slot["dz"] + 0.5) / max(1, s["z_len"]) * (b - a)
                sx, sz, px, pz = frame_at(t_slot)
                off = LANE_F[slot["lane"]] * (radius(t_slot) - 0.8)
                x, z = sx + px * off, sz + pz * off
                kinds = slot["kinds"]
                if "hero" in kinds:
                    t_slot = (a + b) / 2
                    sx, sz, px, pz = frame_at(t_slot)
                    x, z = sx, sz  # the bulge centre: the hero holds the axis
                    if not drop(x, z, cast[hero_i]):
                        dropped.append(sc.base_of(cast[hero_i]))
                    continue
                if "counter" in kinds:
                    if counter_i is not None and not drop(x, z, sc.set_rotation(cast[counter_i], 0)):
                        dropped.append(sc.base_of(cast[counter_i]))
                    continue
                j = next((q for q in queue if dt.kind_of(sc.base_of(cast[q])) in kinds), None)
                if j is None and queue:
                    j = queue[0]
                if j is not None:
                    queue.remove(j)
                    if not drop(x, z, cast[j], podium=body.get("podiums", False)):
                        dropped.append(sc.base_of(cast[j]))
        # overflow: remaining cast dealt along the leftover late tube
        k = 0
        while queue:
            j = queue.pop(0)
            t_slot = 0.08 + 0.8 * (k / max(1, len(rest)))
            sx, sz, px, pz = frame_at(t_slot)
            off = (radius(t_slot) - 1.0) * (1 if k % 2 else -1) * 0.7
            if not drop(sx + px * off, sz + pz * off, cast[j]):
                dropped.append(sc.base_of(cast[j]))
            k += 1

        s0, se = spine[0], spine[-1]
        utils[int(round(s0[1]))][int(round(s0[0]))] = "s"
        utils[int(round(se[1]))][int(round(se[0]))] = exit_tok

        data = {
            "documentation": {"composer": {
                "tool": "gen_sdf_track.py (the hybrid, P-10 x P-11)",
                "seed": seed, "train": train_log, "dropped": dropped,
                "note": "desire shapes the ground; the sections decide what stands on it; "
                        "lanes breathe with the tube; walls are parapets on the rim",
            }},
            "layers": {"structure": floor, "utilities": utils, "interactables": inter},
            "lighting": source.get("lighting", {}),
            "map_info": {"dimensions": {"width": float(W), "depth": float(D), "max_height": 5.0},
                         "lookup_name": cand, "name": cand, "format": "json"},
            "settings": source.get("settings", {}),
            "utility_definitions": source.get("utility_definitions", {}),
        }
        # connectivity gate
        walk = {(x, z) for z in range(D) for x in range(W) if floor[z][x] != "0"}
        seen, stack = {next(iter(walk))}, [next(iter(walk))]
        while stack:
            xx, zz = stack.pop()
            for nb in ((xx + 1, zz), (xx - 1, zz), (xx, zz + 1), (xx, zz - 1)):
                if nb in walk and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
        if len(seen) != len(walk):
            print(f"  seed {seed}: ISLANDS ({len(seen)}/{len(walk)}) — rejected")
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
        tot = s_exp + 3.0 * fit
        print(f"  seed {seed}: {tot:5.2f}  exp={s_exp:.2f} FIT={fit:.2f} "
              f"dropped={len(dropped)} train={'>'.join(t['id'][:8] for t in train_log[:6])}…")
        if best is None or tot > best[0]:
            best = (tot, seed, data, fit)
    shutil.rmtree(os.path.join(MAPS_DIR, cand), ignore_errors=True)
    if best is None:
        print(f"{map_name}: no candidate passed")
        return False
    tot, seed, data, fit = best
    out = f"SdfTrack_{map_name}"
    data["map_info"]["lookup_name"] = out
    data["map_info"]["name"] = out
    data["documentation"]["composer"]["score"] = round(tot, 2)
    data["documentation"]["composer"]["fit"] = round(fit, 2)
    sc.write_map(out, data)
    print(f"{map_name} -> {out}  seed {seed}  total {tot:.2f} (FIT {fit:.2f})")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="Point_Lines")
    ap.add_argument("--scripts", default="doc/book/look_scripts/primitives.json")
    ap.add_argument("--seeds", type=int, default=4)
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    compose(args.map, scripts, args.seeds)


if __name__ == "__main__":
    main()
