"""map_chamber.py — auto-research a single map, the way the chamber
researches a single artifact.

Hill-climb: mutate the map (move an artifact to a neighbor cell, swap two
same-kind artifacts, raise/lower a podium), gate every mutant (connectivity
flood-fill + pathfinder), judge with the experience fitness + FIT against
the desire target, keep strict improvements, iterate. The trajectory is
the research record — every accepted step names its mutation.

This complements the /map-dna tracker (the per-map agenda lives there);
the chamber is the inner loop it can call.

  python tools/map_chamber.py --map Dream_Strip --gens 6 --pop 6
Writes commons/maps/Refined_<Map>/ + doc/reports/map_chamber_<Map>.json.
"""
import argparse
import copy
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


def load(map_name):
    return json.load(open(os.path.join(MAPS_DIR, map_name, "map_data.json"), encoding="utf-8"))


def arts_of(data):
    out = []
    I = data["layers"]["interactables"]
    for z, row in enumerate(I):
        for x, c in enumerate(row):
            if str(c).strip():
                out.append((x, z, str(c)))
    return out


def connected(data):
    S = data["layers"]["structure"]
    walk = {(x, z) for z, row in enumerate(S) for x, c in enumerate(row)
            if str(c).strip() not in ("0", "", " ")}
    if not walk:
        return False
    seen, stack = set(), [next(iter(walk))]
    seen.add(stack[0])
    while stack:
        x, z = stack.pop()
        for nb in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if nb in walk and nb not in seen:
                seen.add(nb)
                stack.append(nb)
    return len(seen) == len(walk)


def mutate(data, rng):
    """One mutation; returns (mutant, description) or None."""
    d = copy.deepcopy(data)
    I = d["layers"]["interactables"]
    S = d["layers"]["structure"]
    arts = arts_of(d)
    if not arts:
        return None
    op = rng.choice(["nudge", "swap", "podium", "nudge", "nudge"])
    if op == "nudge":
        x, z, tok = rng.choice(arts)
        cands = [(x + dx, z + dz) for dx in (-2, -1, 0, 1, 2) for dz in (-2, -1, 0, 1, 2)
                 if (dx, dz) != (0, 0)]
        rng.shuffle(cands)
        for nx, nz in cands:
            if 0 <= nz < len(S) and 0 <= nx < len(S[0]) \
                    and str(S[nz][nx]).strip() not in ("0", "", " ") \
                    and not str(I[nz][nx]).strip():
                I[z][x] = " "
                I[nz][nx] = tok
                return d, f"nudge {sc.base_of(tok)} ({x},{z})->({nx},{nz})"
        return None
    if op == "swap":
        a, b = rng.sample(arts, 2) if len(arts) >= 2 else (None, None)
        if a is None:
            return None
        ka = dt.kind_of(sc.base_of(a[2]))
        kb = dt.kind_of(sc.base_of(b[2]))
        if ka != kb:
            return None
        I[a[1]][a[0]], I[b[1]][b[0]] = b[2], a[2]
        return d, f"swap {sc.base_of(a[2])} <-> {sc.base_of(b[2])}"
    if op == "podium":
        x, z, tok = rng.choice(arts)
        h = str(S[z][x]).strip()
        if h == "1":
            S[z][x] = "2"
            return d, f"raise podium under {sc.base_of(tok)}"
        if h == "2":
            S[z][x] = "1"
            return d, f"lower podium under {sc.base_of(tok)}"
        return None
    return None


def score(map_name, cast, hero_i, target):
    s_exp, detail = experience_score(map_name)
    if s_exp is None:
        return None, detail
    fit = 0.0
    if target:
        rc, ride = run([sys.executable, "tools/gaze_ride.py", map_name], timeout=180)
        if rc == 0:
            fit = sc.curve_fit(ride, target)
    return s_exp + 3.0 * fit, {"exp": round(s_exp, 2), "fit": round(fit, 2), **detail}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--gens", type=int, default=6)
    ap.add_argument("--pop", type=int, default=6)
    ap.add_argument("--target-of", help="borrow the desire target of this map (default: --map)")
    args = ap.parse_args()
    rng = random.Random(46)
    base = load(args.map)
    cast = [t for _, _, t in arts_of(base)]
    hero_i = max(range(len(cast)), key=lambda i: sc.size_of(cast[i])) if cast else 0
    target = sc.load_target(args.target_of or args.map)
    cand_name = f"ChamberCand_{args.map}"
    sc.write_map(cand_name, base)
    cur_score, cur_detail = score(cand_name, cast, hero_i, target)
    if cur_score is None:
        print(f"base failed the gate: {cur_detail}")
        return
    print(f"base: {cur_score:.2f} {cur_detail}")
    current = base
    log = [{"gen": 0, "score": round(cur_score, 2), "detail": cur_detail, "mutation": "base"}]
    for g in range(1, args.gens + 1):
        best_mut, best_score, best_desc, best_detail = None, cur_score, None, None
        for _ in range(args.pop):
            m = mutate(current, rng)
            if m is None:
                continue
            mutant, desc = m
            if not connected(mutant):
                continue
            sc.write_map(cand_name, mutant)
            s, detail = score(cand_name, cast, hero_i, target)
            if s is not None and s > best_score + 1e-6:
                best_mut, best_score, best_desc, best_detail = mutant, s, desc, detail
        if best_mut is None:
            print(f"gen {g}: no improvement (plateau at {cur_score:.2f})")
            log.append({"gen": g, "score": round(cur_score, 2), "mutation": "plateau"})
            continue
        current, cur_score = best_mut, best_score
        print(f"gen {g}: {cur_score:.2f}  <- {best_desc}")
        log.append({"gen": g, "score": round(cur_score, 2), "detail": best_detail,
                    "mutation": best_desc})
    shutil.rmtree(os.path.join(MAPS_DIR, cand_name), ignore_errors=True)
    out = f"Refined_{args.map}"
    current.setdefault("documentation", {})["map_chamber"] = {
        "base": args.map, "gens": args.gens, "trajectory": log,
        "note": "auto-researched like an artifact: mutate -> gate -> judge -> keep (edge fitness)",
    }
    current["map_info"]["lookup_name"] = out
    current["map_info"]["name"] = out
    sc.write_map(out, current)
    rep = os.path.join(ROOT, "doc", "reports", f"map_chamber_{args.map}.json")
    json.dump({"map": args.map, "refined": out, "trajectory": log},
              open(rep, "w", encoding="utf-8"), indent=1)
    print(f"-> {out}  ({log[0]['score']} -> {log[-1]['score']})  report: {rep}")


if __name__ == "__main__":
    main()
