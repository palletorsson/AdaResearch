"""compose_auto.py — the temperament selector for the composer trio.

place.py's lesson (no base algorithm wins — pick per map), taught to the
composition families. For each map it runs all three under the SAME judge
(score_candidate: pathfinder gate + gaze_ride + experience fitness + FIT):

  search — script_compose (register layouts, N seeds, keep champion)
  grown  — germinate (food map from the desire target, space colonization)
  hybrid — germinate --axis (grown flesh, straight L-010 spine)

and keeps the winner as Auto_<Map>, recording every family's score in the
manifest so the selection is legible. Transformation's pilot split
search 4 / grown 2 / hybrid 1 — each map has a temperament; this tool
lets the map choose.

  python tools/compose_auto.py --scripts doc/book/look_scripts/transformation.json
  python tools/compose_auto.py --map Trans_Pit --engine grown   # force a family
"""
import argparse
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
sys.path.insert(0, os.path.join(ROOT, "tools"))

import germinate as gm  # noqa: E402
import script_compose as sc  # noqa: E402

FAMILIES = [
    ("search", "AutoS_", lambda m, s, n: sc.compose(m, s, n, "AutoS_")),
    ("grown", "AutoG_", lambda m, s, n: gm.germinate_map(m, s, n, "AutoG_", axis=False)),
    ("hybrid", "AutoH_", lambda m, s, n: gm.germinate_map(m, s, n, "AutoH_", axis=True)),
]


def read_champion(name):
    p = os.path.join(MAPS_DIR, name, "map_data.json")
    if not os.path.isfile(p):
        return None
    d = json.load(open(p, encoding="utf-8"))
    s = d.get("documentation", {}).get("composer", {}).get("score")
    return (s, d) if s is not None else None


def auto(map_name, scripts, seeds, prefix, engine):
    fams = FAMILIES if engine == "auto" else [f for f in FAMILIES if f[0] == engine]
    results = {}
    for fam, pre, run in fams:
        print(f" -- {fam} --")
        try:
            run(map_name, scripts, seeds)
        except Exception as e:  # a family may fail; the court goes on
            print(f"  {fam} error: {e}")
        champ = read_champion(pre + map_name)
        if champ:
            results[fam] = champ
    if not results:
        print(f"{map_name}: no family produced a champion")
        return None
    best = max(results, key=lambda k: results[k][0])
    score, data = results[best]
    out = prefix + map_name
    data["map_info"]["lookup_name"] = out
    data["map_info"]["name"] = out
    data["documentation"]["composer"]["engine"] = best
    data["documentation"]["composer"]["auto"] = {
        "selector": "compose_auto.py — the map chooses its temperament",
        "scores": {k: round(v[0], 3) for k, v in results.items()},
    }
    sc.write_map(out, data)
    for _, pre, _ in FAMILIES:
        shutil.rmtree(os.path.join(MAPS_DIR, pre + map_name), ignore_errors=True)
    board = " ".join(f"{k}={v[0]:.2f}" for k, v in sorted(results.items()))
    print(f"{map_name} -> {out}  ENGINE={best}  ({board})")
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="single map; omit for every map in the script file")
    ap.add_argument("--scripts", default="doc/book/look_scripts/transformation.json")
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--engine", default="auto",
                    choices=["auto", "search", "grown", "hybrid"])
    ap.add_argument("--prefix", default="Auto_")
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    targets = [args.map] if args.map else list(scripts["maps"].keys())
    picks = {}
    for m in targets:
        print(f"== {m} ==")
        e = auto(m, scripts, args.seeds, args.prefix, args.engine)
        if e:
            picks[e] = picks.get(e, 0) + 1
    print(f"done: {sum(picks.values())}/{len(targets)}  temperaments: {picks}")


if __name__ == "__main__":
    main()
