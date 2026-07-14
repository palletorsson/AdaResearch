"""map_tournament.py — the marriage: 13 floor strategies, one experience judge.

The pearl factory generates; the desire stack judges. Every recipe in the
rule box produces a candidate map for the sequence, and each candidate is
scored in the EXPERIENCE domain (the edge fitness, L-010..L-014):

  tau      encounter order agreement (kendall vs the map's own cast order)
  cov      cast coverage on the ride
  promise  hero visible early, CENTER (the vanishing-point debt)
  dolly    hero's angular size rises monotonically to one climax
  rank1    the hero is the ride's largest presence
  cycles   desire cycles completed in each artifact's own currency (P-3)

Pathfinder is the hard gate. Results print as a leaderboard and land in
doc/reports/map_tournament_<seq>.json. Generated maps are named
Trial_<recipe>_<seq> — siblings, disposable, re-runnable.

  python tools/map_tournament.py --seq=randomness
  python tools/map_tournament.py --seq=lsystems --keep-losers
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import desire_timeline as dt  # noqa: E402
from script_compose import kendall, base_of, size_of  # noqa: E402

RECIPES = ["lsystem", "dla", "wfc", "voronoi", "rd", "erosion", "halls",
           "rooms", "wanghall", "ants", "antrooms", "derive", "flock", "physarum"]


def run(cmd, timeout=600):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT, timeout=timeout)
    return r.returncode, r.stdout + r.stderr


def cast_of(map_name):
    p = os.path.join(MAPS_DIR, map_name, "map_data.json")
    d = json.load(open(p, encoding="utf-8"))
    cast = []
    for row in d["layers"]["interactables"]:
        for c in row:
            tok = str(c).strip()
            if tok:
                cast.append(tok)
    return cast


def experience_score(name):
    """The edge fitness, target-free: how composed does the ride read?"""
    cast = cast_of(name)
    if not cast:
        return None, "no cast"
    hero_tok = max(cast, key=size_of)
    hero_b = base_of(hero_tok)
    rc, ride = run([sys.executable, "tools/gaze_ride.py", name], timeout=180)
    if rc != 0:
        return None, "gaze_ride error"
    visits, seen_deg = [], {}
    for m in re.finditer(r"-> (\S+)", ride):
        b = base_of(m.group(1))
        if b not in visits:
            visits.append(b)
    hero_track = []
    for sm in dt.STEP_RE.finditer(ride):
        step = int(sm.group(1))
        for vm in dt.VIEW_RE.finditer(sm.group(4)):
            b = base_of(vm.group(1))
            deg = int(vm.group(2))
            seen_deg[b] = max(seen_deg.get(b, 0), deg)
            if b == hero_b:
                hero_track.append((step, deg, vm.group(3)))
    cast_bases = []
    for t in cast:
        b = base_of(t)
        if b not in cast_bases:
            cast_bases.append(b)
    cov = len([b for b in cast_bases if b in visits or b in seen_deg]) / len(cast_bases)
    tau = kendall(cast_bases, visits)
    promise = 0.0
    if hero_track and hero_track[0][0] <= 1:
        promise = 1.0 if hero_track[0][2] == "CENTER" else 0.5
    degs = [d for _, d, _ in hero_track]
    if len(degs) >= 2:
        peak = degs.index(max(degs))
        rises = sum(1 for a, b2 in zip(degs[:peak + 1], degs[1:peak + 1]) if b2 >= a)
        dolly = rises / max(1, peak) if peak else 0.5
    else:
        dolly = 0.0
    hd = seen_deg.get(hero_b, 0)
    rank1 = 1.0 if seen_deg and hd == max(seen_deg.values()) else 0.0
    # desire cycles (P-3) via the forward transform
    tl = dt.transform(name)
    cyc = tl["summary"] if tl else {"cycles": 0, "complete": 0, "runtime_s": 0}
    cyc_frac = (cyc["complete"] / cyc["cycles"]) if cyc["cycles"] else 0.0
    score = 2 * tau + cov + promise + dolly + rank1 + 2 * cyc_frac
    detail = {"tau": round(tau, 2), "cov": round(cov, 2), "promise": promise,
              "dolly": round(dolly, 2), "rank1": rank1,
              "cycles": f"{cyc['complete']}/{cyc['cycles']}",
              "runtime_s": cyc.get("runtime_s", 0), "heroDeg": hd, "hero": hero_b,
              "score": round(score, 2)}
    return score, detail


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", required=True)
    ap.add_argument("--recipes", default="all")
    ap.add_argument("--seed", default="46")
    ap.add_argument("--keep-losers", action="store_true")
    args = ap.parse_args()
    recipes = RECIPES if args.recipes == "all" else args.recipes.split(",")
    rows = []
    for r in recipes:
        name = f"Trial_{r}_{args.seq}"
        shutil.rmtree(os.path.join(MAPS_DIR, name), ignore_errors=True)
        rc, out = run([sys.executable, "tools/pearl_factory.py",
                       f"--recipe={r}", f"--seq={args.seq}",
                       f"--name={name}", f"--seed={args.seed}"])
        if not os.path.isfile(os.path.join(MAPS_DIR, name, "map_data.json")):
            rows.append({"recipe": r, "status": "GEN FAIL",
                         "note": out.strip().splitlines()[-1][:90] if out.strip() else ""})
            print(f"{r:10} GEN FAIL")
            continue
        rc, pf = run([sys.executable, "tools/map_pathfinder.py", "check", name])
        if rc != 0 or "0 FAIL" not in pf:
            rows.append({"recipe": r, "status": "PATHFINDER FAIL"})
            print(f"{r:10} PATHFINDER FAIL")
            continue
        s, detail = experience_score(name)
        if s is None:
            rows.append({"recipe": r, "status": f"SCORE FAIL: {detail}"})
            print(f"{r:10} SCORE FAIL {detail}")
            continue
        rows.append({"recipe": r, "status": "ok", "map": name, **detail})
        print(f"{r:10} {s:5.2f}  {detail}")
    ok = [x for x in rows if x["status"] == "ok"]
    ok.sort(key=lambda x: -x["score"])
    print("\n=== LEADERBOARD:", args.seq, "===")
    for i, x in enumerate(ok, 1):
        print(f"{i:2}. {x['recipe']:10} {x['score']:5.2f}  tau={x['tau']:+.2f} "
              f"cycles={x['cycles']} runtime={x['runtime_s']}s")
    out_p = os.path.join(ROOT, "doc", "reports", f"map_tournament_{args.seq}.json")
    json.dump({"seq": args.seq, "seed": args.seed, "rows": rows,
               "leaderboard": [x["recipe"] for x in ok]},
              open(out_p, "w", encoding="utf-8"), indent=1)
    print(f"report -> {out_p}")
    if not args.keep_losers and ok:
        for x in ok[1:]:
            shutil.rmtree(os.path.join(MAPS_DIR, x["map"]), ignore_errors=True)
        print(f"kept champion {ok[0]['map']}, removed {len(ok)-1} losers "
              f"(--keep-losers to keep all)")


if __name__ == "__main__":
    main()
